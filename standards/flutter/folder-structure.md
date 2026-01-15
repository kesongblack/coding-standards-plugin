# Flutter Folder Structure Standards

## Recommended Structure

```
project-root/
├── lib/
│   ├── main.dart                 # Entry point
│   ├── app.dart                  # App widget (MaterialApp/CupertinoApp)
│   ├── core/                     # Core utilities and constants
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_strings.dart
│   │   │   └── app_dimensions.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   └── text_styles.dart
│   │   ├── utils/
│   │   │   ├── validators.dart
│   │   │   └── formatters.dart
│   │   └── extensions/
│   │       ├── string_extensions.dart
│   │       └── context_extensions.dart
│   ├── config/                   # App configuration
│   │   ├── routes.dart
│   │   └── environment.dart
│   ├── models/                   # Data models
│   │   ├── user.dart
│   │   ├── post.dart
│   │   └── api_response.dart
│   ├── services/                 # API and business services
│   │   ├── api/
│   │   │   ├── api_client.dart
│   │   │   └── endpoints.dart
│   │   ├── auth_service.dart
│   │   └── storage_service.dart
│   ├── repositories/             # Data repositories
│   │   ├── user_repository.dart
│   │   └── post_repository.dart
│   ├── providers/                # State management (Provider/Riverpod)
│   │   ├── auth_provider.dart
│   │   └── user_provider.dart
│   ├── screens/                  # Full-page screens
│   │   ├── home/
│   │   │   ├── home_screen.dart
│   │   │   └── widgets/
│   │   │       └── home_header.dart
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   └── profile/
│   │       └── profile_screen.dart
│   └── widgets/                  # Reusable widgets
│       ├── common/
│       │   ├── custom_button.dart
│       │   ├── loading_indicator.dart
│       │   └── error_view.dart
│       └── forms/
│           ├── custom_text_field.dart
│           └── form_validators.dart
├── test/                         # Tests
│   ├── unit/
│   │   ├── models/
│   │   └── services/
│   ├── widget/
│   │   └── screens/
│   └── integration/
├── assets/                       # Static assets
│   ├── images/
│   ├── fonts/
│   └── icons/
├── android/                      # Android platform code
├── ios/                          # iOS platform code
├── pubspec.yaml                  # Dependencies
└── analysis_options.yaml         # Linting rules
```

---

## Core Directories

### `lib/screens/` - Screen Widgets

Full-page screen widgets with optional local widgets.

**Good:**
```
lib/screens/
├── home/
│   ├── home_screen.dart
│   └── widgets/                  # Screen-specific widgets
│       ├── home_header.dart
│       └── home_stats_card.dart
├── auth/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   └── widgets/
│       └── auth_form.dart
└── settings/
    └── settings_screen.dart
```

**Bad:**
```
lib/screens/
├── home_screen.dart              # Flat - acceptable for small apps
├── login_screen.dart
├── HomeScreen.dart               # Wrong: PascalCase file
└── home.dart                     # Wrong: missing _screen suffix
```

### Why?
- Grouped by feature
- Local widgets colocated
- Clear screen identification

---

### `lib/widgets/` - Reusable Widgets

Widgets used across multiple screens.

**Good:**
```
lib/widgets/
├── common/
│   ├── custom_button.dart
│   ├── custom_app_bar.dart
│   └── loading_indicator.dart
├── forms/
│   ├── custom_text_field.dart
│   └── dropdown_field.dart
└── cards/
    ├── info_card.dart
    └── stat_card.dart
```

**Bad:**
```
lib/widgets/
├── button.dart                   # Wrong: too generic
├── MyButton.dart                 # Wrong: PascalCase file
└── widgets.dart                  # Wrong: barrel file with implementations
```

### Why?
- Organized by purpose
- Reusable across screens
- Easy to discover

---

### `lib/models/` - Data Models

Immutable data classes with serialization.

**Good:**
```
lib/models/
├── user.dart
├── post.dart
├── comment.dart
└── responses/
    ├── api_response.dart
    └── paginated_response.dart
```

**Model Example:**
```dart
// lib/models/user.dart
class User {
  final String id;
  final String name;
  final String email;

  const User({
    required this.id,
    required this.name,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }

  User copyWith({String? id, String? name, String? email}) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }
}
```

### Why?
- Type-safe data
- JSON serialization
- Immutability support

---

### `lib/services/` - Business Services

API clients and business logic services.

**Good:**
```
lib/services/
├── api/
│   ├── api_client.dart           # HTTP client wrapper
│   ├── api_exceptions.dart       # Custom exceptions
│   └── endpoints.dart            # API endpoint constants
├── auth_service.dart
├── user_service.dart
└── storage_service.dart
```

**Bad:**
```
lib/services/
├── api.dart                      # Wrong: too generic
├── AuthService.dart              # Wrong: PascalCase file
└── helper.dart                   # Wrong: use utils instead
```

### Why?
- Separated API logic
- Testable in isolation
- Reusable across providers

---

### `lib/repositories/` - Data Repositories

Abstract data access from services (optional layer).

**Good:**
```
lib/repositories/
├── base_repository.dart          # Base class
├── user_repository.dart
└── post_repository.dart
```

**Repository Example:**
```dart
// lib/repositories/user_repository.dart
class UserRepository {
  final ApiClient _apiClient;
  final StorageService _storage;

  UserRepository(this._apiClient, this._storage);

  Future<User> getUser(String id) async {
    // Try cache first
    final cached = await _storage.getUser(id);
    if (cached != null) return cached;

    // Fetch from API
    final user = await _apiClient.get('/users/$id');
    await _storage.saveUser(user);
    return user;
  }
}
```

### When to Use?
- Multiple data sources (API + cache)
- Complex data logic
- Testing flexibility needed

---

### `lib/providers/` - State Management

State management with Provider, Riverpod, or similar.

**Provider Pattern:**
```
lib/providers/
├── auth_provider.dart
├── user_provider.dart
└── theme_provider.dart
```

**Riverpod Pattern:**
```
lib/providers/
├── auth_providers.dart           # Auth-related providers
├── user_providers.dart
└── app_providers.dart            # App-wide providers
```

**BLoC Pattern (Alternative):**
```
lib/blocs/
├── auth/
│   ├── auth_bloc.dart
│   ├── auth_event.dart
│   └── auth_state.dart
└── user/
    ├── user_bloc.dart
    ├── user_event.dart
    └── user_state.dart
```

### Why?
- Centralized state
- Testable
- Scales with app complexity

---

### `lib/core/` - Core Utilities

App-wide constants, themes, and utilities.

**Good:**
```
lib/core/
├── constants/
│   ├── app_colors.dart
│   ├── app_strings.dart
│   ├── app_dimensions.dart
│   └── api_constants.dart
├── theme/
│   ├── app_theme.dart
│   ├── light_theme.dart
│   └── dark_theme.dart
├── utils/
│   ├── validators.dart
│   ├── date_formatter.dart
│   └── logger.dart
└── extensions/
    ├── string_extensions.dart
    ├── context_extensions.dart
    └── datetime_extensions.dart
```

**Bad:**
```
lib/
├── constants.dart                # Wrong: single file - split it
├── utils.dart                    # Wrong: too generic
└── helpers/                      # Wrong: use core/utils
```

### Why?
- Organized constants
- Reusable utilities
- Type-safe extensions

---

### `test/` - Test Organization

Mirror lib structure in tests.

**Good:**
```
test/
├── unit/
│   ├── models/
│   │   └── user_test.dart
│   ├── services/
│   │   └── auth_service_test.dart
│   └── repositories/
│       └── user_repository_test.dart
├── widget/
│   ├── screens/
│   │   └── login_screen_test.dart
│   └── widgets/
│       └── custom_button_test.dart
└── integration/
    └── auth_flow_test.dart
```

**Bad:**
```
test/
├── widget_test.dart              # Default - not useful
└── test.dart                     # Wrong: not descriptive
```

### Why?
- Mirrors lib structure
- Clear test categories
- Easy to find tests

---

## Feature-First Structure (Alternative)

For larger apps, organize by feature:

```
lib/
├── features/
│   ├── auth/
│   │   ├── models/
│   │   │   └── auth_user.dart
│   │   ├── providers/
│   │   │   └── auth_provider.dart
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── services/
│   │   │   └── auth_service.dart
│   │   └── widgets/
│   │       └── auth_form.dart
│   ├── home/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   └── profile/
│       ├── providers/
│       ├── screens/
│       └── widgets/
├── core/
│   ├── constants/
│   ├── theme/
│   └── utils/
└── shared/
    └── widgets/
```

### When to Use?
- Large applications
- Multiple developers
- Clear feature boundaries

---

## Anti-Patterns

### Don't Put Everything in lib Root
```
# Bad
lib/
├── main.dart
├── user.dart                     # Wrong: use models/
├── button.dart                   # Wrong: use widgets/
└── api.dart                      # Wrong: use services/

# Good
lib/
├── main.dart
├── models/
│   └── user.dart
├── widgets/
│   └── button.dart
└── services/
    └── api_client.dart
```

### Don't Mix Naming Conventions
```
# Bad
lib/screens/
├── HomeScreen.dart               # PascalCase file
├── login_screen.dart             # snake_case file
└── settings-screen.dart          # kebab-case file

# Good - consistent snake_case
lib/screens/
├── home_screen.dart
├── login_screen.dart
└── settings_screen.dart
```

### Don't Create God Widgets
```dart
// Bad - widget does too much
class HomeScreen extends StatefulWidget {
  // 500+ lines handling API calls, state, UI, navigation
}

// Good - split responsibilities
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeData = ref.watch(homeProvider);
    return HomeView(data: homeData);
  }
}
```

---

## Assets Organization

**Good:**
```
assets/
├── images/
│   ├── logo.png
│   ├── logo@2x.png               # Resolution variants
│   └── logo@3x.png
├── icons/
│   ├── home.svg
│   └── settings.svg
├── fonts/
│   ├── Roboto-Regular.ttf
│   └── Roboto-Bold.ttf
└── animations/                   # Lottie files
    └── loading.json
```

**pubspec.yaml:**
```yaml
flutter:
  assets:
    - assets/images/
    - assets/icons/
    - assets/animations/
  fonts:
    - family: Roboto
      fonts:
        - asset: assets/fonts/Roboto-Regular.ttf
        - asset: assets/fonts/Roboto-Bold.ttf
          weight: 700
```

---

## Common Variations

| Standard | Variation | When to Use |
|----------|-----------|-------------|
| `screens/` | `pages/` | Personal preference |
| `providers/` | `blocs/` | Using BLoC pattern |
| `providers/` | `controllers/` | Using GetX |
| Layer-first | Feature-first | Large apps with clear domains |
| `core/` | `shared/` | Personal preference |
