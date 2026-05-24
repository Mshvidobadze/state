import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Multiline text field isolated from parent rebuilds to avoid Android/iOS
/// selection/cursor glitches when the widget tree updates while focused.
class StableMultilineTextField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final String hintText;
  final int? maxLines;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final InputDecoration? decoration;
  final EdgeInsetsGeometry? contentPadding;
  final BorderRadius borderRadius;
  final Color borderColor;
  final Color focusedBorderColor;

  const StableMultilineTextField({
    super.key,
    required this.controller,
    this.enabled = true,
    required this.hintText,
    this.maxLines,
    this.textStyle,
    this.hintStyle,
    this.decoration,
    this.contentPadding,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.borderColor = const Color(0x4D9E9E9E),
    this.focusedBorderColor = Colors.black54,
  });

  @override
  State<StableMultilineTextField> createState() =>
      _StableMultilineTextFieldState();
}

class _StableMultilineTextFieldState extends State<StableMultilineTextField> {
  late final FocusNode _focusNode;
  late TextStyle _textStyle;
  late TextStyle _hintStyle;
  late InputDecoration _inputDecoration;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _cacheStylesAndDecoration();
  }

  @override
  void didUpdateWidget(covariant StableMultilineTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.hintText != widget.hintText ||
        oldWidget.decoration != widget.decoration ||
        oldWidget.borderColor != widget.borderColor ||
        oldWidget.focusedBorderColor != widget.focusedBorderColor ||
        oldWidget.borderRadius != widget.borderRadius ||
        oldWidget.contentPadding != widget.contentPadding ||
        oldWidget.textStyle != widget.textStyle ||
        oldWidget.hintStyle != widget.hintStyle) {
      _cacheStylesAndDecoration();
    }
  }

  void _cacheStylesAndDecoration() {
    final fontFamily = GoogleFonts.beVietnamPro().fontFamily;
    _textStyle =
        widget.textStyle ??
        TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          color: const Color(0xFF121416),
        );
    _hintStyle =
        widget.hintStyle ??
        TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          color: Colors.black38,
        );

    if (widget.decoration != null) {
      _inputDecoration = widget.decoration!;
      return;
    }

    final outlineBorder = OutlineInputBorder(
      borderRadius: widget.borderRadius,
      borderSide: BorderSide(color: widget.borderColor),
    );

    _inputDecoration = InputDecoration(
      hintText: widget.hintText,
      hintStyle: _hintStyle,
      isDense: true,
      contentPadding:
          widget.contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: outlineBorder,
      enabledBorder: outlineBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: widget.borderRadius,
        borderSide: BorderSide(color: widget.focusedBorderColor),
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: TextField(
        key: const ValueKey('stable_multiline_text_field'),
        controller: widget.controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        style: _textStyle,
        decoration: _inputDecoration,
        maxLines: widget.maxLines,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        smartDashesType: SmartDashesType.disabled,
        smartQuotesType: SmartQuotesType.disabled,
        scrollPhysics: const ClampingScrollPhysics(),
      ),
    );
  }
}
