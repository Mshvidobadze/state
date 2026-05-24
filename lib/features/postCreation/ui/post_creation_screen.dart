import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:state/core/constants/ui_constants.dart';
import 'package:state/core/services/preferences_service.dart';
import 'package:state/core/widgets/stable_multiline_text_field.dart';
import 'package:state/features/postCreation/bloc/post_creation_cubit.dart';
import 'package:state/features/postCreation/bloc/post_creation_state.dart';
import 'package:state/features/postCreation/ui/widgets/image_source_selector.dart';
import 'package:state/features/postCreation/ui/widgets/region_picker_bottom_sheet.dart';

class PostCreationScreen extends StatefulWidget {
  const PostCreationScreen({super.key});

  @override
  State<PostCreationScreen> createState() => _PostCreationScreenState();
}

class _PostCreationScreenState extends State<PostCreationScreen> {
  String selectedRegion = 'Georgia';
  final TextEditingController contentController = TextEditingController();
  final List<File> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _initializeRegion();
  }

  Future<void> _initializeRegion() async {
    final savedRegion = await PreferencesService.getRegion();
    if (mounted) {
      setState(() {
        selectedRegion = savedRegion;
      });
    }
  }

  Future<void> _showRegionPicker() async {
    final result = await RegionPickerBottomSheet.show(
      context,
      currentRegion: selectedRegion,
    );
    if (result != null && mounted) {
      setState(() {
        selectedRegion = result;
      });
    }
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= PostCreationCubit.maxImagesPerPost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You can add up to ${PostCreationCubit.maxImagesPerPost} photos per post.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final result = await ImageSourceSelector.show(context);
    if (result != null && mounted) {
      final picker = ImagePicker();
      final remainingSlots =
          PostCreationCubit.maxImagesPerPost - _selectedImages.length;

      if (result == true) {
        final image = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
          maxWidth: 1920,
          maxHeight: 1080,
        );
        if (image != null && mounted) {
          setState(() => _selectedImages.add(File(image.path)));
        }
      } else if (result == false) {
        final images = await picker.pickMultiImage(
          imageQuality: 80,
          maxWidth: 1920,
          maxHeight: 1080,
        );
        if (images.isNotEmpty && mounted) {
          final selected = images.take(remainingSlots).map((x) => File(x.path));
          setState(() => _selectedImages.addAll(selected));
          if (images.length > remainingSlots) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Only first $remainingSlots photos were added (max ${PostCreationCubit.maxImagesPerPost}).',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    }
  }

  void _removeSelectedImage(int index) {
    if (index < 0 || index >= _selectedImages.length) return;
    setState(() => _selectedImages.removeAt(index));
  }

  @override
  void dispose() {
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PostCreationCubit, PostCreationState>(
      listener: (context, state) {
        if (state is PostCreationSuccess) {
          Navigator.of(context).pop(true);
        } else if (state is PostCreationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black87),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: BlocBuilder<PostCreationCubit, PostCreationState>(
                buildWhen:
                    (previous, current) =>
                        (previous is PostCreationLoading) !=
                        (current is PostCreationLoading),
                builder: (context, state) {
                  return TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed:
                        state is PostCreationLoading
                            ? null
                            : () {
                              final content = contentController.text.trim();
                              if (content.isNotEmpty ||
                                  _selectedImages.isNotEmpty) {
                                context.read<PostCreationCubit>().createPost(
                                  region: selectedRegion,
                                  content: content,
                                  imageFiles: _selectedImages,
                                );
                              }
                            },
                    child:
                        state is PostCreationLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black54,
                                ),
                              ),
                            )
                            : const Text('Post'),
                  );
                },
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: _showRegionPicker,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.public,
                              size: 20,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              selectedRegion,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_drop_down,
                              size: 20,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.add,
                              size: 20,
                              color: Colors.black87,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedImages.isEmpty
                                  ? 'Add Photos'
                                  : '${_selectedImages.length}/${PostCreationCubit.maxImagesPerPost} Photos',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedImages.isNotEmpty)
                _PostCreationImagePreview(
                  images: _selectedImages,
                  onRemove: _removeSelectedImage,
                ),
              _PostCreationContentField(controller: contentController),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostCreationContentField extends StatefulWidget {
  final TextEditingController controller;

  const _PostCreationContentField({required this.controller});

  @override
  State<_PostCreationContentField> createState() =>
      _PostCreationContentFieldState();
}

class _PostCreationContentFieldState extends State<_PostCreationContentField> {
  late final TextStyle _textStyle;
  late final TextStyle _hintStyle;
  var _stylesReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stylesReady) return;
    _stylesReady = true;
    final fontFamily = GoogleFonts.beVietnamPro().fontFamily;
    _textStyle = TextStyle(
      fontFamily: fontFamily,
      color: const Color(0xFF121416),
      fontSize: 16,
      height: 1.5,
    );
    _hintStyle = TextStyle(
      fontFamily: fontFamily,
      color: const Color(0xFF6A7681),
      fontSize: 16,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: StableMultilineTextField(
        key: const ValueKey('post_creation_stable_field'),
        controller: widget.controller,
        hintText: "What's on your mind?",
        maxLines: 8,
        textStyle: _textStyle,
        hintStyle: _hintStyle,
        borderRadius: BorderRadius.circular(8),
        borderColor: Colors.grey.withValues(alpha: 0.3),
        focusedBorderColor: Colors.black54,
      ),
    );
  }
}

class _PostCreationImagePreview extends StatefulWidget {
  final List<File> images;
  final ValueChanged<int> onRemove;

  const _PostCreationImagePreview({
    required this.images,
    required this.onRemove,
  });

  @override
  State<_PostCreationImagePreview> createState() =>
      _PostCreationImagePreviewState();
}

class _PostCreationImagePreviewState extends State<_PostCreationImagePreview> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(covariant _PostCreationImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.images.isEmpty) {
      _currentPage = 0;
      return;
    }
    if (_currentPage >= widget.images.length) {
      _currentPage = widget.images.length - 1;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentPage);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacingLarge,
        vertical: UIConstants.spacingLarge,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                child: SizedBox(
                  height: 280,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.images.length,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      return Image.file(
                        widget.images[index],
                        width: double.infinity,
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                ),
              ),
              if (widget.images.length > 1) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.images.length, (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 8 : 6,
                      height: isActive ? 8 : 6,
                      decoration: BoxDecoration(
                        color:
                            isActive
                                ? const Color(0xFF111418)
                                : const Color(0xFFBFC5CC),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
          Positioned(
            top: UIConstants.spacingSmall,
            right: UIConstants.spacingSmall,
            child: GestureDetector(
              onTap: () => widget.onRemove(_currentPage),
              child: Container(
                padding: const EdgeInsets.all(UIConstants.spacingXSmall),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: UIConstants.iconMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
