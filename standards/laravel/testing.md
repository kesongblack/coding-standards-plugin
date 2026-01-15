# Laravel Testing Standards

## Test Directory Structure

Organize tests by type with clear separation.

**Good:**
```
tests/
├── Feature/                      # Integration/HTTP tests
│   ├── Api/
│   │   ├── UserControllerTest.php
│   │   └── PostControllerTest.php
│   ├── Auth/
│   │   ├── LoginTest.php
│   │   └── RegistrationTest.php
│   └── Dashboard/
│       └── DashboardTest.php
├── Unit/                         # Isolated unit tests
│   ├── Models/
│   │   └── UserTest.php
│   ├── Services/
│   │   └── OrderServiceTest.php
│   └── Rules/
│       └── ValidSlugTest.php
└── TestCase.php                  # Base test class
```

**Bad:**
```
tests/
├── UserTest.php                  # Flat structure
├── PostTest.php
└── TestCase.php
```

### Why?
- Mirrors app structure
- Clear test type separation
- Easy to find related tests

---

## Test Naming Conventions

Test classes and methods should be descriptive.

**Good:**
```php
class UserControllerTest extends TestCase
{
    public function test_user_can_view_their_profile(): void
    {
        // ...
    }

    public function test_guest_cannot_access_dashboard(): void
    {
        // ...
    }

    public function test_admin_can_delete_users(): void
    {
        // ...
    }
}
```

**Bad:**
```php
class UserTest extends TestCase
{
    public function testProfile(): void           // Not descriptive
    {
        // ...
    }

    public function test1(): void                 // Meaningless name
    {
        // ...
    }
}
```

### Why?
- Self-documenting tests
- Clear failure messages
- Readable test output

---

## Feature Tests (HTTP Tests)

Test full request/response cycles.

**Good:**
```php
use Illuminate\Foundation\Testing\RefreshDatabase;

class UserControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_view_their_profile(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)
            ->get(route('profile.show'));

        $response->assertOk()
            ->assertViewIs('profile.show')
            ->assertSee($user->name);
    }

    public function test_user_can_update_their_profile(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)
            ->put(route('profile.update'), [
                'name' => 'Updated Name',
                'email' => 'updated@example.com',
            ]);

        $response->assertRedirect(route('profile.show'));

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'name' => 'Updated Name',
        ]);
    }
}
```

**Bad:**
```php
class UserControllerTest extends TestCase
{
    public function test_profile(): void
    {
        // No user creation
        $response = $this->get('/profile');
        $response->assertOk();  // Will fail - no auth
    }
}
```

### Why?
- Tests real application flow
- Catches integration issues
- Validates routing and middleware

---

## Unit Tests

Test isolated units without external dependencies.

**Good:**
```php
class OrderServiceTest extends TestCase
{
    public function test_calculates_order_total_correctly(): void
    {
        $service = new OrderService();

        $items = [
            ['price' => 100, 'quantity' => 2],
            ['price' => 50, 'quantity' => 1],
        ];

        $total = $service->calculateTotal($items);

        $this->assertEquals(250, $total);
    }

    public function test_applies_discount_percentage(): void
    {
        $service = new OrderService();

        $total = $service->applyDiscount(100, 10);

        $this->assertEquals(90, $total);
    }
}
```

**Bad:**
```php
class OrderServiceTest extends TestCase
{
    use RefreshDatabase;  // Not needed for unit tests

    public function test_order(): void
    {
        $user = User::factory()->create();  // Unnecessary
        $order = Order::factory()->create(); // This is integration, not unit
        // ...
    }
}
```

### Why?
- Fast execution
- Isolated failures
- Easy to debug

---

## Model Factories

Use factories for test data generation.

**Good:**
```php
// database/factories/UserFactory.php
class UserFactory extends Factory
{
    public function definition(): array
    {
        return [
            'name' => fake()->name(),
            'email' => fake()->unique()->safeEmail(),
            'email_verified_at' => now(),
            'password' => bcrypt('password'),
            'remember_token' => Str::random(10),
        ];
    }

    public function unverified(): static
    {
        return $this->state(fn (array $attributes) => [
            'email_verified_at' => null,
        ]);
    }

    public function admin(): static
    {
        return $this->state(fn (array $attributes) => [
            'role' => 'admin',
        ]);
    }
}

// In tests
$user = User::factory()->create();
$admin = User::factory()->admin()->create();
$users = User::factory()->count(10)->create();
```

**Bad:**
```php
// In tests - manual creation
$user = new User();
$user->name = 'Test User';
$user->email = 'test@example.com';
$user->password = bcrypt('password');
$user->save();
```

### Why?
- Consistent test data
- Reusable states
- Less boilerplate

---

## Database Testing

Use appropriate database traits.

**Good:**
```php
use Illuminate\Foundation\Testing\RefreshDatabase;

class UserControllerTest extends TestCase
{
    use RefreshDatabase;  // Resets database after each test

    public function test_user_can_be_created(): void
    {
        $response = $this->post(route('users.store'), [
            'name' => 'John Doe',
            'email' => 'john@example.com',
        ]);

        $this->assertDatabaseHas('users', [
            'email' => 'john@example.com',
        ]);
    }
}
```

**For faster tests (when safe):**
```php
use Illuminate\Foundation\Testing\DatabaseTransactions;

class ReadOnlyTest extends TestCase
{
    use DatabaseTransactions;  // Wraps in transaction, rolls back
}
```

**Bad:**
```php
class UserControllerTest extends TestCase
{
    // No database trait - tests affect each other!

    public function test_user_creation(): void
    {
        User::create(['email' => 'test@example.com']);
        // This user persists to next test
    }
}
```

### Why?
- Isolated test runs
- Predictable state
- No test pollution

---

## Mocking Dependencies

Use mocks for external services.

**Good:**
```php
use Mockery\MockInterface;

class PaymentServiceTest extends TestCase
{
    public function test_processes_payment_successfully(): void
    {
        $this->mock(StripeGateway::class, function (MockInterface $mock) {
            $mock->shouldReceive('charge')
                ->once()
                ->with(1000, 'tok_visa')
                ->andReturn(['status' => 'succeeded']);
        });

        $service = app(PaymentService::class);
        $result = $service->process(1000, 'tok_visa');

        $this->assertEquals('succeeded', $result['status']);
    }
}
```

**Mocking Facades:**
```php
use Illuminate\Support\Facades\Mail;
use App\Mail\WelcomeEmail;

class RegistrationTest extends TestCase
{
    public function test_sends_welcome_email_on_registration(): void
    {
        Mail::fake();

        $this->post(route('register'), [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'password',
            'password_confirmation' => 'password',
        ]);

        Mail::assertSent(WelcomeEmail::class, function ($mail) {
            return $mail->hasTo('john@example.com');
        });
    }
}
```

### Why?
- Isolates system under test
- Fast execution
- No external dependencies

---

## HTTP Response Assertions

Use appropriate assertions for responses.

**Good:**
```php
public function test_api_returns_user_data(): void
{
    $user = User::factory()->create(['name' => 'John']);

    $response = $this->actingAs($user)
        ->getJson(route('api.user.show', $user));

    $response
        ->assertOk()
        ->assertJson([
            'data' => [
                'id' => $user->id,
                'name' => 'John',
            ]
        ])
        ->assertJsonStructure([
            'data' => ['id', 'name', 'email', 'created_at']
        ]);
}

public function test_validation_errors_returned(): void
{
    $response = $this->postJson(route('api.users.store'), []);

    $response
        ->assertUnprocessable()
        ->assertJsonValidationErrors(['name', 'email']);
}
```

**Bad:**
```php
public function test_api_works(): void
{
    $response = $this->get('/api/users');
    $this->assertTrue($response->status() === 200);  // Use assertOk()
}
```

### Why?
- Clear assertions
- Better error messages
- Framework integration

---

## Testing Jobs and Queues

Test queued jobs properly.

**Good:**
```php
use Illuminate\Support\Facades\Queue;

class OrderControllerTest extends TestCase
{
    public function test_order_dispatches_processing_job(): void
    {
        Queue::fake();

        $order = Order::factory()->create();

        $this->post(route('orders.process', $order));

        Queue::assertPushed(ProcessOrder::class, function ($job) use ($order) {
            return $job->order->id === $order->id;
        });
    }
}
```

**Testing job execution:**
```php
class ProcessOrderTest extends TestCase
{
    use RefreshDatabase;

    public function test_job_updates_order_status(): void
    {
        $order = Order::factory()->create(['status' => 'pending']);

        $job = new ProcessOrder($order);
        $job->handle();

        $this->assertEquals('processed', $order->fresh()->status);
    }
}
```

### Why?
- Verifies dispatch logic
- Tests job behavior
- Isolates queue from HTTP

---

## Testing Events

Verify events are dispatched correctly.

**Good:**
```php
use Illuminate\Support\Facades\Event;

class UserServiceTest extends TestCase
{
    public function test_user_created_event_dispatched(): void
    {
        Event::fake();

        $service = app(UserService::class);
        $user = $service->createUser([
            'name' => 'John',
            'email' => 'john@example.com',
        ]);

        Event::assertDispatched(UserCreated::class, function ($event) use ($user) {
            return $event->user->id === $user->id;
        });
    }
}
```

### Why?
- Verifies event dispatch
- Tests event payload
- Decoupled from listeners

---

## Test Data Providers

Use data providers for multiple test cases.

**Good:**
```php
class ValidationTest extends TestCase
{
    /**
     * @dataProvider invalidEmailProvider
     */
    public function test_rejects_invalid_emails(string $email): void
    {
        $response = $this->postJson(route('users.store'), [
            'name' => 'John',
            'email' => $email,
        ]);

        $response->assertJsonValidationErrors(['email']);
    }

    public static function invalidEmailProvider(): array
    {
        return [
            'missing @' => ['invalid-email'],
            'missing domain' => ['test@'],
            'spaces' => ['test @example.com'],
            'special chars' => ['test<>@example.com'],
        ];
    }
}
```

### Why?
- DRY test code
- Clear test cases
- Easy to add scenarios

---

## Test Coverage Targets

| Category | Minimum Coverage |
|----------|-----------------|
| Models | 80% |
| Services | 90% |
| Controllers (Feature) | 70% |
| Critical paths | 100% |

---

## Anti-Patterns

### Don't Test Framework Code
```php
// Bad - testing Laravel's validation
public function test_required_validation_works(): void
{
    $validator = Validator::make([], ['name' => 'required']);
    $this->assertTrue($validator->fails());
}

// Good - test YOUR validation rules
public function test_user_creation_requires_name(): void
{
    $response = $this->postJson(route('users.store'), ['email' => 'test@example.com']);
    $response->assertJsonValidationErrors(['name']);
}
```

### Don't Share State Between Tests
```php
// Bad - static state pollution
class UserTest extends TestCase
{
    private static $user;

    public function test_first(): void
    {
        self::$user = User::factory()->create();
    }

    public function test_second(): void
    {
        // Depends on test_first running first!
        $this->assertNotNull(self::$user);
    }
}
```

### Don't Test Private Methods Directly
```php
// Bad - testing implementation details
public function test_private_helper(): void
{
    $reflection = new ReflectionMethod(UserService::class, 'formatName');
    $reflection->setAccessible(true);
    // ...
}

// Good - test through public interface
public function test_user_name_is_formatted(): void
{
    $service = new UserService();
    $user = $service->createUser(['name' => 'john doe']);
    $this->assertEquals('John Doe', $user->name);
}
```
