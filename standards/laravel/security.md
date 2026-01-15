# Laravel Security Standards

## SQL Injection Prevention

Always use Eloquent or parameterized queries.

**Good:**
```php
// Eloquent (safe by default)
$users = User::where('email', $email)->get();

// Query Builder with bindings
$users = DB::table('users')
    ->where('email', $email)
    ->get();

// Raw with bindings
$users = DB::select(
    'SELECT * FROM users WHERE email = ?',
    [$email]
);

// Named bindings
$users = DB::select(
    'SELECT * FROM users WHERE email = :email',
    ['email' => $email]
);
```

**Bad:**
```php
// Direct string interpolation - SQL INJECTION RISK
$users = DB::select("SELECT * FROM users WHERE email = '$email'");

// Concatenation - SQL INJECTION RISK
$users = DB::select('SELECT * FROM users WHERE email = ' . $email);

// Raw without bindings - SQL INJECTION RISK
$users = User::whereRaw("email = '$email'")->get();
```

### Why?
- Prevents SQL injection attacks
- Parameters are properly escaped
- Eloquent handles escaping automatically

---

## XSS Prevention

Escape all output in Blade templates.

**Good:**
```blade
{{-- Auto-escaped (safe) --}}
<p>{{ $user->name }}</p>
<p>{{ $user->bio }}</p>

{{-- Escaped helper --}}
<p>{!! e($user->name) !!}</p>

{{-- Sanitized HTML (when needed) --}}
<p>{!! clean($user->bio) !!}</p>
```

**Bad:**
```blade
{{-- Unescaped - XSS RISK --}}
<p>{!! $user->name !!}</p>
<p>{!! $userInput !!}</p>

{{-- Never trust user input --}}
<p>{!! request('name') !!}</p>
```

### When to Use `{!! !!}`
Only use unescaped output for:
- Trusted HTML from your system (not user input)
- Sanitized/purified HTML content
- Pre-escaped content

```php
// Sanitize HTML before storage
use HTMLPurifier;

$purifier = new HTMLPurifier();
$cleanHtml = $purifier->purify($userInput);
```

### Why?
- Prevents script injection
- Protects against stored XSS
- Default escaping is safe

---

## CSRF Protection

Always include CSRF tokens for state-changing requests.

**Good:**
```blade
{{-- Forms --}}
<form method="POST" action="/users">
    @csrf
    <input type="text" name="name">
    <button type="submit">Create</button>
</form>

{{-- AJAX requests --}}
<meta name="csrf-token" content="{{ csrf_token() }}">

<script>
$.ajaxSetup({
    headers: {
        'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
    }
});
</script>
```

**Bad:**
```blade
{{-- Missing CSRF token --}}
<form method="POST" action="/users">
    <input type="text" name="name">
    <button type="submit">Create</button>
</form>
```

**Exclude routes when necessary (API):**
```php
// app/Http/Middleware/VerifyCsrfToken.php
protected $except = [
    'api/*',              // API routes use tokens instead
    'webhook/stripe',     // External webhooks
];
```

### Why?
- Prevents cross-site request forgery
- Validates request origin
- Built into Laravel forms

---

## Mass Assignment Protection

Define fillable or guarded attributes on models.

**Good:**
```php
class User extends Model
{
    // Whitelist approach (preferred)
    protected $fillable = [
        'name',
        'email',
        'password',
    ];

    // Sensitive fields NOT in fillable
    // 'is_admin', 'role', 'email_verified_at'
}

// Or blacklist approach
class User extends Model
{
    protected $guarded = [
        'id',
        'is_admin',
        'role',
    ];
}
```

**Bad:**
```php
class User extends Model
{
    // DANGEROUS - allows all fields
    protected $guarded = [];
}

// Or no protection at all
class User extends Model
{
    // No $fillable or $guarded defined
}
```

**Safe usage:**
```php
// With fillable protection
User::create($request->validated());

// Explicit assignment for sensitive fields
$user = User::create($request->validated());
$user->role = 'admin';  // Explicit, not from request
$user->save();
```

### Why?
- Prevents unauthorized field updates
- Protects role escalation
- Validates mass assignment

---

## Authentication Best Practices

Use Laravel's built-in authentication features.

**Good:**
```php
// Use Auth facade
if (Auth::check()) {
    $user = Auth::user();
}

// Use middleware
Route::middleware('auth')->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'index']);
});

// Password hashing (automatic with User model)
$user->password = Hash::make($password);

// Password verification
if (Hash::check($password, $user->password)) {
    // Valid
}

// Rate limiting login attempts
use Illuminate\Support\Facades\RateLimiter;

RateLimiter::for('login', function (Request $request) {
    return Limit::perMinute(5)->by($request->ip());
});
```

**Bad:**
```php
// Plain text password - NEVER DO THIS
$user->password = $password;

// Manual session handling without Laravel
$_SESSION['user_id'] = $user->id;

// No rate limiting on login
```

### Why?
- Secure password handling
- Session management
- Brute force protection

---

## Authorization (Policies & Gates)

Use Laravel's authorization features.

**Good:**
```php
// Define a Policy
class PostPolicy
{
    public function update(User $user, Post $post): bool
    {
        return $user->id === $post->user_id;
    }

    public function delete(User $user, Post $post): bool
    {
        return $user->id === $post->user_id || $user->isAdmin();
    }
}

// Register in AuthServiceProvider
protected $policies = [
    Post::class => PostPolicy::class,
];

// Use in controller
public function update(Request $request, Post $post)
{
    $this->authorize('update', $post);
    // or
    if ($request->user()->cannot('update', $post)) {
        abort(403);
    }
}

// Use in Blade
@can('update', $post)
    <a href="{{ route('posts.edit', $post) }}">Edit</a>
@endcan
```

**Bad:**
```php
// Manual checks scattered everywhere
public function update(Request $request, Post $post)
{
    if ($request->user()->id !== $post->user_id) {
        abort(403);
    }
    // Repeated in every method...
}
```

### Why?
- Centralized authorization logic
- Reusable across controllers/views
- Testable in isolation

---

## Environment Variable Security

Never expose sensitive data.

**Good:**
```php
// .env (not committed)
APP_KEY=base64:...
DB_PASSWORD=secret
API_SECRET=your-secret-key

// config/services.php
return [
    'stripe' => [
        'key' => env('STRIPE_KEY'),
        'secret' => env('STRIPE_SECRET'),
    ],
];

// Access via config
$key = config('services.stripe.key');
```

**Bad:**
```php
// Hardcoded secrets - NEVER
$apiKey = 'sk_live_abc123';

// In version control
// .env committed to git

// Exposed in frontend
<script>
    const apiSecret = "{{ env('API_SECRET') }}";  // EXPOSED!
</script>
```

**.gitignore:**
```gitignore
.env
.env.backup
.env.production
```

### Why?
- Secrets stay secret
- Environment-specific config
- No secrets in code

---

## Input Validation

Validate all user input.

**Good:**
```php
// Form Request validation
class StoreUserRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|min:8|confirmed',
            'age' => 'nullable|integer|min:0|max:150',
            'website' => 'nullable|url',
        ];
    }
}

// Controller
public function store(StoreUserRequest $request)
{
    User::create($request->validated());
}
```

**Bad:**
```php
// No validation
public function store(Request $request)
{
    User::create($request->all());  // Dangerous!
}

// Insufficient validation
public function store(Request $request)
{
    $request->validate([
        'email' => 'required',  // Not validated as email format
    ]);
}
```

### Why?
- Prevents malformed data
- Type safety
- Security layer

---

## File Upload Security

Validate and sanitize file uploads.

**Good:**
```php
class UploadRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'document' => [
                'required',
                'file',
                'mimes:pdf,doc,docx',
                'max:10240',  // 10MB
            ],
            'avatar' => [
                'required',
                'image',
                'mimes:jpeg,png,gif',
                'max:2048',
                'dimensions:min_width=100,min_height=100,max_width=2000,max_height=2000',
            ],
        ];
    }
}

// Store with safe name
$path = $request->file('document')->store('documents');

// Or generate safe name
$filename = Str::uuid() . '.' . $request->file('document')->extension();
$path = $request->file('document')->storeAs('documents', $filename);
```

**Bad:**
```php
// No validation
$request->file('document')->store('documents');

// Using original filename (unsafe)
$filename = $request->file('document')->getClientOriginalName();
$path = $request->file('document')->storeAs('documents', $filename);

// Accepting any file type
'document' => 'required|file',  // No mime validation
```

### Why?
- Prevents malicious uploads
- Controls file types
- Limits file size

---

## Secure Headers

Configure security headers.

**Good:**
```php
// app/Http/Middleware/SecurityHeaders.php
class SecurityHeaders
{
    public function handle($request, Closure $next)
    {
        $response = $next($request);

        $response->headers->set('X-Content-Type-Options', 'nosniff');
        $response->headers->set('X-Frame-Options', 'SAMEORIGIN');
        $response->headers->set('X-XSS-Protection', '1; mode=block');
        $response->headers->set('Referrer-Policy', 'strict-origin-when-cross-origin');

        if (app()->environment('production')) {
            $response->headers->set('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
        }

        return $response;
    }
}

// Register in Kernel.php
protected $middleware = [
    // ...
    \App\Http\Middleware\SecurityHeaders::class,
];
```

### Why?
- Prevents clickjacking
- Enables HTTPS enforcement
- Adds defense layers

---

## Encryption

Encrypt sensitive data at rest.

**Good:**
```php
use Illuminate\Support\Facades\Crypt;

// Encrypt
$encrypted = Crypt::encryptString($sensitiveData);

// Decrypt
$decrypted = Crypt::decryptString($encrypted);

// Model attribute encryption
class User extends Model
{
    protected $casts = [
        'ssn' => 'encrypted',
        'api_token' => 'encrypted',
    ];
}
```

**Bad:**
```php
// Storing sensitive data in plain text
$user->ssn = $request->ssn;  // Unencrypted

// Base64 is NOT encryption
$user->ssn = base64_encode($request->ssn);
```

### Why?
- Protects data at rest
- Uses strong encryption
- Laravel handles keys

---

## Rate Limiting

Protect against abuse.

**Good:**
```php
// routes/api.php
Route::middleware('throttle:api')->group(function () {
    Route::get('/users', [UserController::class, 'index']);
});

// Custom rate limiter
// app/Providers/RouteServiceProvider.php
RateLimiter::for('api', function (Request $request) {
    return Limit::perMinute(60)->by($request->user()?->id ?: $request->ip());
});

RateLimiter::for('uploads', function (Request $request) {
    return Limit::perMinute(10)->by($request->user()->id);
});

// Apply to route
Route::post('/upload', [UploadController::class, 'store'])
    ->middleware('throttle:uploads');
```

### Why?
- Prevents DDoS
- Limits brute force
- Protects resources

---

## Logging Security Events

Log security-relevant events.

**Good:**
```php
use Illuminate\Support\Facades\Log;

// Log failed login attempts
if (!Auth::attempt($credentials)) {
    Log::warning('Failed login attempt', [
        'email' => $request->email,
        'ip' => $request->ip(),
        'user_agent' => $request->userAgent(),
    ]);
}

// Log sensitive actions
Log::info('User role changed', [
    'admin_id' => auth()->id(),
    'target_user_id' => $user->id,
    'old_role' => $oldRole,
    'new_role' => $newRole,
]);
```

**Don't log sensitive data:**
```php
// Bad - logging passwords
Log::info('Login attempt', [
    'password' => $request->password,  // NEVER
]);

// Good - omit sensitive data
Log::info('Login attempt', [
    'email' => $request->email,
    'ip' => $request->ip(),
]);
```

### Why?
- Audit trail
- Incident detection
- Forensic analysis

---

## Security Checklist

| Area | Check |
|------|-------|
| SQL | Using Eloquent or parameterized queries |
| XSS | All output escaped with `{{ }}` |
| CSRF | `@csrf` in all forms |
| Auth | Using `Hash::make()` for passwords |
| Mass Assignment | `$fillable` defined on models |
| Validation | All input validated |
| Files | Upload validation with mime types |
| Env | No secrets in code or version control |
| HTTPS | Forced in production |
| Headers | Security headers configured |
