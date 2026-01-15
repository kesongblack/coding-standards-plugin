# Flutter/Dart Naming Standards

## Classes

Classes must use PascalCase (UpperCamelCase) naming.

**Good:**
```dart
class UserProfile {}
class HomePage {}
class ApiService {}
class DatabaseHelper {}
```

**Bad:**
```dart
class userProfile {}      // camelCase
class user_profile {}     // snake_case
class USERPROFILE {}      // SCREAMING_CASE
```

### Why?
- Dart language convention
- Clear distinction from variables and functions
- Consistent with Flutter framework

---

## Files

File names must use lowercase with underscores (snake_case).

**Good:**
```
user_profile.dart
home_page.dart
api_service.dart
database_helper.dart
```

**Bad:**
```
UserProfile.dart          // PascalCase
userProfile.dart          // camelCase
user-profile.dart         // kebab-case
```

### Why?
- Dart package convention
- Case-sensitive file systems compatibility
- Dart style guide requirement

---

## Widgets

Widget class names should be descriptive and may include suffixes like Widget, Screen, Page, or View.

**Good:**
```dart
class LoginScreen extends StatefulWidget {}
class UserProfilePage extends StatelessWidget {}
class CustomButton extends StatelessWidget {}
class LoadingIndicator extends StatelessWidget {}
```

**Bad:**
```dart
class Login {}            // Not descriptive enough
class UserWidget {}       // Too generic
class MyCustomWidget {}   // Vague 'My' prefix
```

### Why?
- Clear purpose identification
- Distinguishes UI components
- Follows Flutter conventions

---

## Private Members

Private members must start with an underscore.

**Good:**
```dart
class UserService {
  String _apiKey = 'secret';
  int _userId = 0;

  void _privateMethod() {}
}
```

**Bad:**
```dart
class UserService {
  String apiKey = 'secret';     // Should be private
  int privateUserId = 0;        // Use underscore, not 'private' prefix

  void privateMethod() {}       // Should use underscore
}
```

### Why?
- Dart language convention for privacy
- Library-level privacy (not class-level)
- Clear indication of internal implementation

---

## Variables and Properties

Variables and properties use lowerCamelCase.

**Good:**
```dart
String userName = 'John';
int itemCount = 0;
bool isLoading = false;
List<String> productNames = [];
```

**Bad:**
```dart
String UserName = 'John';         // PascalCase
int item_count = 0;               // snake_case
bool IsLoading = false;           // PascalCase
```

### Why?
- Dart language convention
- Distinguishes from classes
- Standard practice in Dart/Flutter

---

## Functions and Methods

Functions and methods use lowerCamelCase.

**Good:**
```dart
void fetchUserData() {}
String getUserName() {}
Future<void> loadProducts() async {}
bool isValidEmail(String email) {}
```

**Bad:**
```dart
void FetchUserData() {}           // PascalCase
String get_user_name() {}         // snake_case
Future<void> LoadProducts() {}    // PascalCase
```

### Why?
- Dart language convention
- Clear distinction from classes
- Consistent with other OOP languages

---

## Constants

Constants use lowerCamelCase (not SCREAMING_CASE in Dart).

**Good:**
```dart
const int maxLoginAttempts = 3;
const String apiBaseUrl = 'https://api.example.com';
const double defaultPadding = 16.0;
```

**Bad:**
```dart
const int MAX_LOGIN_ATTEMPTS = 3;     // SCREAMING_CASE (not Dart style)
const String API_BASE_URL = 'url';    // SCREAMING_CASE
```

### Exception: Enum values use lowerCamelCase
```dart
enum Status {
  pending,
  active,
  completed
}
```

### Why?
- Dart style guide convention
- Differentiates from other languages
- All constants are compile-time constants in Dart

---

## Enums

Enum types use PascalCase, enum values use lowerCamelCase.

**Good:**
```dart
enum UserRole {
  admin,
  user,
  guest
}

enum NetworkStatus {
  connected,
  disconnected,
  connecting
}
```

**Bad:**
```dart
enum userRole {              // Enum type should be PascalCase
  Admin,                     // Values should be lowerCamelCase
  User,
  Guest
}
```

### Why?
- Dart style guide
- Type uses PascalCase like classes
- Values follow constant naming

---

## Type Parameters

Type parameters use single uppercase letters or PascalCase for descriptive names.

**Good:**
```dart
class Box<T> {}
class Pair<K, V> {}
class Repository<TEntity> {}
```

**Bad:**
```dart
class Box<type> {}           // Should be uppercase
class Pair<key, value> {}    // Should be uppercase
```

### Why?
- Generic programming convention
- Clear identification of type parameters
- Dart/Flutter standard

---

## Extensions

Extensions use PascalCase with descriptive names.

**Good:**
```dart
extension StringExtensions on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

extension DateTimeHelpers on DateTime {
  bool isToday() {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
}
```

**Bad:**
```dart
extension stringExtensions on String {}    // camelCase
extension string_ext on String {}          // snake_case
```

### Why?
- Clear identification as extensions
- Follows class naming convention
- Dart convention

---

## Mixins

Mixins use PascalCase, often with a descriptive name or 'Mixin' suffix.

**Good:**
```dart
mixin ValidationMixin {
  bool isValidEmail(String email) {
    return email.contains('@');
  }
}

mixin LoggerMixin {
  void log(String message) {
    print(message);
  }
}
```

**Bad:**
```dart
mixin validationMixin {}     // camelCase
mixin validation_mixin {}    // snake_case
```

### Why?
- Clear identification as mixins
- Follows class naming convention
- Dart standard

---

## Imports

Imports should use lowercase with underscores for package names.

**Good:**
```dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'widgets/custom_button.dart';
```

**Bad:**
```dart
import 'package:flutter/Material.dart';    // Wrong case
import '../models/UserModel.dart';         // PascalCase file
```

### Why?
- Package naming convention
- Consistency across imports
- Dart ecosystem standard

---

## State Classes

State classes for StatefulWidgets should have the same name with 'State' suffix or use underscore prefix.

**Good:**
```dart
class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // State implementation
}
```

**Alternative (without prefix)**:
```dart
class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  // State implementation
}
```

### Why?
- Flutter convention
- Clear association with widget
- Privacy when using underscore

---

## Directories

Directories should use lowercase with underscores (snake_case).

**Good:**
```
lib/
├── features/
│   ├── authentication/
│   ├── user_profile/
│   └── product_catalog/
├── widgets/
├── services/
└── utils/
```

**Bad:**
```
lib/
├── Features/              // PascalCase
├── UserProfile/           // PascalCase
└── product-catalog/       // kebab-case
```

### Why?
- Dart package convention
- File system compatibility
- Consistent with file naming

---

## Test Files

Test files must end with `_test.dart` and mirror source file names.

**Good:**
```
lib/services/user_service.dart
test/services/user_service_test.dart

lib/widgets/custom_button.dart
test/widgets/custom_button_test.dart
```

**Bad:**
```
test/services/user_service.test.dart    // Wrong suffix
test/services/UserServiceTest.dart      // Wrong case
test/test_user_service.dart             // Wrong prefix
```

### Why?
- Dart test package convention
- Easy to locate corresponding tests
- Test runner recognition

---

## Boolean Variables

Boolean variables should use `is`, `has`, `can`, or `should` prefixes.

**Good:**
```dart
bool isLoading = false;
bool hasPermission = true;
bool canEdit = false;
bool shouldRefresh = true;
```

**Bad:**
```dart
bool loading = false;          // Not clear it's boolean
bool permission = true;        // Ambiguous
bool edit = false;             // Not descriptive
```

### Why?
- Clear indication of boolean type
- More readable in conditionals
- Common Dart convention
