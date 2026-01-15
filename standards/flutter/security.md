# Flutter Security Standards

## Secure Storage

Never store sensitive data in plain storage.

**Good:**
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
```

**Bad:**
```dart
import 'package:shared_preferences/shared_preferences.dart';

// INSECURE - SharedPreferences is not encrypted
class InsecureStorage {
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);  // Plain text!
  }
}

// INSECURE - Storing in files
import 'dart:io';

Future<void> saveToken(String token) async {
  final file = File('token.txt');
  await file.writeAsString(token);  // Plain text file!
}
```

### Why?
- Data encrypted at rest
- Keychain/Keystore protection
- Secure against device access

---

## API Key Protection

Never hardcode API keys in source code.

**Good:**
```dart
// Using --dart-define at build time
// flutter build apk --dart-define=API_KEY=your_key

class Config {
  static const String apiKey = String.fromEnvironment('API_KEY');
  static const String apiUrl = String.fromEnvironment('API_URL');
}

// For development, use .env with flutter_dotenv
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');
  runApp(MyApp());
}

class ApiService {
  final String apiKey = dotenv.env['API_KEY'] ?? '';
}
```

**Bad:**
```dart
// INSECURE - Hardcoded keys
class ApiService {
  static const String apiKey = 'sk_live_abc123xyz';  // Exposed!
  static const String secret = 'my_super_secret';    // Exposed!
}

// INSECURE - Keys in version control
// .env committed to git with secrets
```

**.gitignore:**
```gitignore
.env
.env.*
*.jks
*.keystore
key.properties
```

### Why?
- Keys not in source code
- Build-time injection
- Not in version control

---

## Network Security

Use HTTPS and certificate pinning.

**Good:**
```dart
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:io';

class SecureApiClient {
  late final Dio _dio;

  SecureApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.example.com',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // Certificate pinning
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) {
        // Verify certificate fingerprint
        final expectedFingerprint = 'AA:BB:CC:DD:...';
        final actualFingerprint = cert.sha256.toString();
        return actualFingerprint == expectedFingerprint;
      };
      return client;
    };
  }
}

// Using http_certificate_pinning package
import 'package:http_certificate_pinning/http_certificate_pinning.dart';

Future<void> makeSecureRequest() async {
  final response = await HttpCertificatePinning.check(
    serverURL: 'https://api.example.com',
    sha: SHA.SHA256,
    allowedSHAFingerprints: ['AA:BB:CC:DD:...'],
    timeout: 50,
  );
}
```

**Bad:**
```dart
// INSECURE - Disabling certificate verification
(_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
  final client = HttpClient();
  client.badCertificateCallback = (cert, host, port) => true;  // Accepts any!
  return client;
};

// INSECURE - Using HTTP
final response = await http.get(Uri.parse('http://api.example.com'));
```

### Why?
- Prevents MITM attacks
- Validates server identity
- Encrypted communication

---

## Input Validation

Validate all user input before processing.

**Good:**
```dart
class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email format';
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain uppercase letter';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain a number';
    }

    return null;
  }

  static String? sanitizeInput(String input) {
    // Remove potentially dangerous characters
    return input.replaceAll(RegExp(r'[<>"\']'), '');
  }
}

// Usage in Form
TextFormField(
  validator: Validators.email,
  decoration: InputDecoration(labelText: 'Email'),
);
```

**Bad:**
```dart
// No validation
void submitForm(String email, String password) {
  // Directly using unvalidated input
  api.login(email, password);
}

// Weak validation
if (email.contains('@')) {
  // Not comprehensive
}
```

### Why?
- Prevents injection attacks
- Catches malformed data
- Better UX with clear errors

---

## Code Obfuscation

Obfuscate release builds.

**Good:**
```bash
# Build with obfuscation
flutter build apk --obfuscate --split-debug-info=./debug-info

flutter build appbundle --obfuscate --split-debug-info=./debug-info

flutter build ipa --obfuscate --split-debug-info=./debug-info
```

**Store debug symbols:**
```bash
# Keep debug-info for crash reports
./debug-info/
├── app.android-arm.symbols
├── app.android-arm64.symbols
└── app.android-x64.symbols
```

**android/app/build.gradle:**
```groovy
android {
    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

### Why?
- Harder to reverse engineer
- Protects business logic
- Reduces APK size

---

## Biometric Authentication

Implement biometrics securely.

**Good:**
```dart
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    final canCheck = await _auth.canCheckBiometrics;
    final isDeviceSupported = await _auth.isDeviceSupported();
    return canCheck && isDeviceSupported;
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to access your account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,  // Allow PIN/pattern fallback
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _auth.getAvailableBiometrics();
  }
}

// Usage
class LoginScreen extends StatelessWidget {
  final BiometricService _biometric = BiometricService();

  Future<void> _handleBiometricLogin() async {
    final isAvailable = await _biometric.isBiometricAvailable();

    if (!isAvailable) {
      // Show message or fallback
      return;
    }

    final authenticated = await _biometric.authenticate();

    if (authenticated) {
      // Proceed with login
      final token = await SecureStorageService().getToken();
      if (token != null) {
        // Navigate to home
      }
    }
  }
}
```

### Why?
- Secure authentication
- User convenience
- Device-level security

---

## Data Encryption

Encrypt sensitive data in transit and at rest.

**Good:**
```dart
import 'package:encrypt/encrypt.dart';

class EncryptionService {
  final Key _key = Key.fromSecureRandom(32);
  final IV _iv = IV.fromSecureRandom(16);

  String encrypt(String plainText) {
    final encrypter = Encrypter(AES(_key));
    final encrypted = encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  String decrypt(String encryptedText) {
    final encrypter = Encrypter(AES(_key));
    final decrypted = encrypter.decrypt64(encryptedText, iv: _iv);
    return decrypted;
  }
}

// For sensitive model data
class SensitiveData {
  final String encryptedSsn;
  final String encryptedCreditCard;

  SensitiveData({
    required String ssn,
    required String creditCard,
  })  : encryptedSsn = EncryptionService().encrypt(ssn),
        encryptedCreditCard = EncryptionService().encrypt(creditCard);
}
```

**Bad:**
```dart
// INSECURE - Plain text sensitive data
class User {
  final String ssn;          // Plain text!
  final String creditCard;   // Plain text!
}

// INSECURE - Base64 is not encryption
String "encrypt"(String data) {
  return base64Encode(utf8.encode(data));  // Easily decoded!
}
```

### Why?
- Protects sensitive data
- AES is industry standard
- Key management matters

---

## Preventing Root/Jailbreak

Detect compromised devices.

**Good:**
```dart
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

class SecurityCheck {
  static Future<bool> isDeviceSecure() async {
    final isJailbroken = await FlutterJailbreakDetection.jailbroken;
    final developerMode = await FlutterJailbreakDetection.developerMode;

    if (isJailbroken) {
      // Log security event
      // Optionally restrict functionality
      return false;
    }

    return true;
  }
}

// Usage at app start
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isSecure = await SecurityCheck.isDeviceSecure();

  if (!isSecure) {
    runApp(SecurityWarningApp());
  } else {
    runApp(MyApp());
  }
}

class SecurityWarningApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'This app cannot run on rooted/jailbroken devices',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
```

### Why?
- Reduced attack surface
- Compliance requirements
- Protects sensitive operations

---

## Secure WebViews

Configure WebViews securely.

**Good:**
```dart
import 'package:webview_flutter/webview_flutter.dart';

class SecureWebView extends StatefulWidget {
  final String url;

  const SecureWebView({required this.url});

  @override
  State<SecureWebView> createState() => _SecureWebViewState();
}

class _SecureWebViewState extends State<SecureWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)  // Disable if not needed
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            // Only allow HTTPS
            if (!request.url.startsWith('https://')) {
              return NavigationDecision.prevent;
            }

            // Whitelist domains
            final allowedDomains = ['example.com', 'trusted.com'];
            final uri = Uri.parse(request.url);

            if (!allowedDomains.contains(uri.host)) {
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
```

**Bad:**
```dart
// INSECURE - No restrictions
WebViewWidget(
  controller: WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadRequest(Uri.parse(userProvidedUrl)),  // Any URL!
);
```

### Why?
- Prevents XSS in WebViews
- Controls navigation
- Limits JavaScript access

---

## Logging Security

Don't log sensitive information.

**Good:**
```dart
class Logger {
  static void info(String message, [Map<String, dynamic>? data]) {
    final sanitized = _sanitize(data);
    debugPrint('[INFO] $message ${sanitized ?? ''}');
  }

  static void error(String message, [dynamic error, StackTrace? stack]) {
    debugPrint('[ERROR] $message');
    if (error != null) {
      debugPrint('Error: $error');
    }
  }

  static Map<String, dynamic>? _sanitize(Map<String, dynamic>? data) {
    if (data == null) return null;

    final sensitiveKeys = ['password', 'token', 'secret', 'ssn', 'creditCard'];
    final sanitized = Map<String, dynamic>.from(data);

    for (final key in sensitiveKeys) {
      if (sanitized.containsKey(key)) {
        sanitized[key] = '***REDACTED***';
      }
    }

    return sanitized;
  }
}

// Usage
Logger.info('User login', {'email': email, 'password': password});
// Output: [INFO] User login {email: user@example.com, password: ***REDACTED***}
```

**Bad:**
```dart
// INSECURE - Logging sensitive data
print('Login attempt: email=$email, password=$password');
print('API Token: $token');
debugPrint('Credit Card: $creditCard');
```

### Why?
- Prevents credential leaks
- Protects user data
- Safe for crash reports

---

## Release Build Checks

Remove debug features in release.

**Good:**
```dart
import 'package:flutter/foundation.dart';

class AppConfig {
  static bool get isDebug => kDebugMode;
  static bool get isRelease => kReleaseMode;

  static String get apiUrl {
    if (kDebugMode) {
      return 'https://dev-api.example.com';
    }
    return 'https://api.example.com';
  }
}

// Conditional logging
void log(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

// Disable debug banner
MaterialApp(
  debugShowCheckedModeBanner: false,
  // ...
);

// Conditional features
Widget build(BuildContext context) {
  return Column(
    children: [
      if (kDebugMode) DebugPanel(),  // Only in debug
      MainContent(),
    ],
  );
}
```

**Bad:**
```dart
// Debug code in release
void fetchData() {
  print('Fetching data...');  // Shows in release!
  print('API Key: $apiKey');   // Exposes secrets!
}

// Debug features always visible
Widget build(BuildContext context) {
  return Column(
    children: [
      DebugPanel(),  // Visible in production!
      MainContent(),
    ],
  );
}
```

### Why?
- No debug info in production
- Cleaner release builds
- Protects sensitive data

---

## Security Checklist

| Area | Check |
|------|-------|
| Storage | Using `flutter_secure_storage` for secrets |
| API Keys | Build-time injection, not hardcoded |
| Network | HTTPS only, certificate pinning |
| Input | All user input validated |
| Obfuscation | Release builds obfuscated |
| Biometrics | Using `local_auth` properly |
| Encryption | AES for sensitive data |
| Root/Jailbreak | Device security checks |
| WebView | Domain whitelisting, HTTPS only |
| Logging | No sensitive data in logs |
| Debug | No debug features in release |
