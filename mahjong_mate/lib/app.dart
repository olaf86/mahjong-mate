import 'package:flutter/material.dart';

import 'routing/app_router.dart';
import 'theme/app_theme.dart';

class MahjongMateApp extends StatelessWidget {
  const MahjongMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mahjong Mate',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
