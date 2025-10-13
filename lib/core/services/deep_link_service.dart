import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:state/app/app_router.dart';

/// Service to handle deep links for both app links and custom URL schemes
/// Follows the same pattern as NotificationService for consistency
class DeepLinkService {
  static DeepLinkService? _instance;
  final AppLinks _appLinks;
  String? _pendingDeepLink;

  @visibleForTesting
  DeepLinkService.withAppLinks(this._appLinks);

  factory DeepLinkService() {
    _instance ??= DeepLinkService._internal();
    return _instance!;
  }

  DeepLinkService._internal() : _appLinks = AppLinks();

  /// Initialize deep link handling
  /// Should be called during app startup
  Future<void> initialize() async {
    // Check for initial deep link (when app is opened from a link)
    _appLinks.getInitialLink().then((Uri? uri) {
      if (uri != null) {
        _handleInitialLink(uri);
      }
    });

    // Listen for deep links when app is already running
    _appLinks.uriLinkStream.listen(
      _handleDeepLinkStream,
      onError: (err) {
        debugPrint('Deep link error: $err');
      },
    );
  }

  /// Handle initial deep link when app is cold started
  void _handleInitialLink(Uri uri) {
    debugPrint('🔗 [DEEP LINK] Initial link received');
    debugPrint('🔗 [DEEP LINK] Full URI: $uri');
    debugPrint('🔗 [DEEP LINK] Host: ${uri.host}');
    debugPrint('🔗 [DEEP LINK] Path: ${uri.path}');
    debugPrint('🔗 [DEEP LINK] Path segments: ${uri.pathSegments}');

    if (_isPostLink(uri)) {
      final postId = _extractPostId(uri);
      debugPrint('🔗 [DEEP LINK] Is post link: true');
      debugPrint('🔗 [DEEP LINK] Extracted post ID: $postId');
      if (postId != null) {
        _pendingDeepLink = postId;
        debugPrint('🔗 [DEEP LINK] Pending deep link for post: $postId');
      }
    } else {
      debugPrint('🔗 [DEEP LINK] Is post link: false');
    }
  }

  /// Handle deep links received while app is running
  void _handleDeepLinkStream(Uri? uri) {
    if (uri == null) {
      debugPrint('🔗 [DEEP LINK] Received null URI');
      return;
    }

    debugPrint('🔗 [DEEP LINK] Deep link received while app running');
    debugPrint('🔗 [DEEP LINK] Full URI: $uri');
    debugPrint('🔗 [DEEP LINK] Host: ${uri.host}');
    debugPrint('🔗 [DEEP LINK] Path: ${uri.path}');
    debugPrint('🔗 [DEEP LINK] Path segments: ${uri.pathSegments}');

    if (_isPostLink(uri)) {
      final postId = _extractPostId(uri);
      debugPrint('🔗 [DEEP LINK] Is post link: true');
      debugPrint('🔗 [DEEP LINK] Extracted post ID: $postId');
      if (postId != null) {
        _navigateToPost(postId);
      }
    } else {
      debugPrint('🔗 [DEEP LINK] Is post link: false');
    }
  }

  /// Check if URI is a post deep link
  /// Handles both HTTPS URLs (https://stateapp.net/post/ID)
  /// and custom scheme URLs (stateapp://post/ID)
  bool _isPostLink(Uri uri) {
    debugPrint('🔗 [DEEP LINK] _isPostLink check:');
    debugPrint('  - Scheme: ${uri.scheme}');
    debugPrint('  - Host: ${uri.host}');
    debugPrint('  - pathSegments.isNotEmpty: ${uri.pathSegments.isNotEmpty}');
    debugPrint(
      '  - first segment: ${uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : 'N/A'}',
    );
    debugPrint('  - pathSegments.length: ${uri.pathSegments.length}');

    // For custom scheme URLs (stateapp://post/ID), "post" is the host
    if (uri.scheme == 'stateapp' &&
        uri.host == 'post' &&
        uri.pathSegments.isNotEmpty) {
      debugPrint('  - Result: true (custom scheme with host=post)');
      return true;
    }

    // For HTTPS URLs (https://stateapp.net/post/ID), "post" is the first path segment
    final isPost =
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments[0] == 'post' &&
        uri.pathSegments.length > 1;
    debugPrint('  - Result: $isPost (HTTPS URL check)');
    return isPost;
  }

  /// Extract post ID from URI
  /// Handles both HTTPS URLs and custom scheme URLs
  String? _extractPostId(Uri uri) {
    // For custom scheme URLs (stateapp://post/ID), the ID is the first path segment
    if (uri.scheme == 'stateapp' && uri.host == 'post') {
      if (uri.pathSegments.isNotEmpty) {
        final postId = uri.pathSegments[0];
        debugPrint(
          '🔗 [DEEP LINK] Extracting post ID from custom scheme: $postId',
        );
        return postId;
      }
    }

    // For HTTPS URLs (https://stateapp.net/post/ID), the ID is the second path segment
    if (uri.pathSegments.length > 1) {
      final postId = uri.pathSegments[1];
      debugPrint('🔗 [DEEP LINK] Extracting post ID from HTTPS URL: $postId');
      return postId;
    }

    debugPrint('🔗 [DEEP LINK] No post ID found in segments');
    return null;
  }

  /// Navigate to post details
  void _navigateToPost(String postId) {
    debugPrint('🔗 [DEEP LINK] Preparing to navigate to post: $postId');
    debugPrint('🔗 [DEEP LINK] Target route: /post-details/$postId');
    Future.delayed(const Duration(milliseconds: 500), () {
      debugPrint(
        '🔗 [DEEP LINK] Executing navigation to: /post-details/$postId',
      );
      AppRouter.router.push('/post-details/$postId');
    });
  }

  /// Handle any pending deep link
  /// Should be called when main screen is loaded
  void handlePendingDeepLink() {
    debugPrint('🔗 [DEEP LINK] handlePendingDeepLink called');
    debugPrint(
      '🔗 [DEEP LINK] Has pending deep link: ${_pendingDeepLink != null}',
    );
    if (_pendingDeepLink != null) {
      final postId = _pendingDeepLink!;
      _pendingDeepLink = null;
      debugPrint('🔗 [DEEP LINK] Handling pending deep link: $postId');
      _navigateToPost(postId);
    }
  }

  /// Check if there's a pending deep link
  bool hasPendingDeepLink() => _pendingDeepLink != null;
}
