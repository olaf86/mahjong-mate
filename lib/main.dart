import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app.dart';

const bool kForceDebugAppCheckProvider = bool.fromEnvironment(
  "APP_CHECK_DEBUG",
);

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  Object? initError;
  try {
    await Firebase.initializeApp();
    final useDebugAppCheckProvider = kDebugMode || kForceDebugAppCheckProvider;
    await FirebaseAppCheck.instance.activate(
      providerAndroid: useDebugAppCheckProvider
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: useDebugAppCheckProvider
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (error) {
    initError = error;
  } finally {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    FlutterNativeSplash.remove();
  }

  runApp(ProviderScope(child: MahjongMateApp(initError: initError)));
}
