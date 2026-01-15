# Flutter Design Patterns & Best Practices

## Prefer StatelessWidget Over StatefulWidget

Use StatelessWidget when state management is not needed within the widget.

### StatelessWidget (Preferred)
```dart
class WelcomeMessage extends StatelessWidget {
  final String userName;

  const WelcomeMessage({
    Key? key,
    required this.userName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text('Welcome, $userName!');
  }
}
```

### StatefulWidget (When State is Needed)
```dart
class Counter extends StatefulWidget {
  const Counter({Key? key}) : super(key: key);

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int _count = 0;

  void _increment() {
    setState(() {
      _count++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Count: $_count'),
        ElevatedButton(
          onPressed: _increment,
          child: Text('Increment'),
        ),
      ],
    );
  }
}
```

### Why?
- Better performance
- Less memory overhead
- Simpler to reason about
- Easier to test

---

## Use Const Constructors

Use `const` constructors whenever possible for better performance.

### Without Const (Slower)
```dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Hello World'),
      ),
    );
  }
}
```

### With Const (Faster)
```dart
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: const Text('Hello World'),
      ),
    );
  }
}
```

### Why?
- Compile-time optimization
- Reduced rebuild cost
- Better memory usage
- Flutter recommends it

---

## State Management Patterns

Use appropriate state management solutions for different scales.

### Provider (Simple to Medium Apps)
```dart
// Model
class CounterModel extends ChangeNotifier {
  int _count = 0;

  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }
}

// Provider Setup
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => CounterModel(),
      child: MyApp(),
    ),
  );
}

// Widget Usage
class CounterDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final counter = context.watch<CounterModel>();
    return Text('${counter.count}');
  }
}
```

### Riverpod (Recommended for New Projects)
```dart
// Provider
final counterProvider = StateNotifierProvider<CounterNotifier, int>((ref) {
  return CounterNotifier();
});

class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);

  void increment() => state++;
}

// Widget Usage
class CounterDisplay extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Text('$count');
  }
}
```

### BLoC (Complex Apps)
```dart
// Events
abstract class CounterEvent {}
class IncrementEvent extends CounterEvent {}

// States
class CounterState {
  final int count;
  const CounterState(this.count);
}

// BLoC
class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(CounterState(0)) {
    on<IncrementEvent>((event, emit) {
      emit(CounterState(state.count + 1));
    });
  }
}

// Widget Usage
class CounterDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CounterBloc, CounterState>(
      builder: (context, state) {
        return Text('${state.count}');
      },
    );
  }
}
```

### Why?
- Separation of business logic from UI
- Testable code
- Scalable architecture
- Reactive updates

---

## Separation of Concerns

Separate business logic from UI code using services and repositories.

### Anti-pattern (Logic in Widget)
```dart
class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  User? user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final response = await http.get(Uri.parse('https://api.example.com/user'));
    final data = json.decode(response.body);
    setState(() {
      user = User.fromJson(data);
    });
  }

  @override
  Widget build(BuildContext context) {
    return user != null ? Text(user!.name) : CircularProgressIndicator();
  }
}
```

### Better Pattern (Service Layer)
```dart
// Service
class UserService {
  final http.Client client;

  UserService(this.client);

  Future<User> getUser(String id) async {
    final response = await client.get(
      Uri.parse('https://api.example.com/user/$id'),
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load user');
    }
  }
}

// Repository (Optional additional layer)
class UserRepository {
  final UserService _service;

  UserRepository(this._service);

  Future<User> getUserById(String id) async {
    return await _service.getUser(id);
  }
}

// Widget with Provider
class UserProfilePage extends ConsumerWidget {
  final String userId;

  const UserProfilePage({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider(userId));

    return userAsync.when(
      data: (user) => Text(user.name),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}

// Provider
final userServiceProvider = Provider((ref) => UserService(http.Client()));

final userProvider = FutureProvider.family<User, String>((ref, id) async {
  final service = ref.watch(userServiceProvider);
  return service.getUser(id);
});
```

### Why?
- Testable in isolation
- Reusable business logic
- Single Responsibility Principle
- Better maintainability

---

## Widget Composition

Break down large widgets into smaller, reusable components.

### Anti-pattern (Large Widget)
```dart
class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(product.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              product.name,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              product.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 20, color: Colors.green),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('Add to Cart'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### Better Pattern (Composed Widgets)
```dart
class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ProductImage(imageUrl: product.imageUrl),
            const SizedBox(height: 8),
            ProductTitle(name: product.name),
            const SizedBox(height: 4),
            ProductDescription(description: product.description),
            const SizedBox(height: 8),
            ProductFooter(product: product),
          ],
        ),
      ),
    );
  }
}

class ProductImage extends StatelessWidget {
  final String imageUrl;

  const ProductImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class ProductTitle extends StatelessWidget {
  final String name;

  const ProductTitle({Key? key, required this.name}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

// ... other small widgets
```

### Why?
- Easier to maintain
- Reusable components
- Better readability
- Testable in isolation

---

## Use Named Parameters

Use named parameters for better clarity and safety.

### Positional (Harder to Read)
```dart
class UserCard extends StatelessWidget {
  final String name;
  final String email;
  final String avatarUrl;
  final bool isVerified;

  const UserCard(this.name, this.email, this.avatarUrl, this.isVerified);
}

// Usage - hard to understand
UserCard('John', 'john@example.com', 'https://...', true);
```

### Named (Clear and Safe)
```dart
class UserCard extends StatelessWidget {
  final String name;
  final String email;
  final String avatarUrl;
  final bool isVerified;

  const UserCard({
    Key? key,
    required this.name,
    required this.email,
    required this.avatarUrl,
    this.isVerified = false,
  }) : super(key: key);
}

// Usage - clear and readable
UserCard(
  name: 'John',
  email: 'john@example.com',
  avatarUrl: 'https://...',
  isVerified: true,
);
```

### Why?
- Self-documenting code
- Named parameters are safer
- Default values supported
- Flutter convention

---

## Error Handling

Implement proper error handling throughout your app.

### Implementation
```dart
// Custom Exceptions
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}

class ValidationException implements Exception {
  final Map<String, String> errors;
  ValidationException(this.errors);
}

// Service with Error Handling
class ApiService {
  Future<User> fetchUser(String id) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.example.com/users/$id'),
      );

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw NetworkException('User not found');
      } else {
        throw NetworkException('Failed to fetch user');
      }
    } on SocketException {
      throw NetworkException('No internet connection');
    } on HttpException {
      throw NetworkException('Network error');
    } catch (e) {
      throw NetworkException('Unexpected error: $e');
    }
  }
}

// Widget with Error Handling
class UserProfilePage extends ConsumerWidget {
  final String userId;

  const UserProfilePage({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: userAsync.when(
        data: (user) => UserProfileView(user: user),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          if (error is NetworkException) {
            return ErrorView(
              message: error.message,
              onRetry: () => ref.refresh(userProvider(userId)),
            );
          }
          return ErrorView(
            message: 'An unexpected error occurred',
            onRetry: () => ref.refresh(userProvider(userId)),
          );
        },
      ),
    );
  }
}
```

### Why?
- Better user experience
- Proper error recovery
- Debugging information
- Graceful degradation

---

## Async/Await Best Practices

Handle asynchronous operations properly.

### Implementation
```dart
// Good: Proper error handling
Future<User> loadUser(String id) async {
  try {
    final user = await userService.getUser(id);
    return user;
  } catch (e) {
    print('Error loading user: $e');
    rethrow;
  }
}

// Good: Parallel execution
Future<void> loadUserData(String userId) async {
  final results = await Future.wait([
    userService.getUser(userId),
    userService.getUserPosts(userId),
    userService.getUserFriends(userId),
  ]);

  final user = results[0] as User;
  final posts = results[1] as List<Post>;
  final friends = results[2] as List<User>;
}

// Good: Timeout handling
Future<User> loadUserWithTimeout(String id) async {
  try {
    return await userService
        .getUser(id)
        .timeout(const Duration(seconds: 10));
  } on TimeoutException {
    throw NetworkException('Request timed out');
  }
}

// Bad: Not handling errors
Future<User> loadUser(String id) async {
  return await userService.getUser(id); // No error handling
}

// Bad: Sequential when could be parallel
Future<void> loadUserData(String userId) async {
  final user = await userService.getUser(userId);
  final posts = await userService.getUserPosts(userId);
  final friends = await userService.getUserFriends(userId);
}
```

### Why?
- Prevent unhandled exceptions
- Better performance
- User feedback
- Resource management

---

## Responsive Design

Build apps that work across different screen sizes.

### Implementation
```dart
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return mobile;
        } else if (constraints.maxWidth < 1200) {
          return tablet ?? mobile;
        } else {
          return desktop;
        }
      },
    );
  }
}

// Usage
ResponsiveLayout(
  mobile: MobileLayout(),
  tablet: TabletLayout(),
  desktop: DesktopLayout(),
);
```

### Media Query Usage
```dart
class AdaptiveWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 32),
      child: Text(
        'Adaptive Content',
        style: TextStyle(
          fontSize: isSmallScreen ? 14 : 18,
        ),
      ),
    );
  }
}
```

### Why?
- Works on all devices
- Better user experience
- Professional appearance
- Flexibility

---

## Immutability

Prefer immutable data structures.

### Implementation
```dart
// Immutable Model
class User {
  final String id;
  final String name;
  final String email;

  const User({
    required this.id,
    required this.name,
    required this.email,
  });

  // Copy with method for updates
  User copyWith({
    String? id,
    String? name,
    String? email,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ email.hashCode;
}

// Usage
final user = User(id: '1', name: 'John', email: 'john@example.com');
final updatedUser = user.copyWith(name: 'Jane');
```

### Why?
- Thread-safe
- Predictable behavior
- Easier debugging
- Better performance with const

---

## Null Safety

Leverage Dart's null safety features.

### Implementation
```dart
// Nullable types
String? nullableName;

// Non-nullable types (default)
String name = 'John';

// Null-aware operators
String displayName = nullableName ?? 'Guest';
int? length = nullableName?.length;

// Late variables (for lazy initialization)
late final String userId;

void initialize(String id) {
  userId = id; // Must be assigned before use
}

// Required parameters
class User {
  final String name;
  final String? nickname; // Optional

  User({
    required this.name,
    this.nickname,
  });
}
```

### Why?
- Catch null errors at compile-time
- Safer code
- Better IDE support
- Dart 3+ requirement
