import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:state/core/widgets/stable_multiline_text_field.dart';
import 'package:state/features/postCreation/ui/widgets/image_source_selector.dart';

class CommentInput extends StatefulWidget {
  final Function(String content, File? image) onSubmit;
  final String? replyingTo;
  final VoidCallback? onCancelReply;
  final bool enabled;
  final String? disabledHint;

  const CommentInput({
    super.key,
    required this.onSubmit,
    this.replyingTo,
    this.onCancelReply,
    this.enabled = true,
    this.disabledHint,
  });

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final _controller = TextEditingController();
  final _selectedImage = ValueNotifier<File?>(null);
  final ImagePicker _picker = ImagePicker();
  late final Listenable _submitStateListenable;
  late final TextStyle _replyBannerStyle;
  late final Color _borderColor;
  late final Color _hintColor;
  late final TextStyle _hintTextStyle;
  var _stylesReady = false;

  bool get _canSubmit =>
      _controller.text.trim().isNotEmpty || _selectedImage.value != null;

  @override
  void initState() {
    super.initState();
    _submitStateListenable = Listenable.merge([_controller, _selectedImage]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stylesReady) return;
    _stylesReady = true;
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final fontFamily = GoogleFonts.beVietnamPro().fontFamily;
    _hintColor = isLightMode ? Colors.black38 : Colors.white38;
    _borderColor =
        isLightMode
            ? Colors.grey.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.1);
    _replyBannerStyle = TextStyle(
      fontFamily: fontFamily,
      color: _hintColor,
      fontSize: 12,
    );
    _hintTextStyle = TextStyle(
      fontFamily: fontFamily,
      color: _hintColor,
      fontSize: 14,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _selectedImage.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await ImageSourceSelector.show(context);
    if (result != null && mounted) {
      XFile? image;
      if (result == true) {
        // Camera
        image = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
          maxWidth: 1920,
          maxHeight: 1080,
        );
      } else {
        // Gallery
        image = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
          maxWidth: 1920,
          maxHeight: 1080,
        );
      }

      if (image != null && mounted) {
        _selectedImage.value = File(image.path);
      }
    }
  }

  void _removeImage() {
    _selectedImage.value = null;
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    final image = _selectedImage.value;
    if (text.isNotEmpty || image != null) {
      widget.onSubmit(text, image);
      _controller.clear();
      _selectedImage.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;
    final backgroundColor =
        isLightMode ? Colors.white : const Color(0xFF2D2D2D);
    final borderColor =
        isLightMode
            ? Colors.grey.withOpacity(0.2)
            : Colors.white.withOpacity(0.1);
    final hintColor = isLightMode ? Colors.black38 : Colors.white38;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color:
                  isLightMode
                      ? Colors.grey.withOpacity(0.1)
                      : Colors.white.withOpacity(0.05),
              child: Row(
                children: [
                  Text(
                    'Replying to ${widget.replyingTo}',
                    style: _replyBannerStyle,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: widget.onCancelReply,
                    color: hintColor,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          // Image Preview
          ValueListenableBuilder<File?>(
            valueListenable: _selectedImage,
            builder: (context, selectedImage, _) {
              if (selectedImage == null) {
                return const SizedBox.shrink();
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        selectedImage,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _removeImage,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          padding: const EdgeInsets.all(4),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: widget.enabled ? _pickImage : null,
                  color: hintColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StableMultilineTextField(
                    key: const ValueKey('comment_input_stable_field'),
                    controller: _controller,
                    enabled: widget.enabled,
                    hintText:
                        widget.enabled
                            ? 'Add a comment...'
                            : (widget.disabledHint ?? 'You cannot comment here'),
                    hintStyle: _hintTextStyle,
                    borderRadius: BorderRadius.circular(20),
                    borderColor: _borderColor,
                    focusedBorderColor: const Color(0xFF74182F),
                  ),
                ),
                const SizedBox(width: 8),
                ListenableBuilder(
                  listenable: _submitStateListenable,
                  builder: (context, _) {
                    final canSubmit = _canSubmit;
                    return IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: canSubmit ? _handleSubmit : null,
                      color:
                          canSubmit ? const Color(0xFF74182F) : hintColor,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
