import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:state/core/configs/assets/app_vectors.dart';
import 'package:state/core/constants/ui_constants.dart';
import 'package:state/core/widgets/shimmer.dart';

class PostImageLoadingPlaceholder extends StatelessWidget {
  final double? height;
  final BorderRadius borderRadius;
  final bool expand;
  final bool isFullscreen;

  static const Color _logoColor = Color(0xFF9CA3AF);

  const PostImageLoadingPlaceholder({
    super.key,
    this.height,
    this.borderRadius = BorderRadius.zero,
    this.expand = false,
    this.isFullscreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isFullscreen ? const Color(0xFF1A1A1A) : const Color(0xFFE9EBEE);
    final shimmerHighlight =
        isFullscreen ? const Color(0xFF2A2A2A) : const Color(0xFFF7F8FA);

    final placeholder = ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Shimmer(
              baseColor: backgroundColor,
              highlightColor: shimmerHighlight,
              child: ColoredBox(color: backgroundColor),
            ),
          ),
          SvgPicture.asset(
            AppVectors.appLogo,
            width: UIConstants.loadingPlaceholderSize,
            height: UIConstants.loadingPlaceholderSize,
            colorFilter: const ColorFilter.mode(_logoColor, BlendMode.srcIn),
          ),
        ],
      ),
    );

    if (expand) {
      return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: placeholder,
      );
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: placeholder,
    );
  }
}
