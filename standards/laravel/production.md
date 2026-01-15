# Laravel Production Safety Standards

## Overview

These rules ensure your Laravel application is properly configured for production deployment.

---

## Debug Mode

### debug-disabled

**Severity:** error

`APP_DEBUG` must be set to `false` in production environments.

**Why?**
- Debug mode exposes sensitive information (stack traces, environment variables)
- Attackers can use this information to exploit vulnerabilities
- Performance impact from detailed error reporting

**Good:**
```env
APP_DEBUG=false
APP_ENV=production
```

**Bad:**
```env
APP_DEBUG=true
APP_ENV=production
```

---

## Environment File Exposure

### env-not-exposed

**Severity:** error

The `.env` file must never be accessible from the public directory.

**Why?**
- Contains database credentials, API keys, app secrets
- Direct access would expose all sensitive configuration
- Common attack vector for Laravel applications

**Check:**
- Ensure `.env` is not in `public/` directory
- Verify web server blocks access to dotfiles
- Use `php artisan config:cache` in production

---

## Seeders in Routes

### seeders-not-in-routes

**Severity:** error

Database seeders must not be callable via HTTP routes.

**Why?**
- Seeders can reset or corrupt production data
- No authentication by default
- Could be exploited for denial of service

**Bad:**
```php
// routes/web.php
Route::get('/seed', function () {
    Artisan::call('db:seed');  // NEVER do this!
});
```

**Good:**
- Run seeders only via CLI during deployment
- Use migrations for production data changes
- Implement proper admin-only commands if needed

---

## Debug Functions

### no-dd-dump

**Severity:** warning

Debug functions (`dd()`, `dump()`, `var_dump()`) must be removed from production code.

**Why?**
- Halts execution unexpectedly (`dd()`)
- Exposes internal data structures
- Unprofessional user experience
- Can leak sensitive information

**Bad:**
```php
public function show(User $user)
{
    dd($user);  // Stops execution, shows data
    dump($user->roles);  // Outputs to browser
}
```

**Good:**
```php
public function show(User $user)
{
    Log::debug('User loaded', ['id' => $user->id]);
    return view('users.show', compact('user'));
}
```

**Tip:** Use IDE search or `grep -r "dd\|dump\|var_dump" app/` to find remaining debug calls.
