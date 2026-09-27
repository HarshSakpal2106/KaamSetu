// Replace this file by running:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Until then, Firebase stays off and the app uses mock login.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(_message);
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        throw UnsupportedError(_message);
      default:
        throw UnsupportedError(_message);
    }
  }

  static const String _message =
      'Firebase is not configured yet. Run: dart pub global activate flutterfire_cli && flutterfire configure';
}
