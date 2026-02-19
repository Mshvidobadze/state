import 'package:flutter/material.dart';

class PostImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  final BorderRadius borderRadius;
  final BoxFit fit;
  final bool showIndicator;
  final ValueChanged<int>? onImageTap;
  final VoidCallback? onDoubleTap;
  final String Function(int index)? heroTagBuilder;

  const PostImageCarousel({
    super.key,
    required this.imageUrls,
    this.height = 320,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.fit = BoxFit.contain,
    this.showIndicator = true,
    this.onImageTap,
    this.onDoubleTap,
    this.heroTagBuilder,
  });

  @override
  State<PostImageCarousel> createState() => _PostImageCarouselState();
}

class _PostImageCarouselState extends State<PostImageCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(covariant PostImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrls.isEmpty) {
      _currentPage = 0;
      return;
    }
    if (_currentPage >= widget.imageUrls.length) {
      _currentPage = widget.imageUrls.length - 1;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentPage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final image = ClipRRect(
                borderRadius: widget.borderRadius,
                child: Image.network(
                  widget.imageUrls[index],
                  width: double.infinity,
                  fit: widget.fit,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: const Color(0xFFF3F4F6),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFF3F4F6),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: Color(0xFF9CA3AF),
                        size: 28,
                      ),
                    );
                  },
                ),
              );

              final heroTag = widget.heroTagBuilder?.call(index);
              final wrappedImage =
                  heroTag != null ? Hero(tag: heroTag, child: image) : image;

              return GestureDetector(
                onTap: widget.onImageTap == null ? null : () => widget.onImageTap!(index),
                onDoubleTap: widget.onDoubleTap,
                child: wrappedImage,
              );
            },
          ),
        ),
        if (widget.showIndicator && widget.imageUrls.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.imageUrls.length, (index) {
              final isActive = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 8 : 6,
                height: isActive ? 8 : 6,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF121416) : const Color(0xFFBFC5CC),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
