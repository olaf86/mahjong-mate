import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'core/firebase/firebase_init_error_screen.dart';
import 'routing/app_router.dart';
import 'theme/app_theme.dart';

class MahjongMateApp extends StatefulWidget {
  const MahjongMateApp({super.key, this.initError});

  final Object? initError;

  @override
  State<MahjongMateApp> createState() => _MahjongMateAppState();
}

class _MahjongMateAppState extends State<MahjongMateApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    _initLinks();
  }

  Future<void> _initLinks() async {
    try {
      final initial = await _appLinks.getInitialLink();
      _handleUri(initial);
    } catch (_) {}
    _sub = _appLinks.uriLinkStream.listen(_handleUri, onError: (_) {});
  }

  void _handleUri(Uri? uri) {
    if (uri == null) return;
    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments.first == 'r') {
      final code = segments[1];
      if (code.isNotEmpty) {
        appRouter.go('/r/$code');
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initError != null) {
      return MaterialApp(
        title: 'Mahjong Mate',
        theme: AppTheme.lightTheme,
        home: FirebaseInitErrorScreen(error: widget.initError),
      );
    }

    return MaterialApp.router(
      title: 'Mahjong Mate',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
