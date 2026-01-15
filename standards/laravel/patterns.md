# Laravel Design Patterns & Best Practices

## Avoid Fat Controllers

Controllers should be thin, delegating business logic to services.

### Anti-pattern (Fat Controller)
```php
class OrderController extends Controller
{
    public function store(Request $request)
    {
        // Validation
        $validated = $request->validate([
            'product_id' => 'required|exists:products,id',
            'quantity' => 'required|integer|min:1',
        ]);

        // Business logic in controller
        $product = Product::find($validated['product_id']);

        if ($product->stock < $validated['quantity']) {
            return back()->with('error', 'Insufficient stock');
        }

        $order = Order::create([
            'user_id' => auth()->id(),
            'product_id' => $product->id,
            'quantity' => $validated['quantity'],
            'total' => $product->price * $validated['quantity'],
        ]);

        $product->stock -= $validated['quantity'];
        $product->save();

        Mail::to(auth()->user())->send(new OrderConfirmation($order));

        return redirect()->route('orders.show', $order);
    }
}
```

### Better Pattern (Service Layer)
```php
class OrderController extends Controller
{
    public function __construct(
        private OrderService $orderService
    ) {}

    public function store(StoreOrderRequest $request)
    {
        $order = $this->orderService->createOrder(
            auth()->user(),
            $request->validated()
        );

        return redirect()
            ->route('orders.show', $order)
            ->with('success', 'Order created successfully');
    }
}

class OrderService
{
    public function createOrder(User $user, array $data): Order
    {
        $product = Product::findOrFail($data['product_id']);

        if ($product->stock < $data['quantity']) {
            throw new InsufficientStockException();
        }

        DB::transaction(function () use ($user, $product, $data) {
            $order = Order::create([
                'user_id' => $user->id,
                'product_id' => $product->id,
                'quantity' => $data['quantity'],
                'total' => $product->price * $data['quantity'],
            ]);

            $product->decrement('stock', $data['quantity']);

            event(new OrderCreated($order));

            return $order;
        });
    }
}
```

### Why?
- Separation of concerns
- Easier testing
- Reusable business logic
- Cleaner controllers

---

## Use Eloquent Relationships

Leverage Eloquent relationships instead of manual queries.

### Anti-pattern
```php
class User extends Model
{
    public function getPosts()
    {
        return DB::table('posts')
            ->where('user_id', $this->id)
            ->get();
    }
}

// Usage
$posts = $user->getPosts();
```

### Better Pattern
```php
class User extends Model
{
    public function posts()
    {
        return $this->hasMany(Post::class);
    }
}

// Usage
$posts = $user->posts;
$posts = $user->posts()->where('published', true)->get();
```

### Why?
- Lazy loading and eager loading support
- Query builder integration
- Cleaner syntax
- Better performance with eager loading

---

## Repository Pattern

Use repository pattern for complex data access logic.

### Implementation
```php
interface UserRepositoryInterface
{
    public function find(int $id): ?User;
    public function findByEmail(string $email): ?User;
    public function create(array $data): User;
    public function update(User $user, array $data): User;
}

class UserRepository implements UserRepositoryInterface
{
    public function find(int $id): ?User
    {
        return User::find($id);
    }

    public function findByEmail(string $email): ?User
    {
        return User::where('email', $email)->first();
    }

    public function create(array $data): User
    {
        return User::create($data);
    }

    public function update(User $user, array $data): User
    {
        $user->update($data);
        return $user->fresh();
    }
}

// Service Provider
class AppServiceProvider extends ServiceProvider
{
    public function register()
    {
        $this->app->bind(
            UserRepositoryInterface::class,
            UserRepository::class
        );
    }
}

// Usage in Service
class UserService
{
    public function __construct(
        private UserRepositoryInterface $userRepository
    ) {}

    public function registerUser(array $data): User
    {
        return $this->userRepository->create($data);
    }
}
```

### When to Use?
- Complex query logic
- Multiple data sources
- Need for testing flexibility
- Data access abstraction

### When NOT to Use?
- Simple CRUD operations
- Small applications
- Direct Eloquent usage is sufficient

---

## Form Request Validation

Use Form Requests for validation logic instead of controller validation.

### Anti-pattern
```php
class UserController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|min:8|confirmed',
        ]);

        // ... create user
    }
}
```

### Better Pattern
```php
class StoreUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|min:8|confirmed',
        ];
    }

    public function messages(): array
    {
        return [
            'email.unique' => 'This email is already registered.',
            'password.min' => 'Password must be at least 8 characters.',
        ];
    }
}

class UserController extends Controller
{
    public function store(StoreUserRequest $request)
    {
        $user = User::create($request->validated());
        // ...
    }
}
```

### Why?
- Separation of concerns
- Reusable validation rules
- Custom error messages
- Authorization logic in one place

---

## Query Scopes

Use query scopes for reusable query constraints.

### Implementation
```php
class Post extends Model
{
    // Local Scope
    public function scopePublished($query)
    {
        return $query->where('published', true);
    }

    public function scopeRecent($query, $days = 7)
    {
        return $query->where('created_at', '>=', now()->subDays($days));
    }
}

// Usage
$posts = Post::published()->recent()->get();
$posts = Post::published()->recent(30)->get();
```

### Why?
- DRY principle
- Chainable queries
- Readable code
- Centralized query logic

---

## Resource Collections

Use API Resources for consistent API responses.

### Implementation
```php
class UserResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'created_at' => $this->created_at->toISOString(),
            'posts' => PostResource::collection($this->whenLoaded('posts')),
        ];
    }
}

class UserCollection extends ResourceCollection
{
    public function toArray($request): array
    {
        return [
            'data' => $this->collection,
            'meta' => [
                'total' => $this->total(),
                'per_page' => $this->perPage(),
            ],
        ];
    }
}

// Usage
return UserResource::collection($users);
return new UserCollection($users);
```

### Why?
- Consistent API structure
- Transformation layer
- Conditional attributes
- Easy to maintain

---

## Events and Listeners

Use events for loosely coupled application flow.

### Implementation
```php
// Event
class OrderCreated
{
    public function __construct(
        public Order $order
    ) {}
}

// Listeners
class SendOrderConfirmationEmail
{
    public function handle(OrderCreated $event): void
    {
        Mail::to($event->order->user)
            ->send(new OrderConfirmation($event->order));
    }
}

class UpdateInventory
{
    public function handle(OrderCreated $event): void
    {
        foreach ($event->order->items as $item) {
            $item->product->decrement('stock', $item->quantity);
        }
    }
}

class NotifyAdministrator
{
    public function handle(OrderCreated $event): void
    {
        // Send notification to admin
    }
}

// EventServiceProvider
protected $listen = [
    OrderCreated::class => [
        SendOrderConfirmationEmail::class,
        UpdateInventory::class,
        NotifyAdministrator::class,
    ],
];

// Usage
event(new OrderCreated($order));
```

### Why?
- Decoupled components
- Easy to add new listeners
- Single Responsibility Principle
- Testable in isolation

---

## Jobs for Async Processing

Use jobs for time-consuming tasks.

### Implementation
```php
class ProcessVideoUpload implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public Video $video
    ) {}

    public function handle(VideoProcessor $processor): void
    {
        $processor->transcode($this->video);

        $this->video->update(['status' => 'processed']);

        event(new VideoProcessed($this->video));
    }

    public function failed(Throwable $exception): void
    {
        $this->video->update(['status' => 'failed']);
    }
}

// Usage
ProcessVideoUpload::dispatch($video);
```

### Why?
- Non-blocking operations
- Better user experience
- Scalable architecture
- Failure handling

---

## Database Transactions

Use database transactions for data integrity.

### Implementation
```php
use Illuminate\Support\Facades\DB;

public function transferFunds(User $from, User $to, float $amount): void
{
    DB::transaction(function () use ($from, $to, $amount) {
        $from->decrement('balance', $amount);
        $to->increment('balance', $amount);

        Transaction::create([
            'from_user_id' => $from->id,
            'to_user_id' => $to->id,
            'amount' => $amount,
        ]);
    });
}
```

### Why?
- ACID compliance
- Automatic rollback on errors
- Data consistency
- Prevents partial updates

---

## Service Container and Dependency Injection

Use dependency injection for better testability.

### Anti-pattern
```php
class OrderService
{
    public function createOrder(array $data): Order
    {
        $paymentGateway = new StripePaymentGateway();
        $emailService = new EmailService();

        // ... process order
    }
}
```

### Better Pattern
```php
class OrderService
{
    public function __construct(
        private PaymentGatewayInterface $paymentGateway,
        private EmailServiceInterface $emailService
    ) {}

    public function createOrder(array $data): Order
    {
        // ... process order using injected dependencies
    }
}

// Binding in Service Provider
$this->app->bind(PaymentGatewayInterface::class, StripePaymentGateway::class);
```

### Why?
- Testable with mocks
- Flexible implementations
- Follows SOLID principles
- Laravel container manages lifecycle
