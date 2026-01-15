# Next.js Design Patterns & Best Practices

## Server Components by Default

Use Server Components by default and opt into Client Components only when needed.

### Server Component (Default)
```tsx
// app/blog/page.tsx
async function BlogPage() {
  const posts = await fetch('https://api.example.com/posts');
  const data = await posts.json();

  return (
    <div>
      <h1>Blog Posts</h1>
      {data.map(post => (
        <article key={post.id}>
          <h2>{post.title}</h2>
          <p>{post.excerpt}</p>
        </article>
      ))}
    </div>
  );
}

export default BlogPage;
```

### Client Component (When Needed)
```tsx
// components/SearchInput.tsx
'use client';

import { useState } from 'react';

export function SearchInput() {
  const [query, setQuery] = useState('');

  return (
    <input
      type="text"
      value={query}
      onChange={(e) => setQuery(e.target.value)}
      placeholder="Search..."
    />
  );
}
```

### When to Use Client Components?
- Need hooks (useState, useEffect, etc.)
- Event handlers (onClick, onChange, etc.)
- Browser-only APIs (localStorage, window, etc.)
- Third-party libraries that require client-side

### Why?
- Better performance (less JavaScript shipped)
- Automatic code splitting
- SEO-friendly
- Reduced bundle size

---

## Data Fetching in Server Components

Fetch data directly in Server Components for better performance.

### Implementation
```tsx
// app/users/[id]/page.tsx
interface User {
  id: string;
  name: string;
  email: string;
}

async function getUser(id: string): Promise<User> {
  const res = await fetch(`https://api.example.com/users/${id}`, {
    next: { revalidate: 3600 } // Cache for 1 hour
  });

  if (!res.ok) throw new Error('Failed to fetch user');

  return res.json();
}

async function UserPage({ params }: { params: { id: string } }) {
  const user = await getUser(params.id);

  return (
    <div>
      <h1>{user.name}</h1>
      <p>{user.email}</p>
    </div>
  );
}

export default UserPage;
```

### Caching Strategies
```tsx
// No caching (always fresh)
fetch(url, { cache: 'no-store' });

// Cache with revalidation
fetch(url, { next: { revalidate: 3600 } });

// Cache indefinitely (static)
fetch(url, { cache: 'force-cache' });
```

### Why?
- Server-side rendering benefits
- Reduced client-side JavaScript
- Better initial page load
- SEO improvements

---

## Avoid useEffect for Data Fetching

Don't use useEffect for data fetching in Client Components when Server Components can handle it.

### Anti-pattern
```tsx
'use client';

import { useEffect, useState } from 'react';

export function UserProfile({ userId }: { userId: string }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch(`/api/users/${userId}`)
      .then(res => res.json())
      .then(data => {
        setUser(data);
        setLoading(false);
      });
  }, [userId]);

  if (loading) return <div>Loading...</div>;

  return <div>{user?.name}</div>;
}
```

### Better Pattern (Server Component)
```tsx
// No 'use client' directive
async function UserProfile({ userId }: { userId: string }) {
  const user = await fetch(`/api/users/${userId}`).then(r => r.json());

  return <div>{user.name}</div>;
}
```

### When Client-Side Fetching is Needed (Use SWR or React Query)
```tsx
'use client';

import useSWR from 'swr';

const fetcher = (url: string) => fetch(url).then(r => r.json());

export function UserProfile({ userId }: { userId: string }) {
  const { data: user, error, isLoading } = useSWR(
    `/api/users/${userId}`,
    fetcher
  );

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error loading user</div>;

  return <div>{user.name}</div>;
}
```

### Why?
- Better performance
- Automatic caching and revalidation
- Less code to maintain
- Built-in error and loading states

---

## Loading and Error States

Use loading.tsx and error.tsx for route-level states.

### Loading State
```tsx
// app/dashboard/loading.tsx
export default function Loading() {
  return (
    <div className="animate-pulse">
      <div className="h-8 bg-gray-200 rounded w-1/4 mb-4"></div>
      <div className="h-4 bg-gray-200 rounded w-full mb-2"></div>
      <div className="h-4 bg-gray-200 rounded w-full mb-2"></div>
    </div>
  );
}
```

### Error State
```tsx
// app/dashboard/error.tsx
'use client';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div>
      <h2>Something went wrong!</h2>
      <p>{error.message}</p>
      <button onClick={reset}>Try again</button>
    </div>
  );
}
```

### Why?
- Automatic loading states during navigation
- Error boundaries built-in
- Better UX
- Less boilerplate

---

## Server Actions for Mutations

Use Server Actions for form submissions and mutations.

### Implementation
```tsx
// app/actions/user.ts
'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';

export async function createUser(formData: FormData) {
  const name = formData.get('name') as string;
  const email = formData.get('email') as string;

  // Validation
  if (!name || !email) {
    return { error: 'Name and email are required' };
  }

  // Database operation
  const user = await db.user.create({
    data: { name, email }
  });

  // Revalidate cache
  revalidatePath('/users');

  // Redirect
  redirect(`/users/${user.id}`);
}

// app/users/new/page.tsx
import { createUser } from '@/app/actions/user';

export default function NewUserPage() {
  return (
    <form action={createUser}>
      <input name="name" type="text" required />
      <input name="email" type="email" required />
      <button type="submit">Create User</button>
    </form>
  );
}
```

### Why?
- No API routes needed
- Built-in CSRF protection
- Type-safe
- Progressive enhancement

---

## Static and Dynamic Rendering

Understand when to use static vs dynamic rendering.

### Static (Default - Best Performance)
```tsx
// app/blog/[slug]/page.tsx
export async function generateStaticParams() {
  const posts = await fetch('https://api.example.com/posts').then(r => r.json());

  return posts.map((post) => ({
    slug: post.slug,
  }));
}

async function BlogPost({ params }: { params: { slug: string } }) {
  const post = await fetch(`https://api.example.com/posts/${params.slug}`)
    .then(r => r.json());

  return <article>{post.content}</article>;
}

export default BlogPost;
```

### Dynamic (When Data Changes Frequently)
```tsx
// app/dashboard/page.tsx
export const dynamic = 'force-dynamic'; // Opt into dynamic rendering

async function Dashboard() {
  const data = await fetch('https://api.example.com/dashboard', {
    cache: 'no-store'
  }).then(r => r.json());

  return <div>{data.stats}</div>;
}

export default Dashboard;
```

### Incremental Static Regeneration (ISR)
```tsx
async function ProductPage({ params }: { params: { id: string } }) {
  const product = await fetch(`https://api.example.com/products/${params.id}`, {
    next: { revalidate: 60 } // Revalidate every 60 seconds
  }).then(r => r.json());

  return <div>{product.name}</div>;
}
```

### Why?
- Optimal performance for each use case
- CDN caching for static pages
- Fresh data when needed
- Best of both worlds with ISR

---

## Composition Over Nesting

Keep component composition flat and avoid deep nesting.

### Anti-pattern
```tsx
function UserDashboard() {
  return (
    <DashboardLayout>
      <DashboardHeader>
        <UserMenu>
          <UserAvatar>
            <UserImage />
          </UserAvatar>
          <UserDropdown>
            <UserDropdownItem />
          </UserDropdown>
        </UserMenu>
      </DashboardHeader>
      <DashboardContent>
        <DashboardSidebar>
          <SidebarNav>
            <SidebarNavItem />
          </SidebarNav>
        </DashboardSidebar>
        <DashboardMain>
          {/* Content */}
        </DashboardMain>
      </DashboardContent>
    </DashboardLayout>
  );
}
```

### Better Pattern
```tsx
function UserDashboard() {
  return (
    <DashboardLayout
      header={<Header user={<UserMenu />} />}
      sidebar={<Sidebar nav={<Nav items={navItems} />} />}
      content={<MainContent />}
    />
  );
}
```

### Why?
- Easier to read and maintain
- Better prop passing
- More flexible composition
- Reduced coupling

---

## API Route Handlers

Use Route Handlers for API endpoints with proper validation.

### Implementation
```tsx
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';

const userSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
});

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();

    // Validation
    const validated = userSchema.parse(body);

    // Database operation
    const user = await db.user.create({
      data: validated
    });

    return NextResponse.json(user, { status: 201 });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { error: 'Validation failed', details: error.errors },
        { status: 400 }
      );
    }

    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams;
  const page = searchParams.get('page') || '1';

  const users = await db.user.findMany({
    skip: (parseInt(page) - 1) * 10,
    take: 10
  });

  return NextResponse.json(users);
}
```

### Why?
- Type-safe request/response
- Proper error handling
- Input validation
- RESTful conventions

---

## Parallel Data Fetching

Fetch data in parallel when possible.

### Sequential (Slow)
```tsx
async function UserProfile({ id }: { id: string }) {
  const user = await fetchUser(id);
  const posts = await fetchUserPosts(id);
  const comments = await fetchUserComments(id);

  return <div>{/* Render */}</div>;
}
```

### Parallel (Fast)
```tsx
async function UserProfile({ id }: { id: string }) {
  const [user, posts, comments] = await Promise.all([
    fetchUser(id),
    fetchUserPosts(id),
    fetchUserComments(id)
  ]);

  return <div>{/* Render */}</div>;
}
```

### Why?
- Faster page loads
- Better user experience
- Efficient resource usage

---

## Metadata for SEO

Use Metadata API for SEO optimization.

### Static Metadata
```tsx
// app/blog/[slug]/page.tsx
import { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'My Blog',
  description: 'A blog about web development',
};

export default function BlogPage() {
  return <div>Blog</div>;
}
```

### Dynamic Metadata
```tsx
export async function generateMetadata({
  params
}: {
  params: { slug: string }
}): Promise<Metadata> {
  const post = await fetchPost(params.slug);

  return {
    title: post.title,
    description: post.excerpt,
    openGraph: {
      title: post.title,
      description: post.excerpt,
      images: [post.image],
    },
  };
}
```

### Why?
- Better SEO
- Social media previews
- Type-safe metadata
- Automatic meta tag generation

---

## Environment Variables

Properly manage environment variables.

### Server-Only Variables
```typescript
// lib/config.ts
export const config = {
  databaseUrl: process.env.DATABASE_URL!,
  apiSecret: process.env.API_SECRET_KEY!,
};
```

### Public Variables (Client-Side)
```typescript
// lib/client-config.ts
export const clientConfig = {
  apiUrl: process.env.NEXT_PUBLIC_API_URL!,
  stripeKey: process.env.NEXT_PUBLIC_STRIPE_KEY!,
};
```

### Validation (Recommended)
```typescript
// lib/env.ts
import { z } from 'zod';

const envSchema = z.object({
  DATABASE_URL: z.string().url(),
  NEXT_PUBLIC_API_URL: z.string().url(),
  API_SECRET_KEY: z.string().min(32),
});

export const env = envSchema.parse(process.env);
```

### Why?
- Security (private variables never exposed)
- Type safety
- Early error detection
- Clear documentation
