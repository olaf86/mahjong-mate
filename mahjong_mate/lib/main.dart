import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? initError;
  try {
    await Firebase.initializeApp();
  } catch (error) {
    initError = error;
  }

  runApp(ProviderScope(child: MahjongMateApp(initError: initError)));
}
