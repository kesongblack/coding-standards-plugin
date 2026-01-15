# Laravel Folder Structure Standards

## Recommended Structure

```
project-root/
├── app/
│   ├── Console/
│   │   └── Commands/             # Artisan commands
│   ├── Events/                   # Event classes
│   ├── Exceptions/               # Exception handlers
│   ├── Http/
│   │   ├── Controllers/          # HTTP controllers
│   │   │   ├── Api/              # API controllers
│   │   │   └── Web/              # Web controllers (optional)
│   │   ├── Middleware/           # HTTP middleware
│   │   └── Requests/             # Form request validation
│   ├── Jobs/                     # Queue jobs
│   ├── Listeners/                # Event listeners
│   ├── Mail/                     # Mailable classes
│   ├── Models/                   # Eloquent models
│   ├── Notifications/            # Notification classes
│   ├── Observers/                # Model observers
│   ├── Policies/                 # Authorization policies
│   ├── Providers/                # Service providers
│   ├── Services/                 # Business logic services
│   └── Repositories/             # Repository classes (optional)
├── bootstrap/
│   └── app.php                   # Application bootstrap
├── config/                       # Configuration files
├── database/
│   ├── factories/                # Model factories
│   ├── migrations/               # Database migrations
│   └── seeders/                  # Database seeders
├── public/
│   └── index.php                 # Entry point
├── resources/
│   ├── css/                      # CSS source files
│   ├── js/                       # JavaScript source files
│   ├── lang/                     # Language files
│   └── views/                    # Blade templates
│       ├── components/           # Blade components
│       ├── layouts/              # Layout templates
│       └── pages/                # Page templates
├── routes/
│   ├── api.php                   # API routes
│   ├── channels.php              # Broadcast channels
│   ├── console.php               # Console routes
│   └── web.php                   # Web routes
├── storage/
│   ├── app/                      # Application storage
│   ├── framework/                # Framework storage
│   └── logs/                     # Log files
├── tests/
│   ├── Feature/                  # Feature tests
│   └── Unit/                     # Unit tests
├── .env                          # Environment config
├── artisan                       # Artisan CLI
└── composer.json                 # Dependencies
```

---

## Core Directories

### `app/Http/Controllers/` - Controllers

Controllers should be thin and organized by domain or API version.

**Good:**
```
app/Http/Controllers/
├── Api/
│   ├── V1/
│   │   ├── UserController.php
│   │   └── PostController.php
│   └── V2/
│       └── UserController.php
├── Auth/
│   ├── LoginController.php
│   └── RegisterController.php
└── Dashboard/
    └── DashboardController.php
```

**Bad:**
```
app/Http/Controllers/
├── UserController.php            # Flat - hard to scale
├── PostController.php
├── ApiUserController.php         # Wrong: use subdirectories
└── user_controller.php           # Wrong: snake_case
```

### Why?
- Organized by domain/feature
- API versioning support
- Easy to navigate large codebases

---

### `app/Models/` - Eloquent Models

Models should be in the Models directory (Laravel 8+ convention).

**Good:**
```
app/Models/
├── User.php
├── Post.php
├── Comment.php
└── Concerns/                     # Model traits
    ├── HasSlug.php
    └── HasUuid.php
```

**Bad:**
```
app/
├── User.php                      # Wrong: Laravel 7 style
├── Post.php
└── Models/                       # Mixed locations
    └── Comment.php
```

### Why?
- Laravel 8+ convention
- Clean app directory
- Consistent location

---

### `app/Services/` - Service Classes

Business logic should live in service classes, not controllers.

**Good:**
```
app/Services/
├── UserService.php
├── OrderService.php
├── PaymentService.php
└── External/                     # Third-party integrations
    ├── StripeService.php
    └── MailchimpService.php
```

**Bad:**
```
app/
├── UserService.php               # Wrong: use Services directory
├── Helpers/
│   └── OrderHelper.php           # Wrong: use Services
```

### Why?
- Separation of concerns
- Reusable business logic
- Testable in isolation

---

### `app/Repositories/` - Repository Pattern (Optional)

Use repositories for complex data access logic.

**Good:**
```
app/Repositories/
├── Contracts/                    # Interfaces
│   ├── UserRepositoryInterface.php
│   └── PostRepositoryInterface.php
├── UserRepository.php
└── PostRepository.php
```

**When to Use:**
- Complex query logic
- Multiple data sources
- Need for testing flexibility

**When NOT to Use:**
- Simple CRUD operations
- Small applications
- Direct Eloquent is sufficient

---

### `app/Http/Requests/` - Form Requests

Validation logic should be in Form Request classes.

**Good:**
```
app/Http/Requests/
├── User/
│   ├── StoreUserRequest.php
│   └── UpdateUserRequest.php
├── Post/
│   ├── StorePostRequest.php
│   └── UpdatePostRequest.php
└── Auth/
    ├── LoginRequest.php
    └── RegisterRequest.php
```

**Bad:**
```
app/Http/Requests/
├── StoreUserRequest.php          # Flat - acceptable for small apps
├── UpdateUserRequest.php
├── UserRequest.php               # Wrong: too generic
```

### Why?
- Organized by domain
- Reusable validation
- Clean controllers

---

### `app/Events/` and `app/Listeners/` - Event System

Events and listeners should follow a clear naming pattern.

**Good:**
```
app/Events/
├── User/
│   ├── UserCreated.php
│   └── UserDeleted.php
└── Order/
    ├── OrderPlaced.php
    └── OrderShipped.php

app/Listeners/
├── User/
│   ├── SendWelcomeEmail.php
│   └── NotifyAdmins.php
└── Order/
    ├── ProcessPayment.php
    └── UpdateInventory.php
```

**Bad:**
```
app/Events/
├── UserCreatedEvent.php          # Wrong: redundant 'Event' suffix
└── UserEvent.php                 # Wrong: too generic

app/Listeners/
└── UserListener.php              # Wrong: not descriptive
```

### Why?
- Clear event/listener pairing
- Domain organization
- Descriptive names

---

### `app/Jobs/` - Queue Jobs

Jobs should be named as actions.

**Good:**
```
app/Jobs/
├── ProcessVideoUpload.php
├── SendNewsletterEmail.php
├── GenerateReport.php
└── Imports/
    ├── ImportUsers.php
    └── ImportProducts.php
```

**Bad:**
```
app/Jobs/
├── VideoJob.php                  # Wrong: not descriptive
├── EmailJob.php                  # Wrong: too generic
└── UserImportJob.php             # Wrong: redundant 'Job' suffix
```

### Why?
- Action-oriented naming
- Clear job purpose
- Grouped by feature

---

### `resources/views/` - Blade Templates

Views organized by feature with layouts and components separated.

**Good:**
```
resources/views/
├── layouts/
│   ├── app.blade.php
│   └── guest.blade.php
├── components/
│   ├── button.blade.php
│   ├── alert.blade.php
│   └── forms/
│       ├── input.blade.php
│       └── select.blade.php
├── auth/
│   ├── login.blade.php
│   └── register.blade.php
├── dashboard/
│   ├── index.blade.php
│   └── settings.blade.php
└── users/
    ├── index.blade.php
    ├── show.blade.php
    └── partials/
        └── _user-card.blade.php
```

**Bad:**
```
resources/views/
├── app.blade.php                 # Flat - hard to navigate
├── login.blade.php
├── dashboard.blade.php
└── user-list.blade.php
```

### Why?
- Feature-based organization
- Reusable components
- Clear hierarchy

---

### `routes/` - Route Files

Keep routes organized and avoid bloated route files.

**Good:**
```
routes/
├── api.php                       # API routes (or split below)
├── api/
│   ├── v1.php                    # API v1 routes
│   └── v2.php                    # API v2 routes
├── web.php                       # Web routes
└── admin.php                     # Admin routes (loaded in provider)
```

**In RouteServiceProvider:**
```php
Route::prefix('admin')
    ->middleware('web', 'auth', 'admin')
    ->group(base_path('routes/admin.php'));
```

### Why?
- Manageable route files
- Version separation
- Clear responsibility

---

### `tests/` - Test Organization

Mirror app structure in tests.

**Good:**
```
tests/
├── Feature/
│   ├── Api/
│   │   └── UserControllerTest.php
│   ├── Auth/
│   │   └── LoginTest.php
│   └── Dashboard/
│       └── DashboardTest.php
└── Unit/
    ├── Models/
    │   └── UserTest.php
    └── Services/
        └── OrderServiceTest.php
```

**Bad:**
```
tests/
├── Feature/
│   ├── UserTest.php              # Flat - hard to navigate
│   └── OrderTest.php
└── Unit/
    └── ExampleTest.php           # Default - not useful
```

### Why?
- Mirrors app structure
- Easy to find tests
- Clear test scope

---

## Anti-Patterns

### Don't Put Business Logic in Controllers
```php
// Bad - fat controller
class OrderController extends Controller
{
    public function store(Request $request)
    {
        // 100 lines of business logic...
    }
}

// Good - thin controller
class OrderController extends Controller
{
    public function store(StoreOrderRequest $request, OrderService $service)
    {
        $order = $service->createOrder($request->validated());
        return redirect()->route('orders.show', $order);
    }
}
```

### Don't Create "Helper" Classes
```
# Bad
app/Helpers/
├── StringHelper.php
└── ArrayHelper.php

# Good - use services or utility classes
app/Services/
└── TextFormatterService.php
```

### Don't Mix API and Web Controllers
```
# Bad
app/Http/Controllers/
├── UserController.php            # Which one? Web or API?
└── ApiUserController.php

# Good
app/Http/Controllers/
├── Api/
│   └── UserController.php
└── Web/
    └── UserController.php
```

---

## Domain-Driven Structure (Large Apps)

For large applications, consider domain-driven organization:

```
app/
├── Domain/
│   ├── User/
│   │   ├── Actions/
│   │   │   └── CreateUserAction.php
│   │   ├── Models/
│   │   │   └── User.php
│   │   ├── Events/
│   │   │   └── UserCreated.php
│   │   └── Policies/
│   │       └── UserPolicy.php
│   └── Order/
│       ├── Actions/
│       ├── Models/
│       └── Events/
├── Http/
│   └── Controllers/
└── Support/
    └── helpers.php
```

### Why?
- Domain isolation
- Clear boundaries
- Scales well

---

## Laravel Modules (Optional)

For very large apps, consider `nwidart/laravel-modules`:

```
Modules/
├── User/
│   ├── Config/
│   ├── Database/
│   ├── Http/
│   ├── Models/
│   ├── Providers/
│   └── Routes/
└── Order/
    ├── Config/
    ├── Database/
    ├── Http/
    ├── Models/
    ├── Providers/
    └── Routes/
```

### When to Use?
- Very large applications
- Multiple teams
- Module boundaries needed
