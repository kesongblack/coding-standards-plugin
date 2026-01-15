# Flutter Production Safety Standards

## Overview

These rules ensure your Flutter application is properly configured for production/release builds.

---

## Debug Banner

### debug-banner-disabled

**Severity:** error

The debug banner must be disabled in production builds.

**Why?**
- Unprofessional appearance in released apps
- Indicates incomplete release configuration
- May confuse end users

**Bad:**
```dart
MaterialApp(
  debugShowCheckedModeBanner: true,  // Shows "DEBUG" banner
  home: MyHomePage(),
);
```

**Good:**
```dart
MaterialApp(
  debugShowCheckedModeBanner: false,  // No banner in release
  home: MyHomePage(),
);
```

**Note:** The banner is hidden by default in release builds, but explicitly setting it to `false` is recommended.

---

## Print Statements

### no-print-statements

**Severity:** warning

Print statements should be removed from production code.

**Why?**
- Output goes to system logs (accessible on some devices)
- Performance overhead
- Can expose sensitive information
- Not visible to users anyway

**Bad:**
```dart
void fetchUser() async {
  print('Fetching user...');  // Remove this
  final user = await api.getUser();
  debugPrint('User: $user');  // And this
}
```

**Good:**
```dart
import 'package:logger/logger.dart';

final logger = Logger();

void fetchUser() async {
  logger.d('Fetching user...');  // Proper logging
  final user = await api.getUser();
}
```

**Alternatives:**
- Use `logger` package for structured logging
- Use `flutter_logs` for file-based logging
- Conditionally log with `kDebugMode`

---

## Release Signing

### release-signing

**Severity:** error

Android release builds must have proper signing configuration.

**Why?**
- Required for Play Store submission
- Identifies your app uniquely
- Prevents tampering with APK
- Required for app updates

**Setup in `android/app/build.gradle`:**
```gradle
android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release  // Must be set!
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

**Checklist:**
- [ ] Keystore file created and securely stored
- [ ] `key.properties` file configured (not in git!)
- [ ] Release build type uses release signing config

---

## Debug Mode Checks

### no-kdebugmode-unchecked

**Severity:** warning

`kDebugMode` should be used with proper conditional checks.

**Why?**
- Ensures debug code doesn't run in release
- Makes intent clear
- Compiler can optimize away debug blocks

**Bad:**
```dart
// kDebugMode used without condition
void logData() {
  print(kDebugMode);  // Just checking the value?
}
```

**Good:**
```dart
void logData(String data) {
  if (kDebugMode) {
    print('Debug: $data');  // Only runs in debug
  }
}

// Or use assertion (removed in release)
void validateData(String data) {
  assert(() {
    print('Validating: $data');
    return true;
  }());
}
```

**Best Practice:**
```dart
import 'package:flutter/foundation.dart';

void sensitiveOperation() {
  if (kDebugMode) {
    // Debug-only logging
    print('Sensitive data for debugging');
  }
  // Production code continues...
}
```
