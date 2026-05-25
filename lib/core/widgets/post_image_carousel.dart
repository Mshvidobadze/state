import 'package:flutter/material.dart';
import 'package:state/core/constants/ui_constants.dart';
import 'package:state/core/widgets/post_image_loading_placeholder.dart';

class PostImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  final bool useNaturalHeight;
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
    this.useNaturalHeight = false,
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
  final Map<int, double> _naturalHeights = {};

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
      _naturalHeights.clear();
      return;
    }
    if (_currentPage >= widget.imageUrls.length) {
      _currentPage = widget.imageUrls.length - 1;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentPage);
      }
    }
    if (oldWidget.imageUrls != widget.imageUrls) {
      _naturalHeights.clear();
    }
  }

  double _carouselHeight(double maxWidth) {
    if (!widget.useNaturalHeight) {
      return widget.height;
    }

    return _naturalHeights[_currentPage] ??
        widget.height.clamp(
          UIConstants.loadingPlaceholderHeight,
          double.infinity,
        );
  }

  void _handleNaturalHeightResolved(int index, double height) {
    if (!widget.useNaturalHeight || _naturalHeights[index] == height) return;
    setState(() => _naturalHeights[index] = height);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final carouselHeight = _carouselHeight(constraints.maxWidth);

        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              height: carouselHeight,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.imageUrls.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final image = ClipRRect(
                    borderRadius: widget.borderRadius,
                    child: _CarouselNetworkImage(
                      imageUrl: widget.imageUrls[index],
                      fit: widget.fit,
                      placeholderHeight: carouselHeight,
                      borderRadius: widget.borderRadius,
                      useNaturalHeight: widget.useNaturalHeight,
                      onNaturalHeightResolved:
                          (height) =>
                              _handleNaturalHeightResolved(index, height),
                    ),
                  );

                  final heroTag = widget.heroTagBuilder?.call(index);
                  final wrappedImage =
                      heroTag != null ? Hero(tag: heroTag, child: image) : image;

                  return GestureDetector(
                    onTap:
                        widget.onImageTap == null
                            ? null
                            : () => widget.onImageTap!(index),
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
                      color:
                          isActive
                              ? const Color(0xFF121416)
                              : const Color(0xFFBFC5CC),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class _CarouselNetworkImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double placeholderHeight;
  final BorderRadius borderRadius;
  final bool useNaturalHeight;
  final ValueChanged<double>? onNaturalHeightResolved;

  const _CarouselNetworkImage({
    required this.imageUrl,
    required this.fit,
    required this.placeholderHeight,
    required this.borderRadius,
    required this.useNaturalHeight,
    this.onNaturalHeightResolved,
  });

  @override
  State<_CarouselNetworkImage> createState() => _CarouselNetworkImageState();
}

class _CarouselNetworkImageState extends State<_CarouselNetworkImage> {
  ImageStreamListener? _listener;
  ImageStream? _stream;

  @override
  void initState() {
    super.initState();
    _resolveNaturalHeight();
  }

  @override
  void didUpdateWidget(covariant _CarouselNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _removeListener();
      _resolveNaturalHeight();
    }
  }

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  void _removeListener() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    _stream = null;
    _listener = null;
  }

  void _resolveNaturalHeight() {
    if (!widget.useNaturalHeight) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final maxWidth = context.size?.width;
      if (maxWidth == null || maxWidth <= 0) return;

      final provider = NetworkImage(widget.imageUrl);
      _stream = provider.resolve(createLocalImageConfiguration(context));
      _listener = ImageStreamListener((info, _) {
        final aspectRatio = info.image.height / info.image.width;
        widget.onNaturalHeightResolved?.call(maxWidth * aspectRatio);
      });
      _stream!.addListener(_listener!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = PostImageLoadingPlaceholder(
      height: widget.placeholderHeight,
      borderRadius: widget.borderRadius,
    );

    return Image.network(
      widget.imageUrl,
      width: double.infinity,
      fit: widget.fit,
      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return placeholder;
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return placeholder;
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: widget.placeholderHeight,
          width: double.infinity,
          color: const Color(0xFFE9EBEE),
          alignment: Alignment.center,
          child: const Icon(
            Icons.broken_image_outlined,
            color: Color(0xFF9CA3AF),
            size: 28,
          ),
        );
      },
    );
  }
}
