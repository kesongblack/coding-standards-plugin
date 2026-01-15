# Laravel Naming Standards

## Controllers

Controllers should use singular PascalCase with `Controller` suffix.

**Good:**
```php
UserController
OrderController
ProductController
```

**Bad:**
```php
UsersController      // Plural
userController       // camelCase
User_Controller      // Snake_case
```

### Why?
- Laravel convention for PSR-4 autoloading
- Singular form represents the resource being controlled
- Consistent with Laravel's documentation and community standards

---

## Models

Models must use singular PascalCase naming without suffixes.

**Good:**
```php
User
Order
Product
BlogPost
```

**Bad:**
```php
Users           // Plural
UserModel       // Unnecessary suffix
user            // lowercase
```

### Why?
- Represents a single instance of the entity
- Eloquent automatically handles plural table names
- PSR-4 autoloading standard

---

## Migrations

Migrations must follow Laravel's timestamp naming convention:
`YYYY_MM_DD_HHMMSS_description_in_snake_case.php`

**Good:**
```
2026_01_14_120000_create_users_table.php
2026_01_14_120100_add_email_to_users_table.php
2026_01_14_120200_create_orders_table.php
```

**Bad:**
```
create_users_table.php           // No timestamp
2026-01-14_create_users.php      // Wrong date format
CreateUsersTable.php             // PascalCase
```

### Why?
- Ensures migrations run in correct order
- Laravel framework requirement
- Clear chronological history

---

## Form Requests

Form request classes must end with `Request` suffix.

**Good:**
```php
StoreUserRequest
UpdateProductRequest
LoginRequest
```

**Bad:**
```php
UserFormRequest      // Redundant 'Form'
StoreUserValidation  // Wrong suffix
UserStore            // No suffix
```

### Why?
- Clear distinction from regular requests
- Consistent with Laravel conventions
- Immediately identifies validation classes

---

## Services

Service classes should use descriptive names with `Service` suffix.

**Good:**
```php
UserService
OrderProcessingService
PaymentService
EmailNotificationService
```

**Bad:**
```php
Users               // No suffix, unclear purpose
UserManager         // Use Service instead of Manager
UserHelper          // Avoid generic 'Helper' suffix
```

### Why?
- Clear indication of business logic layer
- Distinguishes from repositories and controllers
- Follows common Laravel patterns

---

## Repositories

Repository classes should end with `Repository` suffix.

**Good:**
```php
UserRepository
OrderRepository
ProductRepository
```

**Bad:**
```php
UserRepo            // Abbreviated
Users               // No suffix
UserData            // Unclear purpose
```

### Why?
- Clear separation from models and services
- Follows repository pattern conventions
- Indicates data access layer

---

## Jobs

Job classes should use descriptive verb phrases without suffixes.

**Good:**
```php
SendWelcomeEmail
ProcessPayment
GenerateInvoice
```

**Bad:**
```php
SendWelcomeEmailJob     // Redundant Job suffix
WelcomeEmail            // Not descriptive
EmailSender             // Too generic
```

### Why?
- Describes the action being performed
- Laravel convention (no Job suffix needed)
- Clear and concise

---

## Events

Event classes should describe what happened in past tense.

**Good:**
```php
UserRegistered
OrderShipped
PaymentProcessed
```

**Bad:**
```php
UserRegisterEvent       // Redundant Event suffix
RegisterUser            // Present tense
UserRegistration        // Noun form
```

### Why?
- Events represent something that already occurred
- Clear semantic meaning
- Laravel convention

---

## Listeners

Listener classes should describe the action taken.

**Good:**
```php
SendWelcomeEmail
UpdateUserStatistics
NotifyAdministrator
```

**Bad:**
```php
SendWelcomeEmailListener    // Redundant Listener suffix
EmailSender                 // Too generic
WelcomeEmail                // Not descriptive
```

### Why?
- Describes what the listener does
- Laravel convention (no Listener suffix)
- Action-oriented naming

---

## Middleware

Middleware classes should be descriptive nouns or adjectives.

**Good:**
```php
Authenticate
CheckUserRole
EnsureEmailIsVerified
```

**Bad:**
```php
AuthMiddleware          // Redundant Middleware suffix
Auth                    // Too short/vague
UserAuthentication      // Too verbose
```

### Why?
- Describes the check or transformation
- Laravel convention (no Middleware suffix)
- Clear purpose

---

## Variables and Methods

### Variables
Use camelCase for variables and properties.

**Good:**
```php
$userName
$orderTotal
$isActive
```

**Bad:**
```php
$user_name      // Snake_case (use only for database columns)
$UserName       // PascalCase
$uname          // Abbreviated
```

### Methods
Use camelCase for method names, starting with a verb.

**Good:**
```php
public function getUserById($id)
public function createOrder()
public function isActive()
```

**Bad:**
```php
public function get_user()          // Snake_case
public function User()              // No verb, PascalCase
public function getUserByIdMethod() // Redundant 'Method'
```

### Why?
- PSR-12 coding standard
- Laravel framework conventions
- Consistent with PHP community standards
