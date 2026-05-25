import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:state/core/widgets/post_image_loading_placeholder.dart';

class FullscreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String Function(int index)? heroTagBuilder;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.heroTagBuilder,
  });

  static void show(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
    String Function(int index)? heroTagBuilder,
  }) {
    if (imageUrls.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder:
            (context) => FullscreenImageViewer(
              imageUrls: imageUrls,
              initialIndex: initialIndex.clamp(0, imageUrls.length - 1),
              heroTagBuilder: heroTagBuilder,
            ),
      ),
    );
  }

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late final PageController _pageController;
  late int _currentIndex;
  final Map<int, PhotoViewScaleStateController> _scaleStateControllers = {};
  final Map<int, StreamSubscription<PhotoViewScaleState>> _scaleSubscriptions =
      {};

  double _dragOffset = 0;
  bool _isDismissDragging = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final subscription in _scaleSubscriptions.values) {
      subscription.cancel();
    }
    for (final controller in _scaleStateControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  PhotoViewScaleStateController _scaleControllerFor(int index) {
    return _scaleStateControllers.putIfAbsent(index, () {
      final controller = PhotoViewScaleStateController();
      _scaleSubscriptions[index] = controller.outputScaleStateStream.listen((_) {
        if (_currentIndex == index && mounted) {
          setState(() {});
        }
      });
      return controller;
    });
  }

  bool get _canDragToDismiss {
    final controller = _scaleStateControllers[_currentIndex];
    if (controller == null) return true;
    return controller.scaleState == PhotoViewScaleState.initial;
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _dragOffset = 0;
      _isDismissDragging = false;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_canDragToDismiss && !_isDismissDragging) return;

    setState(() {
      _isDismissDragging = true;
      _dragOffset += details.delta.dy;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDismissDragging) return;

    final height = MediaQuery.sizeOf(context).height;
    final velocity = details.primaryVelocity ?? 0;
    final shouldDismiss =
        _dragOffset.abs() > height * 0.12 || velocity.abs() > 650;

    if (shouldDismiss) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _dragOffset = 0;
      _isDismissDragging = false;
    });
  }

  void _handleDragCancel() {
    if (!_isDismissDragging) return;
    setState(() {
      _dragOffset = 0;
      _isDismissDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final dragProgress = (_dragOffset.abs() / height).clamp(0.0, 1.0);
    final backgroundOpacity = (1 - dragProgress * 0.85).clamp(0.0, 1.0);
    final contentScale = (1 - dragProgress * 0.05).clamp(0.9, 1.0);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: backgroundOpacity),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart:
            _canDragToDismiss
                ? (_) => setState(() => _isDismissDragging = true)
                : null,
        onVerticalDragUpdate:
            _canDragToDismiss || _isDismissDragging ? _handleDragUpdate : null,
        onVerticalDragEnd: _isDismissDragging ? _handleDragEnd : null,
        onVerticalDragCancel: _handleDragCancel,
        child: Transform.translate(
          offset: Offset(0, _dragOffset),
          child: Transform.scale(
            scale: contentScale,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  physics:
                      _isDismissDragging
                          ? const NeverScrollableScrollPhysics()
                          : const PageScrollPhysics(),
                  itemCount: widget.imageUrls.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder:
                      (context, index) => _FullscreenPhotoPage(
                        imageUrl: widget.imageUrls[index],
                        heroTag:
                            index == widget.initialIndex
                                ? widget.heroTagBuilder?.call(index)
                                : null,
                        scaleStateController: _scaleControllerFor(index),
                        disableGestures: _isDismissDragging,
                      ),
                ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.imageUrls.length > 1)
                  SafeArea(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${_currentIndex + 1} / ${widget.imageUrls.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FullscreenPhotoPage extends StatefulWidget {
  final String imageUrl;
  final String? heroTag;
  final PhotoViewScaleStateController scaleStateController;
  final bool disableGestures;

  const _FullscreenPhotoPage({
    required this.imageUrl,
    this.heroTag,
    required this.scaleStateController,
    this.disableGestures = false,
  });

  @override
  State<_FullscreenPhotoPage> createState() => _FullscreenPhotoPageState();
}

class _FullscreenPhotoPageState extends State<_FullscreenPhotoPage> {
  bool _isImageReady = false;
  bool _hasError = false;
  ImageStreamListener? _listener;
  ImageStream? _stream;

  @override
  void initState() {
    super.initState();
    _preloadImage();
  }

  @override
  void didUpdateWidget(covariant _FullscreenPhotoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _removeListener();
      setState(() {
        _isImageReady = false;
        _hasError = false;
      });
      _preloadImage();
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

  void _preloadImage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final provider = NetworkImage(widget.imageUrl);
      _stream = provider.resolve(createLocalImageConfiguration(context));
      _listener = ImageStreamListener(
        (_, _) {
          if (mounted) {
            setState(() => _isImageReady = true);
          }
        },
        onError: (_, _) {
          if (mounted) {
            setState(() {
              _isImageReady = true;
              _hasError = true;
            });
          }
        },
      );
      _stream!.addListener(_listener!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (!_isImageReady)
          const PostImageLoadingPlaceholder(
            expand: true,
            isFullscreen: true,
          ),
        if (_isImageReady && _hasError)
          const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 48,
            ),
          ),
        if (_isImageReady && !_hasError)
          PhotoViewGestureDetectorScope(
            axis: Axis.vertical,
            child: _buildPhotoView(),
          ),
      ],
    );
  }

  Widget _buildPhotoView() {
    final photoView = PhotoView(
      imageProvider: NetworkImage(widget.imageUrl),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3,
      backgroundDecoration: const BoxDecoration(color: Colors.transparent),
      scaleStateController: widget.scaleStateController,
      disableGestures: widget.disableGestures,
      gaplessPlayback: true,
    );

    if (widget.heroTag != null) {
      return Hero(tag: widget.heroTag!, child: photoView);
    }

    return photoView;
  }
}
