import 'package:flutter/foundation.dart';

const bool useFirebaseEmulators = bool.fromEnvironment(
  'USE_FIREBASE_EMULATORS',
  defaultValue: false,
);

const bool screenshotMode = bool.fromEnvironment(
  'SCREENSHOT_MODE',
  defaultValue: false,
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
