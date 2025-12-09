import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _isComposing = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _controller.dispose();
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
        setState(() {
          _selectedImage = File(image!.path);
          _isComposing = true;
        });
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _isComposing = _controller.text.trim().isNotEmpty;
    });
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty || _selectedImage != null) {
      widget.onSubmit(text, _selectedImage);
      _controller.clear();
      setState(() {
        _isComposing = false;
        _selectedImage = null;
      });
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
                    style: GoogleFonts.beVietnamPro(
                      color: hintColor,
                      fontSize: 12,
                    ),
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
          if (_selectedImage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
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
                  child: TextField(
                    controller: _controller,
                    enabled: widget.enabled,
                    onChanged: (text) {
                      setState(
                        () =>
                            _isComposing =
                                text.trim().isNotEmpty ||
                                _selectedImage != null,
                      );
                    },
                    style: GoogleFonts.beVietnamPro(fontSize: 14),
                    decoration: InputDecoration(
                      hintText:
                          widget.enabled
                              ? 'Add a comment...'
                              : (widget.disabledHint ?? 'You cannot comment here'),
                      hintStyle: GoogleFonts.beVietnamPro(
                        color: hintColor,
                        fontSize: 14,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0xFF74182F)),
                      ),
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isComposing ? _handleSubmit : null,
                  color: _isComposing ? const Color(0xFF74182F) : hintColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
