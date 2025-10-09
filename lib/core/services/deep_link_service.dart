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
    if (_isPostLink(uri)) {
      final postId = _extractPostId(uri);
      if (postId != null) {
        _pendingDeepLink = postId;
        debugPrint('Pending deep link for post: $postId');
      }
    }
  }

  /// Handle deep links received while app is running
  void _handleDeepLinkStream(Uri? uri) {
    if (uri == null) return;

    debugPrint('Deep link received: ${uri.path}');

    if (_isPostLink(uri)) {
      final postId = _extractPostId(uri);
      if (postId != null) {
        _navigateToPost(postId);
      }
    }
  }

  /// Check if URI is a post deep link
  bool _isPostLink(Uri uri) {
    return uri.pathSegments.isNotEmpty &&
        uri.pathSegments[0] == 'post' &&
        uri.pathSegments.length > 1;
  }

  /// Extract post ID from URI
  String? _extractPostId(Uri uri) {
    if (uri.pathSegments.length > 1) {
      return uri.pathSegments[1];
    }
    return null;
  }

  /// Navigate to post details
  void _navigateToPost(String postId) {
    Future.delayed(const Duration(milliseconds: 500), () {
      AppRouter.router.push('/post-details/$postId');
    });
  }

  /// Handle any pending deep link
  /// Should be called when main screen is loaded
  void handlePendingDeepLink() {
    if (_pendingDeepLink != null) {
      final postId = _pendingDeepLink!;
      _pendingDeepLink = null;
      debugPrint('Handling pending deep link: $postId');
      _navigateToPost(postId);
    }
  }

  /// Check if there's a pending deep link
  bool hasPendingDeepLink() => _pendingDeepLink != null;
}
