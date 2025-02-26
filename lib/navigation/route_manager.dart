import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

// Create a custom RouteObserver that manages history
class RouteHistoryObserver extends RouteObserver<PageRoute<dynamic>> {
  final List<PageRoute> _routeHistory = [];

  List<PageRoute> get routeHistory => List.unmodifiable(_routeHistory);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      _routeHistory.add(route);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (route is PageRoute && _routeHistory.contains(route)) {
      _routeHistory.remove(route);
    }
  }

  bool canPopToInitialRoute() {
    return _routeHistory.length > 1;
  }
}

// Create a navigation helper
class NavigationHelper {
  static final RouteHistoryObserver routeObserver = RouteHistoryObserver();

  static void navigateToPage(BuildContext context, Widget page) {
    if (kIsWeb && _isIOS()) {
      // For iOS web: use a controlled navigation without animation
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          opaque: true,
          barrierDismissible: false,
        ),
      );
    } else {
      // For others: use the platform's default navigation
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => page,
        ),
      );
    }
  }

  static bool _isIOS() {
    try {
      return Platform.isIOS;
    } catch (e) {
      // In web, check for iOS using user agent
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      return userAgent.contains('iphone') || userAgent.contains('ipad');
    }
  }
}
