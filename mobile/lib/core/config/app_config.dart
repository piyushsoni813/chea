import 'package:flutter/foundation.dart';

/// All runtime configuration in one place.
///
/// Development:
/// - Web            -> localhost
/// - Android Emulator -> 10.0.2.2
/// - Windows/Desktop -> localhost
///
/// Production:
/// - https://api.chea.edu
class AppConfig {
  AppConfig._();

  static const _env = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  static String get baseUrl {
    if (_env == 'production') {
      return 'https://api.chea.edu/api/v1';
    }

    // Development
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android Emulator
        return 'http://10.0.2.2:8000/api/v1';

      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return 'http://localhost:8000/api/v1';

      case TargetPlatform.iOS:
        // iOS Simulator
        return 'http://localhost:8000/api/v1';

      case TargetPlatform.fuchsia:
        return 'http://localhost:8000/api/v1';
    }
  }

  static const apiVersion = 'v1';
}