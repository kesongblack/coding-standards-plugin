# Next.js Folder Structure Standards

## Recommended Structure (App Router)

```
project-root/
├── app/                          # App Router pages and layouts
│   ├── layout.tsx                # Root layout
│   ├── page.tsx                  # Home page
│   ├── loading.tsx               # Root loading state
│   ├── error.tsx                 # Root error boundary
│   ├── not-found.tsx             # 404 page
│   ├── globals.css               # Global styles
│   ├── (auth)/                   # Route group (no URL segment)
│   │   ├── login/page.tsx
│   │   └── register/page.tsx
│   ├── dashboard/
│   │   ├── layout.tsx            # Dashboard layout
│   │   ├── page.tsx              # Dashboard home
│   │   └── settings/page.tsx
│   ├── api/                      # API routes
│   │   ├── users/route.ts
│   │   └── posts/
│   │       ├── route.ts
│   │       └── [id]/route.ts
│   └── actions/                  # Server actions (alternative: lib/actions/)
│       └── user.ts
├── components/                   # Reusable UI components
│   ├── ui/                       # Base UI components
│   │   ├── Button.tsx
│   │   ├── Input.tsx
│   │   └── Modal.tsx
│   ├── layout/                   # Layout components
│   │   ├── Header.tsx
│   │   ├── Footer.tsx
│   │   └── Sidebar.tsx
│   └── features/                 # Feature-specific components
│       ├── auth/
│       │   ├── LoginForm.tsx
│       │   └── RegisterForm.tsx
│       └── dashboard/
│           └── StatsCard.tsx
├── lib/                          # Utilities, helpers, config
│   ├── utils.ts                  # General utilities
│   ├── db.ts                     # Database client
│   ├── auth.ts                   # Auth helpers
│   └── validations.ts            # Zod schemas
├── hooks/                        # Custom React hooks
│   ├── useAuth.ts
│   ├── useDebounce.ts
│   └── useLocalStorage.ts
├── types/                        # TypeScript types
│   ├── index.ts                  # Re-exports
│   ├── user.ts
│   └── api.ts
├── public/                       # Static assets
│   ├── images/
│   ├── fonts/
│   └── favicon.ico
├── middleware.ts                 # Edge middleware
├── next.config.js                # Next.js config
├── tailwind.config.js            # Tailwind config (if used)
└── tsconfig.json                 # TypeScript config
```

---

## Core Directories

### `app/` - Application Routes

Contains all pages, layouts, and API routes using App Router conventions.

**Good:**
```
app/
├── page.tsx                      # Home (/)
├── about/page.tsx                # About (/about)
├── blog/
│   ├── page.tsx                  # Blog list (/blog)
│   └── [slug]/page.tsx           # Blog post (/blog/:slug)
└── api/
    └── users/route.ts            # API endpoint (/api/users)
```

**Bad:**
```
app/
├── HomePage.tsx                  # Wrong: should be page.tsx
├── Blog/page.tsx                 # Wrong: PascalCase directory
└── api/
    └── users.ts                  # Wrong: should be route.ts
```

### Why?
- Next.js App Router convention
- File-based routing requires specific names
- URL-friendly paths

---

### `components/` - Reusable Components

Organized by purpose: `ui/` for base components, `layout/` for structure, `features/` for domain-specific.

**Good:**
```
components/
├── ui/
│   ├── Button.tsx
│   └── Button.test.tsx           # Colocated test
├── layout/
│   └── Header.tsx
└── features/
    └── checkout/
        └── CartSummary.tsx
```

**Bad:**
```
components/
├── Button.tsx                    # Flat structure - harder to scale
├── Header.tsx
├── CartSummary.tsx
└── LoginForm.tsx
```

### Why?
- Scalable organization
- Clear component categories
- Easy to find related components

---

### `lib/` - Utilities and Configuration

Server-side utilities, database clients, and shared configuration.

**Good:**
```
lib/
├── db.ts                         # Database client (Prisma, Drizzle)
├── auth.ts                       # Auth configuration
├── utils.ts                      # General utilities
└── validations/
    ├── user.ts                   # User schemas
    └── post.ts                   # Post schemas
```

**Bad:**
```
utils/                            # Wrong: use lib/
helpers/                          # Wrong: use lib/
lib/
└── everything.ts                 # Wrong: split by concern
```

### Why?
- Next.js convention (`@/lib`)
- Clear separation from client code
- Easy imports via path alias

---

### `hooks/` - Custom React Hooks

All custom hooks in one place with `use` prefix.

**Good:**
```
hooks/
├── useAuth.ts
├── useDebounce.ts
└── useMediaQuery.ts
```

**Bad:**
```
hooks/
├── auth.ts                       # Wrong: no 'use' prefix
├── UseAuth.ts                    # Wrong: PascalCase
└── use-auth.ts                   # Wrong: kebab-case
```

### Why?
- React Rules of Hooks
- Easy discovery
- Consistent naming

---

### `types/` - TypeScript Definitions

Centralized type definitions with re-exports.

**Good:**
```
types/
├── index.ts                      # Re-exports all types
├── user.ts
├── post.ts
└── api.ts
```

**Bad:**
```
types.ts                          # Single file - hard to maintain
typings/                          # Wrong: use types/
@types/                           # Wrong: reserved for declarations
```

### Why?
- Clean imports (`import { User } from '@/types'`)
- Organized by domain
- Easy to maintain

---

## Route Groups and Parallel Routes

### Route Groups `(name)`

Group routes without affecting URL structure.

**Good:**
```
app/
├── (marketing)/
│   ├── about/page.tsx            # /about
│   └── pricing/page.tsx          # /pricing
├── (app)/
│   ├── dashboard/page.tsx        # /dashboard
│   └── settings/page.tsx         # /settings
└── (auth)/
    ├── login/page.tsx            # /login
    └── register/page.tsx         # /register
```

### Why?
- Shared layouts per group
- Organized routes
- No URL impact

---

## Colocation

Keep related files together.

**Good:**
```
components/
└── Button/
    ├── Button.tsx
    ├── Button.test.tsx
    ├── Button.module.css
    └── index.ts                  # Re-export
```

**Alternative (Flat):**
```
components/
├── Button.tsx
├── Button.test.tsx
└── Button.module.css
```

### Why?
- Easy to find related files
- Self-contained components
- Simpler refactoring

---

## Server Actions Location

Two valid approaches:

### Option 1: In `app/actions/`
```
app/
└── actions/
    ├── user.ts
    └── post.ts
```

### Option 2: In `lib/actions/`
```
lib/
└── actions/
    ├── user.ts
    └── post.ts
```

Both are acceptable. Choose one and be consistent.

---

## Anti-Patterns

### Don't Mix Pages and App Router
```
# Bad - mixed routing systems
pages/                            # Remove if using App Router
app/
```

### Don't Put Components in `app/`
```
# Bad
app/
├── page.tsx
└── components/                   # Wrong location
    └── Button.tsx

# Good
app/
└── page.tsx
components/                       # At root level
└── Button.tsx
```

### Don't Use Deep Nesting for Components
```
# Bad
components/
└── features/
    └── dashboard/
        └── widgets/
            └── stats/
                └── cards/
                    └── StatsCard.tsx

# Good - max 2-3 levels
components/
└── features/
    └── dashboard/
        └── StatsCard.tsx
```

---

## Common Variations

These variations are acceptable based on project needs:

| Standard | Variation | When to Use |
|----------|-----------|-------------|
| `components/` | `src/components/` | Using `src/` directory |
| `lib/` | `src/lib/` | Using `src/` directory |
| `hooks/` | `lib/hooks/` | Prefer all utilities in lib |
| `types/` | `lib/types/` | Prefer all utilities in lib |
| Flat components | Folder components | Small vs large projects |

---

## Monorepo Structure

For monorepo setups (Turborepo, Nx):

```
apps/
├── web/                          # Next.js app
│   ├── app/
│   └── components/
├── admin/                        # Admin Next.js app
│   ├── app/
│   └── components/
└── docs/                         # Documentation site
packages/
├── ui/                           # Shared UI components
├── config/                       # Shared configs
└── types/                        # Shared types
```

### Why?
- Shared code between apps
- Independent deployments
- Consistent tooling
