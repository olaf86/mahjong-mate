import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app.dart';
import 'shared/config/runtime_mode.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  Object? initError;
  try {
    await _initializeFirebase();
    await _configureFirebaseServices();
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

Future<void> _initializeFirebase() async {
  if (useFirebaseEmulators) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'demo-api-key',
        appId: '1:1234567890:android:demo-mahjong-mate',
        messagingSenderId: '1234567890',
        projectId: 'mahjong-mate-app',
        storageBucket: 'mahjong-mate-app.appspot.com',
      ),
    );
    return;
  }

  await Firebase.initializeApp();
}

Future<void> _configureFirebaseServices() async {
  if (useFirebaseEmulators) {
    final host = firebaseEmulatorHost();
    debugPrint('Using Firebase emulators (host: $host)');
    FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
    return;
  }

  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleAppAttestWithDeviceCheckFallbackProvider(),
  );
}
