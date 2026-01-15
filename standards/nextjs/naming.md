# Next.js Naming Standards

## Components

React components must use PascalCase naming.

**Good:**
```tsx
Button.tsx
UserProfile.tsx
NavigationBar.tsx
ProductCard.tsx
```

**Bad:**
```tsx
button.tsx          // lowercase
user-profile.tsx    // kebab-case
user_profile.tsx    // snake_case
```

### Why?
- React convention
- Clear distinction from regular files
- Aligns with JSX syntax: `<Button />` not `<button />`

---

## Pages (App Router)

App Router directories and files should use kebab-case.

**Good:**
```
app/
├── page.tsx                    // Home page
├── about/page.tsx              // About page
├── blog/
│   ├── page.tsx                // Blog listing
│   └── [slug]/page.tsx         // Blog post
└── user-profile/
    └── page.tsx                // User profile
```

**Bad:**
```
app/
├── About/page.tsx              // PascalCase directory
├── blog_post/page.tsx          // snake_case
└── userProfile/page.tsx        // camelCase
```

### Why?
- URL-friendly naming
- Next.js App Router convention
- SEO-friendly URLs

---

## Custom Hooks

Custom hooks must start with 'use' prefix and use camelCase.

**Good:**
```typescript
useAuth.ts
useLocalStorage.ts
useFetchData.ts
useDebounce.ts
```

**Bad:**
```typescript
auth.ts             // No 'use' prefix
UseAuth.ts          // PascalCase
use-auth.ts         // kebab-case
userAuth.ts         // Wrong prefix
```

### Why?
- React Rules of Hooks requirement
- Clear identification of hooks
- Enables React linting rules

---

## API Routes

API routes must be named `route.ts` or `route.js` in App Router.

**Good:**
```
app/api/
├── users/route.ts
├── posts/
│   ├── route.ts
│   └── [id]/route.ts
└── auth/
    ├── login/route.ts
    └── register/route.ts
```

**Bad:**
```
app/api/
├── users.ts                    // Wrong filename
├── posts/posts.ts              // Not route.ts
└── auth/loginAPI.ts            // Wrong naming
```

### Why?
- Next.js App Router requirement
- Consistent API structure
- Framework convention

---

## Utilities and Helpers

Utility functions should use camelCase naming.

**Good:**
```typescript
formatDate.ts
calculateTotal.ts
validateEmail.ts
parseQueryParams.ts
```

**Bad:**
```typescript
FormatDate.ts       // PascalCase
format-date.ts      // kebab-case
format_date.ts      // snake_case
```

### Why?
- JavaScript convention
- Matches function naming
- Clear distinction from components

---

## Types and Interfaces

Types and interfaces should use PascalCase with descriptive names.

**Good:**
```typescript
// types/user.ts
export interface User {
  id: string;
  name: string;
}

export type UserRole = 'admin' | 'user' | 'guest';

export interface UserProfile extends User {
  bio: string;
}
```

**Bad:**
```typescript
export interface user { }           // lowercase
export interface IUser { }          // Hungarian notation
export type userRole = string;      // camelCase
```

### Why?
- TypeScript convention
- Clear type identification
- Aligns with component naming

---

## Server Actions

Server actions should use descriptive verb phrases with camelCase.

**Good:**
```typescript
// app/actions/user.ts
export async function createUser(data: FormData) { }
export async function updateUserProfile(userId: string, data: FormData) { }
export async function deleteUser(userId: string) { }
```

**Bad:**
```typescript
export async function CreateUser() { }      // PascalCase
export async function user_create() { }     // snake_case
export async function doCreateUser() { }    // Redundant 'do'
```

### Why?
- JavaScript convention
- Action-oriented naming
- Clear function purpose

---

## Middleware

Middleware files should be named `middleware.ts` at root or route level.

**Good:**
```
middleware.ts                           // Root middleware
app/api/middleware.ts                   // API middleware
```

**Bad:**
```
customMiddleware.ts                     // Wrong name
middleware/auth.ts                      // Wrong location
```

### Why?
- Next.js convention
- Automatic middleware detection
- Clear purpose

---

## Environment Variables

Environment variables should use SCREAMING_SNAKE_CASE.

**Good:**
```env
# Public (client-side)
NEXT_PUBLIC_API_URL=https://api.example.com
NEXT_PUBLIC_STRIPE_KEY=pk_test_xxx

# Private (server-side only)
DATABASE_URL=postgresql://...
API_SECRET_KEY=secret123
STRIPE_SECRET_KEY=sk_test_xxx
```

**Bad:**
```env
next_public_api_url=...         // lowercase
NextPublicApiUrl=...            // PascalCase
apiUrl=...                      // camelCase (won't be exposed)
```

### Why?
- Next.js requirement for public variables
- Environment variable convention
- Clear distinction between public and private

---

## Constants

Constants should use SCREAMING_SNAKE_CASE.

**Good:**
```typescript
export const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB
export const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL;
export const DEFAULT_PAGE_SIZE = 20;
```

**Bad:**
```typescript
export const maxFileSize = 5242880;         // camelCase
export const MaxFileSize = 5242880;         // PascalCase
```

### Why?
- JavaScript convention
- Clear identification of constants
- Distinguishes from regular variables

---

## CSS Modules

CSS module files should match component names with `.module.css` suffix.

**Good:**
```
components/
├── Button.tsx
├── Button.module.css
├── UserProfile.tsx
└── UserProfile.module.css
```

**Bad:**
```
components/
├── Button.tsx
├── button.css                  // Doesn't match component case
├── UserProfile.tsx
└── styles.module.css           // Not descriptive
```

### Why?
- Clear association with components
- Next.js CSS Modules convention
- Easy to locate styles

---

## Test Files

Test files should be colocated with source files using `.test` or `.spec` suffix.

**Good:**
```
components/
├── Button.tsx
├── Button.test.tsx
├── Button.module.css
├── UserProfile.tsx
└── UserProfile.spec.tsx
```

**Bad:**
```
components/
├── Button.tsx
└── ButtonTest.tsx              // No .test/.spec suffix

__tests__/
└── Button.test.tsx             // Not colocated
```

### Why?
- Easy to find tests
- Colocated with implementation
- Standard testing convention

---

## Directories

Directories should use kebab-case for clarity.

**Good:**
```
components/
lib/
app/
├── user-dashboard/
├── admin-panel/
└── api/
```

**Bad:**
```
Components/                     // PascalCase
user_dashboard/                 // snake_case
userDashboard/                  // camelCase
```

### Why?
- URL-friendly
- Unix/Linux convention
- Consistent across the project
