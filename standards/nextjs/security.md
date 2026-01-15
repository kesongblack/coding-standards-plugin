# Next.js Security Standards

## XSS Prevention

React escapes by default, but be cautious with certain patterns.

**Good:**
```tsx
// React auto-escapes (safe)
function UserProfile({ user }: { user: User }) {
  return (
    <div>
      <h1>{user.name}</h1>
      <p>{user.bio}</p>
    </div>
  );
}

// Safe attribute usage
<a href={`/users/${user.id}`}>Profile</a>
```

**Bad:**
```tsx
// dangerouslySetInnerHTML - XSS RISK
function UserBio({ html }: { html: string }) {
  return <div dangerouslySetInnerHTML={{ __html: html }} />;  // Dangerous!
}

// Unsafe href with user input
<a href={userInput}>Click</a>  // Could be javascript:alert()
```

**When `dangerouslySetInnerHTML` is necessary:**
```tsx
import DOMPurify from 'dompurify';

function SafeHtml({ html }: { html: string }) {
  const sanitized = DOMPurify.sanitize(html, {
    ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a', 'p'],
    ALLOWED_ATTR: ['href'],
  });

  return <div dangerouslySetInnerHTML={{ __html: sanitized }} />;
}
```

**Validate URLs:**
```tsx
function SafeLink({ url, children }: { url: string; children: React.ReactNode }) {
  const isValidUrl = url.startsWith('http://') || url.startsWith('https://') || url.startsWith('/');

  if (!isValidUrl) {
    return <span>{children}</span>;
  }

  return <a href={url}>{children}</a>;
}
```

### Why?
- Prevents script injection
- React escapes by default
- Sanitize when needed

---

## Environment Variables

Understand NEXT_PUBLIC_ exposure.

**Good:**
```env
# .env.local (server-side only - safe)
DATABASE_URL=postgresql://...
API_SECRET_KEY=sk_live_...
JWT_SECRET=your-secret-key

# Public variables (exposed to browser)
NEXT_PUBLIC_API_URL=https://api.example.com
NEXT_PUBLIC_STRIPE_KEY=pk_live_...
NEXT_PUBLIC_GA_ID=UA-...
```

```tsx
// Server Component (safe - secret not exposed)
async function getData() {
  const res = await fetch(process.env.API_URL, {
    headers: {
      Authorization: `Bearer ${process.env.API_SECRET_KEY}`,
    },
  });
  return res.json();
}

// Client Component (only public vars accessible)
function StripeButton() {
  const stripeKey = process.env.NEXT_PUBLIC_STRIPE_KEY;
  // process.env.API_SECRET_KEY is undefined here
}
```

**Bad:**
```env
# WRONG - exposing secrets
NEXT_PUBLIC_API_SECRET=sk_live_...    # Exposed to browser!
NEXT_PUBLIC_DATABASE_URL=postgresql:// # Never!
```

```tsx
// WRONG - trying to access server vars in client
'use client';

function ClientComponent() {
  // This will be undefined in browser
  const secret = process.env.API_SECRET_KEY;  // undefined
}
```

### Why?
- NEXT_PUBLIC_ vars are bundled into client code
- Anyone can see them in browser
- Keep secrets server-side only

---

## API Route Security

Secure your API endpoints.

**Good:**
```tsx
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { z } from 'zod';
import { rateLimit } from '@/lib/rate-limit';

const userSchema = z.object({
  name: z.string().min(1).max(100),
  email: z.string().email(),
});

export async function POST(request: NextRequest) {
  // 1. Rate limiting
  const limiter = await rateLimit(request);
  if (!limiter.success) {
    return NextResponse.json(
      { error: 'Too many requests' },
      { status: 429 }
    );
  }

  // 2. Authentication
  const session = await getServerSession();
  if (!session) {
    return NextResponse.json(
      { error: 'Unauthorized' },
      { status: 401 }
    );
  }

  // 3. Input validation
  const body = await request.json();
  const result = userSchema.safeParse(body);

  if (!result.success) {
    return NextResponse.json(
      { error: 'Invalid input', details: result.error.issues },
      { status: 400 }
    );
  }

  // 4. Process validated data
  const user = await createUser(result.data);

  return NextResponse.json(user, { status: 201 });
}
```

**Bad:**
```tsx
// No auth, no validation, no rate limiting
export async function POST(request: NextRequest) {
  const body = await request.json();
  const user = await db.user.create({ data: body });  // Dangerous!
  return NextResponse.json(user);
}
```

### Why?
- Validates input
- Authenticates users
- Prevents abuse

---

## Server Actions Security

Validate and authorize Server Actions.

**Good:**
```tsx
// app/actions/user.ts
'use server';

import { getServerSession } from 'next-auth';
import { z } from 'zod';
import { revalidatePath } from 'next/cache';

const updateProfileSchema = z.object({
  name: z.string().min(1).max(100),
  bio: z.string().max(500).optional(),
});

export async function updateProfile(formData: FormData) {
  // 1. Authentication
  const session = await getServerSession();
  if (!session?.user) {
    throw new Error('Unauthorized');
  }

  // 2. Validation
  const rawData = {
    name: formData.get('name'),
    bio: formData.get('bio'),
  };

  const result = updateProfileSchema.safeParse(rawData);
  if (!result.success) {
    return { error: 'Invalid input' };
  }

  // 3. Authorization (user can only update their own profile)
  const userId = session.user.id;

  // 4. Update
  await db.user.update({
    where: { id: userId },
    data: result.data,
  });

  revalidatePath('/profile');
  return { success: true };
}
```

**Bad:**
```tsx
'use server';

export async function updateProfile(formData: FormData) {
  // No auth check!
  // No validation!
  const userId = formData.get('userId');  // User-controlled ID!

  await db.user.update({
    where: { id: userId },
    data: {
      name: formData.get('name'),
      role: formData.get('role'),  // Role escalation!
    },
  });
}
```

### Why?
- Server Actions are public endpoints
- Must validate all input
- Must verify authorization

---

## Content Security Policy

Configure CSP headers for protection.

**Good:**
```tsx
// next.config.js
const cspHeader = `
  default-src 'self';
  script-src 'self' 'unsafe-eval' 'unsafe-inline';
  style-src 'self' 'unsafe-inline';
  img-src 'self' blob: data: https:;
  font-src 'self';
  object-src 'none';
  base-uri 'self';
  form-action 'self';
  frame-ancestors 'none';
  upgrade-insecure-requests;
`;

module.exports = {
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'Content-Security-Policy',
            value: cspHeader.replace(/\n/g, ''),
          },
        ],
      },
    ];
  },
};
```

**With nonce for inline scripts:**
```tsx
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const nonce = Buffer.from(crypto.randomUUID()).toString('base64');
  const cspHeader = `
    default-src 'self';
    script-src 'self' 'nonce-${nonce}' 'strict-dynamic';
    style-src 'self' 'nonce-${nonce}';
  `;

  const response = NextResponse.next();
  response.headers.set('Content-Security-Policy', cspHeader.replace(/\n/g, ''));
  response.headers.set('x-nonce', nonce);

  return response;
}
```

### Why?
- Prevents XSS attacks
- Controls resource loading
- Defense in depth

---

## Security Headers

Configure essential security headers.

**Good:**
```tsx
// next.config.js
module.exports = {
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'X-DNS-Prefetch-Control',
            value: 'on',
          },
          {
            key: 'Strict-Transport-Security',
            value: 'max-age=63072000; includeSubDomains; preload',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'X-Frame-Options',
            value: 'SAMEORIGIN',
          },
          {
            key: 'X-XSS-Protection',
            value: '1; mode=block',
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin',
          },
          {
            key: 'Permissions-Policy',
            value: 'camera=(), microphone=(), geolocation=()',
          },
        ],
      },
    ];
  },
};
```

### Why?
- HTTPS enforcement
- Clickjacking protection
- MIME type sniffing protection

---

## Authentication Best Practices

Use established auth libraries.

**Good (NextAuth.js):**
```tsx
// app/api/auth/[...nextauth]/route.ts
import NextAuth from 'next-auth';
import CredentialsProvider from 'next-auth/providers/credentials';
import bcrypt from 'bcrypt';

const handler = NextAuth({
  providers: [
    CredentialsProvider({
      async authorize(credentials) {
        const user = await db.user.findUnique({
          where: { email: credentials?.email },
        });

        if (!user || !credentials?.password) {
          return null;
        }

        const isValid = await bcrypt.compare(
          credentials.password,
          user.password
        );

        if (!isValid) {
          return null;
        }

        return { id: user.id, email: user.email, name: user.name };
      },
    }),
  ],
  session: {
    strategy: 'jwt',
    maxAge: 30 * 24 * 60 * 60, // 30 days
  },
  pages: {
    signIn: '/login',
    error: '/auth/error',
  },
});

export { handler as GET, handler as POST };
```

**Bad:**
```tsx
// Rolling your own auth
export async function POST(request: NextRequest) {
  const { email, password } = await request.json();

  const user = await db.user.findUnique({ where: { email } });

  // Plain text comparison - NEVER
  if (user?.password === password) {
    // Setting cookie manually - error prone
    const response = NextResponse.json({ success: true });
    response.cookies.set('userId', user.id);  // Not secure!
    return response;
  }
}
```

### Why?
- Battle-tested security
- Proper session handling
- CSRF protection built-in

---

## Input Validation

Validate all user input on the server.

**Good:**
```tsx
import { z } from 'zod';

// Define schemas
const createUserSchema = z.object({
  name: z.string().min(1).max(100),
  email: z.string().email(),
  password: z.string().min(8).regex(
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
    'Password must contain uppercase, lowercase, and number'
  ),
  age: z.number().int().min(13).max(120).optional(),
  website: z.string().url().optional(),
});

// Use in API route
export async function POST(request: NextRequest) {
  const body = await request.json();

  const result = createUserSchema.safeParse(body);

  if (!result.success) {
    return NextResponse.json(
      { error: 'Validation failed', issues: result.error.issues },
      { status: 400 }
    );
  }

  // result.data is typed and validated
  const user = await createUser(result.data);
  return NextResponse.json(user);
}
```

**Bad:**
```tsx
export async function POST(request: NextRequest) {
  const body = await request.json();

  // No validation!
  const user = await db.user.create({
    data: {
      name: body.name,
      email: body.email,
      isAdmin: body.isAdmin,  // Privilege escalation!
    },
  });
}
```

### Why?
- Type safety
- Prevents injection
- Clear error messages

---

## SQL Injection Prevention

Use parameterized queries with your ORM.

**Good (Prisma):**
```tsx
// Prisma handles parameterization
const user = await prisma.user.findUnique({
  where: { email: userInput },
});

// Safe raw query
const users = await prisma.$queryRaw`
  SELECT * FROM users WHERE email = ${userInput}
`;
```

**Good (Drizzle):**
```tsx
import { eq } from 'drizzle-orm';

const user = await db
  .select()
  .from(users)
  .where(eq(users.email, userInput));
```

**Bad:**
```tsx
// String interpolation - SQL INJECTION
const user = await prisma.$queryRawUnsafe(
  `SELECT * FROM users WHERE email = '${userInput}'`
);

// Template literal without Prisma's handling
const query = `SELECT * FROM users WHERE id = ${userId}`;
```

### Why?
- Prevents SQL injection
- ORMs handle escaping
- Safe query building

---

## File Upload Security

Validate uploads thoroughly.

**Good:**
```tsx
// app/api/upload/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { writeFile } from 'fs/promises';
import path from 'path';
import crypto from 'crypto';

const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const MAX_SIZE = 5 * 1024 * 1024; // 5MB

export async function POST(request: NextRequest) {
  const formData = await request.formData();
  const file = formData.get('file') as File;

  if (!file) {
    return NextResponse.json({ error: 'No file provided' }, { status: 400 });
  }

  // Validate type
  if (!ALLOWED_TYPES.includes(file.type)) {
    return NextResponse.json({ error: 'Invalid file type' }, { status: 400 });
  }

  // Validate size
  if (file.size > MAX_SIZE) {
    return NextResponse.json({ error: 'File too large' }, { status: 400 });
  }

  // Generate safe filename
  const ext = path.extname(file.name);
  const safeFilename = `${crypto.randomUUID()}${ext}`;

  // Save file
  const bytes = await file.arrayBuffer();
  const buffer = Buffer.from(bytes);
  await writeFile(`./uploads/${safeFilename}`, buffer);

  return NextResponse.json({ filename: safeFilename });
}
```

**Bad:**
```tsx
export async function POST(request: NextRequest) {
  const formData = await request.formData();
  const file = formData.get('file') as File;

  // Using original filename - PATH TRAVERSAL RISK
  await writeFile(`./uploads/${file.name}`, await file.arrayBuffer());
}
```

### Why?
- Validates file types
- Prevents path traversal
- Limits file size

---

## Rate Limiting

Protect against abuse.

**Good:**
```tsx
// lib/rate-limit.ts
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(10, '10 s'),
  analytics: true,
});

export async function rateLimit(request: NextRequest) {
  const ip = request.ip ?? '127.0.0.1';
  return await ratelimit.limit(ip);
}

// In API route
export async function POST(request: NextRequest) {
  const { success, remaining } = await rateLimit(request);

  if (!success) {
    return NextResponse.json(
      { error: 'Rate limit exceeded' },
      {
        status: 429,
        headers: { 'X-RateLimit-Remaining': remaining.toString() },
      }
    );
  }

  // Process request...
}
```

### Why?
- Prevents DDoS
- Limits brute force
- Protects resources

---

## Security Checklist

| Area | Check |
|------|-------|
| XSS | No `dangerouslySetInnerHTML` with user input |
| Env | Secrets not prefixed with `NEXT_PUBLIC_` |
| Auth | Using NextAuth or similar library |
| API | All routes validate input |
| CSRF | Server Actions use built-in protection |
| Headers | Security headers configured |
| SQL | Using ORM with parameterized queries |
| Files | Upload validation for type/size |
| Rate Limit | API routes protected |
| CSP | Content Security Policy configured |
