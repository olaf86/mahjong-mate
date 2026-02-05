import 'package:flutter/material.dart';

import 'core/firebase/firebase_init_error_screen.dart';
import 'routing/app_router.dart';
import 'theme/app_theme.dart';

class MahjongMateApp extends StatelessWidget {
  const MahjongMateApp({super.key, this.initError});

  final Object? initError;

  @override
  Widget build(BuildContext context) {
    if (initError != null) {
      return MaterialApp(
        title: 'Mahjong Mate',
        theme: AppTheme.lightTheme,
        home: FirebaseInitErrorScreen(error: initError),
      );
    }

    return MaterialApp.router(
      title: 'Mahjong Mate',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
