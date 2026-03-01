import 'package:flutter/foundation.dart';

const bool useFirebaseEmulators = bool.fromEnvironment(
  'USE_FIREBASE_EMULATORS',
  defaultValue: false,
);

const bool screenshotMode = bool.fromEnvironment(
  'SCREENSHOT_MODE',
  defaultValue: false,
);

const String screenshotAuthEmail = String.fromEnvironment(
  'SCREENSHOT_AUTH_EMAIL',
  defaultValue: 'screenshot@example.com',
);

const String screenshotAuthPassword = String.fromEnvironment(
  'SCREENSHOT_AUTH_PASSWORD',
  defaultValue: 'Passw0rd!',
);

String firebaseEmulatorHost() {
  if (kIsWeb) {
    return 'localhost';
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return '10.0.2.2';
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.fuchsia:
      return 'localhost';
  }
}
