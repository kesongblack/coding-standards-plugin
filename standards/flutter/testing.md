# Flutter Testing Standards

## Test Directory Structure

Organize tests by type mirroring the lib structure.

**Good:**
```
test/
├── unit/                         # Unit tests
│   ├── models/
│   │   └── user_test.dart
│   ├── services/
│   │   └── auth_service_test.dart
│   └── utils/
│       └── validators_test.dart
├── widget/                       # Widget tests
│   ├── screens/
│   │   └── login_screen_test.dart
│   └── widgets/
│       └── custom_button_test.dart
├── integration/                  # Integration tests
│   └── auth_flow_test.dart
├── mocks/                        # Shared mocks
│   ├── mock_auth_service.dart
│   └── mock_api_client.dart
├── fixtures/                     # Test data
│   └── user_fixtures.dart
└── test_helpers.dart             # Shared test utilities
```

**Bad:**
```
test/
├── widget_test.dart              # Default - not useful
├── user_test.dart                # Flat - hard to navigate
└── login_test.dart
```

### Why?
- Mirrors lib structure
- Clear test categories
- Easy to find tests

---

## Unit Testing

Test business logic in isolation.

**Good:**
```dart
// test/unit/services/order_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/services/order_service.dart';

void main() {
  group('OrderService', () {
    late OrderService service;

    setUp(() {
      service = OrderService();
    });

    group('calculateTotal', () {
      test('returns sum of item prices', () {
        final items = [
          OrderItem(price: 100, quantity: 2),
          OrderItem(price: 50, quantity: 1),
        ];

        final total = service.calculateTotal(items);

        expect(total, equals(250));
      });

      test('returns 0 for empty list', () {
        final total = service.calculateTotal([]);

        expect(total, equals(0));
      });
    });

    group('applyDiscount', () {
      test('applies percentage discount', () {
        final result = service.applyDiscount(100, 10);

        expect(result, equals(90));
      });

      test('handles 0% discount', () {
        final result = service.applyDiscount(100, 0);

        expect(result, equals(100));
      });
    });
  });
}
```

**Bad:**
```dart
void main() {
  test('order service works', () {
    final service = OrderService();
    expect(service.calculateTotal([]), equals(0));
    expect(service.applyDiscount(100, 10), equals(90));
    // Multiple assertions - hard to identify failures
  });
}
```

### Why?
- Isolated logic testing
- Fast execution
- Clear failure identification

---

## Widget Testing

Test widgets in isolation with testWidgets.

**Good:**
```dart
// test/widget/widgets/custom_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/widgets/custom_button.dart';

void main() {
  group('CustomButton', () {
    testWidgets('renders with correct text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomButton(text: 'Submit'),
          ),
        ),
      );

      expect(find.text('Submit'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Submit',
              onPressed: () => wasPressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      expect(wasPressed, isTrue);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Submit',
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomButton(text: 'Submit'),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });
}
```

**Bad:**
```dart
testWidgets('button works', (tester) async {
  await tester.pumpWidget(CustomButton(text: 'Click'));  // Missing MaterialApp
  // Will throw error
});
```

### Why?
- Tests widget rendering
- Tests user interaction
- Catches UI bugs

---

## Testing with Providers

Test widgets that depend on state management.

**Good (Riverpod):**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/screens/home_screen.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('shows user name when authenticated', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => AuthNotifier()..login(
              User(id: '1', name: 'John Doe'),
            )),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      expect(find.text('Welcome, John Doe'), findsOneWidget);
    });

    testWidgets('shows login button when not authenticated', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: HomeScreen()),
        ),
      );

      expect(find.text('Login'), findsOneWidget);
    });
  });
}
```

**Good (Provider):**
```dart
import 'package:provider/provider.dart';

testWidgets('shows user data', (tester) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthProvider>.value(
      value: MockAuthProvider()..setUser(User(name: 'John')),
      child: const MaterialApp(home: ProfileScreen()),
    ),
  );

  expect(find.text('John'), findsOneWidget);
});
```

### Why?
- Provides required state
- Testable with mocked data
- Isolated from real providers

---

## Mocking with Mockito

Use mockito for mocking dependencies.

**Setup (`pubspec.yaml`):**
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0
  build_runner: ^2.4.0
```

**Good:**
```dart
// test/mocks/mock_api_client.dart
import 'package:mockito/annotations.dart';
import 'package:myapp/services/api_client.dart';

@GenerateMocks([ApiClient])
void main() {}
```

```dart
// Run: flutter pub run build_runner build

// test/unit/services/user_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/services/user_service.dart';
import '../mocks/mock_api_client.mocks.dart';

void main() {
  group('UserService', () {
    late MockApiClient mockApiClient;
    late UserService userService;

    setUp(() {
      mockApiClient = MockApiClient();
      userService = UserService(mockApiClient);
    });

    test('getUser returns user from API', () async {
      when(mockApiClient.get('/users/1')).thenAnswer(
        (_) async => {'id': '1', 'name': 'John'},
      );

      final user = await userService.getUser('1');

      expect(user.name, equals('John'));
      verify(mockApiClient.get('/users/1')).called(1);
    });

    test('getUser throws on API error', () async {
      when(mockApiClient.get('/users/1')).thenThrow(
        Exception('Network error'),
      );

      expect(
        () => userService.getUser('1'),
        throwsException,
      );
    });
  });
}
```

### Why?
- Isolates unit under test
- Predictable responses
- Verifies interactions

---

## Async Testing

Handle async operations properly.

**Good:**
```dart
group('AsyncOperations', () {
  test('completes future successfully', () async {
    final service = DataService();

    final result = await service.fetchData();

    expect(result, isNotEmpty);
  });

  test('handles timeout', () async {
    final service = SlowService();

    expect(
      () => service.fetchData().timeout(Duration(seconds: 1)),
      throwsA(isA<TimeoutException>()),
    );
  });

  testWidgets('shows data after loading', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DataScreen()),
    );

    // Initial loading state
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for async operation and rebuild
    await tester.pumpAndSettle();

    // Data loaded
    expect(find.text('Data loaded'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
});
```

**Key methods:**
- `pump()` - Triggers a frame
- `pumpAndSettle()` - Pumps until no more frames scheduled
- `pump(Duration)` - Advances time by duration

### Why?
- Proper async handling
- Tests loading states
- Handles timeouts

---

## Golden Tests

Visual regression testing with golden files.

**Good:**
```dart
// test/widget/golden/button_golden_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/widgets/custom_button.dart';

void main() {
  group('CustomButton Golden Tests', () {
    testWidgets('primary button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomButton(
                text: 'Primary',
                variant: ButtonVariant.primary,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(CustomButton),
        matchesGoldenFile('goldens/button_primary.png'),
      );
    });

    testWidgets('disabled button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomButton(
                text: 'Disabled',
                onPressed: null,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(CustomButton),
        matchesGoldenFile('goldens/button_disabled.png'),
      );
    });
  });
}
```

**Update goldens:**
```bash
flutter test --update-goldens
```

### Why?
- Catches visual regressions
- Documents expected UI
- Easy to update

---

## Integration Testing

Test complete flows with integration_test.

**Good:**
```dart
// integration_test/auth_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:myapp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow', () {
    testWidgets('user can login and see dashboard', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to login
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(
        find.byKey(Key('email_field')),
        'user@example.com',
      );
      await tester.enterText(
        find.byKey(Key('password_field')),
        'password123',
      );

      // Submit
      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle();

      // Verify dashboard
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Welcome'), findsOneWidget);
    });

    testWidgets('shows error for invalid credentials', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(Key('email_field')),
        'invalid@example.com',
      );
      await tester.enterText(
        find.byKey(Key('password_field')),
        'wrongpassword',
      );

      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle();

      expect(find.text('Invalid credentials'), findsOneWidget);
    });
  });
}
```

**Run integration tests:**
```bash
flutter test integration_test/auth_flow_test.dart
```

### Why?
- Tests real app behavior
- End-to-end validation
- Catches integration bugs

---

## Test Fixtures

Create reusable test data.

**Good:**
```dart
// test/fixtures/user_fixtures.dart
import 'package:myapp/models/user.dart';

class UserFixtures {
  static User get validUser => User(
    id: '1',
    name: 'John Doe',
    email: 'john@example.com',
  );

  static User get adminUser => User(
    id: '2',
    name: 'Admin User',
    email: 'admin@example.com',
    role: UserRole.admin,
  );

  static List<User> get userList => [
    validUser,
    adminUser,
    User(id: '3', name: 'Jane Doe', email: 'jane@example.com'),
  ];

  static Map<String, dynamic> get validUserJson => {
    'id': '1',
    'name': 'John Doe',
    'email': 'john@example.com',
  };
}
```

**Usage:**
```dart
test('processes user correctly', () {
  final user = UserFixtures.validUser;
  final result = service.process(user);
  expect(result.success, isTrue);
});
```

### Why?
- Consistent test data
- Reusable across tests
- Easy to maintain

---

## Test Coverage Targets

| Category | Minimum Coverage |
|----------|-----------------|
| Models | 90% |
| Services | 85% |
| Providers/BLoCs | 85% |
| Widgets | 70% |
| Screens | 60% |
| Critical paths | 100% |

**Run coverage:**
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## Anti-Patterns

### Don't Test Flutter Framework
```dart
// Bad - testing Flutter's Text widget
testWidgets('Text displays string', (tester) async {
  await tester.pumpWidget(Text('Hello'));
  expect(find.text('Hello'), findsOneWidget);
});

// Good - test YOUR widget behavior
testWidgets('UserCard displays user name', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: UserCard(user: UserFixtures.validUser)),
  );
  expect(find.text('John Doe'), findsOneWidget);
});
```

### Don't Forget MaterialApp Wrapper
```dart
// Bad - missing MaterialApp
testWidgets('button works', (tester) async {
  await tester.pumpWidget(MyButton());  // Will throw
});

// Good
testWidgets('button works', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: MyButton())),
  );
});
```

### Don't Use Real HTTP in Tests
```dart
// Bad - makes real network calls
test('fetches data', () async {
  final service = ApiService();  // Real HTTP client
  final result = await service.fetchUsers();
});

// Good - mock the client
test('fetches data', () async {
  final mockClient = MockHttpClient();
  when(mockClient.get(any)).thenAnswer((_) async => Response('[]', 200));

  final service = ApiService(mockClient);
  final result = await service.fetchUsers();
});
```
