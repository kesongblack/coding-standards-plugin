# Next.js Production Safety Standards

## Overview

These rules ensure your Next.js application is properly configured for production deployment.

---

## Console Statements

### no-console-logs

**Severity:** warning

Console statements should be removed from production code.

**Why?**
- Clutters browser developer tools
- Can expose sensitive debugging information
- Slight performance overhead
- Unprofessional in production

**Bad:**
```tsx
export function UserCard({ user }) {
  console.log('Rendering user:', user);  // Remove this
  console.error('Debug:', user.email);   // And this
  return <div>{user.name}</div>;
}
```

**Good:**
```tsx
export function UserCard({ user }) {
  // Use proper logging service in production
  if (process.env.NODE_ENV === 'development') {
    console.log('Rendering user:', user);
  }
  return <div>{user.name}</div>;
}
```

**Tip:** Use ESLint rule `no-console` with `warn` level.

---

## Development-Only Code

### no-dev-only-code

**Severity:** warning

Review code blocks that check for development environment.

**Why?**
- May contain debug features that shouldn't ship
- Could indicate incomplete feature flags
- Potential security implications

**Review these patterns:**
```tsx
// Make sure these blocks don't contain security risks
if (process.env.NODE_ENV === 'development') {
  // Development-only code
}

if (process.env.NODE_ENV !== 'production') {
  // Non-production code
}
```

---

## Environment Variables

### env-vars-required

**Severity:** error

All required environment variables must be set in production.

**Why?**
- Missing env vars cause runtime errors
- Features may silently fail
- Security configurations may be skipped

**Best Practices:**
```tsx
// lib/env.ts - Validate at build time
const requiredEnvVars = [
  'DATABASE_URL',
  'NEXTAUTH_SECRET',
  'NEXT_PUBLIC_API_URL',
] as const;

for (const envVar of requiredEnvVars) {
  if (!process.env[envVar]) {
    throw new Error(`Missing required env var: ${envVar}`);
  }
}
```

**Checklist:**
- [ ] All `NEXT_PUBLIC_*` vars set for client-side
- [ ] All server-side vars configured
- [ ] No placeholder values in production

---

## Build Configuration

### build-optimized

**Severity:** info

Verify production build optimizations in `next.config.js`.

**Recommended Settings:**
```js
// next.config.js
module.exports = {
  // Enable React strict mode
  reactStrictMode: true,

  // Optimize images
  images: {
    formats: ['image/avif', 'image/webp'],
  },

  // Enable SWC minification (default in Next.js 13+)
  swcMinify: true,

  // Configure headers for security
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          { key: 'X-Frame-Options', value: 'DENY' },
          { key: 'X-Content-Type-Options', value: 'nosniff' },
        ],
      },
    ];
  },
};
```

**Pre-deployment Checklist:**
- [ ] Run `next build` successfully
- [ ] Check bundle size with `@next/bundle-analyzer`
- [ ] Verify no development dependencies in production
