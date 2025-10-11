import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:state/core/constants/ui_constants.dart';
import 'package:state/core/services/preferences_service.dart';
import 'package:state/features/postCreation/bloc/post_creation_cubit.dart';
import 'package:state/features/postCreation/bloc/post_creation_state.dart';
import 'package:state/features/postCreation/ui/widgets/region_picker_bottom_sheet.dart';
import 'package:state/features/postCreation/ui/widgets/image_source_selector.dart';
import 'package:google_fonts/google_fonts.dart';

class PostCreationScreen extends StatefulWidget {
  const PostCreationScreen({super.key});

  @override
  State<PostCreationScreen> createState() => _PostCreationScreenState();
}

class _PostCreationScreenState extends State<PostCreationScreen> {
  String selectedRegion = 'Global'; // Will be updated in initState
  final TextEditingController contentController = TextEditingController();
  File? _selectedImage;

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
    final result = await ImageSourceSelector.show(context);
    if (result != null && mounted) {
      final picker = ImagePicker();
      XFile? image;

      // Opens camera or gallery based on user selection from ImageSourceSelector
      if (result == true) {
        image = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
          maxWidth: 1920,
          maxHeight: 1080,
        );
      } else if (result == false) {
        image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
          maxWidth: 1920,
          maxHeight: 1080,
        );
      }

      // Updates the selected image if an image was selected
      if (image != null && mounted) {
        setState(() => _selectedImage = File(image!.path));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PostCreationCubit, PostCreationState>(
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
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black87),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed:
                      state is PostCreationLoading
                          ? null
                          : () {
                            final content = contentController.text.trim();
                            // Allow posting with just image or just text or both
                            if (content.isNotEmpty || _selectedImage != null) {
                              context.read<PostCreationCubit>().createPost(
                                region: selectedRegion,
                                content: content,
                                imageFile: _selectedImage,
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
                            children: const [
                              Icon(Icons.add, size: 20, color: Colors.black87),
                              SizedBox(width: 8),
                              Text(
                                'Add Image',
                                style: TextStyle(
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
                if (_selectedImage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: UIConstants.spacingLarge,
                      vertical: UIConstants.spacingLarge,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            UIConstants.radiusMedium,
                          ),
                          child: Image.file(
                            _selectedImage!,
                            width: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Positioned(
                          top: UIConstants.spacingSmall,
                          right: UIConstants.spacingSmall,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImage = null),
                            child: Container(
                              padding: const EdgeInsets.all(
                                UIConstants.spacingXSmall,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(
                                  UIConstants.radiusLarge,
                                ),
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
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: contentController,
                    maxLines: 8,
                    style: GoogleFonts.beVietnamPro(
                      color: const Color(0xFF121416),
                      fontSize: 16,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: "What's on your mind?",
                      hintStyle: GoogleFonts.beVietnamPro(
                        color: const Color(0xFF6A7681),
                        fontSize: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.black54),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
