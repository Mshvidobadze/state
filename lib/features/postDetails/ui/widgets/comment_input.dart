import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CommentInput extends StatefulWidget {
  final Function(String) onSubmit;
  final String? replyingTo;
  final VoidCallback? onCancelReply;

  const CommentInput({
    super.key,
    required this.onSubmit,
    this.replyingTo,
    this.onCancelReply,
  });

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final _controller = TextEditingController();
  bool _isComposing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSubmit(text);
      _controller.clear();
      setState(() => _isComposing = false);
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: (text) {
                      setState(() => _isComposing = text.trim().isNotEmpty);
                    },
                    style: GoogleFonts.beVietnamPro(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
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
                        borderSide: const BorderSide(color: Color(0xFF1A237E)),
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
                  color: _isComposing ? const Color(0xFF1A237E) : hintColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
