import 'package:flutter/material.dart';
import 'package:state/app/app_router.dart';

abstract class INavigationService {
  Future<void> goToMainScaffold(BuildContext context);
  Future<void> goToSignIn(BuildContext context);
  Future<bool?> goToPostCreation(BuildContext context);
  Future<void> goToPostDetails(
    BuildContext context,
    String postId, {
    String? commentId,
  });
  Future<void> goToUserProfile(BuildContext context, String userId);
  Future<void> goToSearch(BuildContext context);
  void goToHomeTab(BuildContext context);
  void goToFollowingTab(BuildContext context);
  void goToNotificationsTab(BuildContext context);
  void goToUserTab(BuildContext context);
  void pop<T>(BuildContext context, [T? result]);
  void popUntilRoot(BuildContext context);
  void popUntil(BuildContext context, String routeName);
  Future<void> handleDeepLink(String path);
  bool isCurrentRoute(BuildContext context, String route);
  String getCurrentLocation(BuildContext context);
}

class NavigationService implements INavigationService {
  NavigationService();

  @override
  Future<void> goToMainScaffold(BuildContext context) async {
    try {
      AppRouter.goToMainScaffold(context);
    } catch (e) {
      _handleNavigationError('goToMainScaffold', e);
    }
  }

  @override
  Future<void> goToSignIn(BuildContext context) async {
    try {
      AppRouter.goToSignIn(context);
    } catch (e) {
      _handleNavigationError('goToSignIn', e);
    }
  }

  @override
  Future<bool?> goToPostCreation(BuildContext context) async {
    try {
      final result = await AppRouter.goToPostCreation(context);
      return result;
    } catch (e) {
      _handleNavigationError('goToPostCreation', e);
      return null;
    }
  }

  @override
  Future<void> goToPostDetails(
    BuildContext context,
    String postId, {
    String? commentId,
  }) async {
    try {
      await AppRouter.goToPostDetails(context, postId, commentId: commentId);
    } catch (e) {
      _handleNavigationError('goToPostDetails', e);
    }
  }

  @override
  Future<void> goToUserProfile(BuildContext context, String userId) async {
    try {
      AppRouter.goToUserProfile(context, userId);
    } catch (e) {
      _handleNavigationError('goToUserProfile', e);
    }
  }

  @override
  Future<void> goToSearch(BuildContext context) async {
    try {
      AppRouter.goToSearch(context);
    } catch (e) {
      _handleNavigationError('goToSearch', e);
    }
  }

  @override
  void goToHomeTab(BuildContext context) {
    try {
      AppRouter.goToHomeTab(context);
    } catch (e) {
      _handleNavigationError('goToHomeTab', e);
    }
  }

  @override
  void goToFollowingTab(BuildContext context) {
    try {
      AppRouter.goToFollowingTab(context);
    } catch (e) {
      _handleNavigationError('goToFollowingTab', e);
    }
  }

  @override
  void goToNotificationsTab(BuildContext context) {
    try {
      // Navigate to user tab since notifications are now integrated there
      AppRouter.goToUserTab(context);
    } catch (e) {
      _handleNavigationError('goToNotificationsTab', e);
    }
  }

  @override
  void goToUserTab(BuildContext context) {
    try {
      AppRouter.goToUserTab(context);
    } catch (e) {
      _handleNavigationError('goToUserTab', e);
    }
  }

  @override
  void pop<T>(BuildContext context, [T? result]) {
    try {
      AppRouter.pop(context, result);
    } catch (e) {
      _handleNavigationError('pop', e);
    }
  }

  @override
  void popUntilRoot(BuildContext context) {
    try {
      AppRouter.popUntilRoot(context);
    } catch (e) {
      _handleNavigationError('popUntilRoot', e);
    }
  }

  @override
  void popUntil(BuildContext context, String routeName) {
    try {
      AppRouter.popUntil(context, routeName);
    } catch (e) {
      _handleNavigationError('popUntil', e);
    }
  }

  @override
  Future<void> handleDeepLink(String path) async {
    try {
      AppRouter.handleDeepLink(path);
    } catch (e) {
      _handleNavigationError('handleDeepLink', e);
    }
  }

  @override
  bool isCurrentRoute(BuildContext context, String route) {
    try {
      return AppRouter.isCurrentRoute(context, route);
    } catch (e) {
      _handleNavigationError('isCurrentRoute', e);
      return false;
    }
  }

  @override
  String getCurrentLocation(BuildContext context) {
    try {
      return AppRouter.getCurrentLocation(context);
    } catch (e) {
      _handleNavigationError('getCurrentLocation', e);
      return '/';
    }
  }

  void _handleNavigationError(String method, dynamic error) {
    // Log navigation errors for debugging
    debugPrint('Navigation error in $method: $error');

    // In production, you might want to:
    // - Send to crash reporting service (Firebase Crashlytics, Sentry, etc.)
    // - Show user-friendly error messages
    // - Fallback to safe navigation
    // - Track analytics events
  }
}

/// Mock navigation service for testing
class MockNavigationService implements INavigationService {
  final List<String> _navigationCalls = [];

  List<String> get navigationCalls => List.unmodifiable(_navigationCalls);

  @override
  Future<void> goToMainScaffold(BuildContext context) async {
    _navigationCalls.add('goToMainScaffold');
  }

  @override
  Future<void> goToSignIn(BuildContext context) async {
    _navigationCalls.add('goToSignIn');
  }

  @override
  Future<bool?> goToPostCreation(BuildContext context) async {
    _navigationCalls.add('goToPostCreation');
    return true;
  }

  @override
  Future<void> goToPostDetails(
    BuildContext context,
    String postId, {
    String? commentId,
  }) async {
    _navigationCalls.add(
      'goToPostDetails:$postId${commentId != null ? ':$commentId' : ''}',
    );
  }

  @override
  Future<void> goToUserProfile(BuildContext context, String userId) async {
    _navigationCalls.add('goToUserProfile:$userId');
  }

  @override
  Future<void> goToSearch(BuildContext context) async {
    _navigationCalls.add('goToSearch');
  }

  @override
  void goToHomeTab(BuildContext context) {
    _navigationCalls.add('goToHomeTab');
  }

  @override
  void goToFollowingTab(BuildContext context) {
    _navigationCalls.add('goToFollowingTab');
  }

  @override
  void goToNotificationsTab(BuildContext context) {
    _navigationCalls.add('goToNotificationsTab');
  }

  @override
  void goToUserTab(BuildContext context) {
    _navigationCalls.add('goToUserTab');
  }

  @override
  void pop<T>(BuildContext context, [T? result]) {
    _navigationCalls.add('pop');
  }

  @override
  void popUntilRoot(BuildContext context) {
    _navigationCalls.add('popUntilRoot');
  }

  @override
  void popUntil(BuildContext context, String routeName) {
    _navigationCalls.add('popUntil:$routeName');
  }

  @override
  Future<void> handleDeepLink(String path) async {
    _navigationCalls.add('handleDeepLink:$path');
  }

  @override
  bool isCurrentRoute(BuildContext context, String route) {
    _navigationCalls.add('isCurrentRoute:$route');
    return true;
  }

  @override
  String getCurrentLocation(BuildContext context) {
    _navigationCalls.add('getCurrentLocation');
    return '/test';
  }

  void clearCalls() {
    _navigationCalls.clear();
  }
}
