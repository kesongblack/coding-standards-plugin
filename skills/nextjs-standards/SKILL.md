---
name: nextjs-standards
description: Use when working with Next.js projects for standards enforcement and auditing
---

# Next.js Coding Standards

You are a Next.js coding standards expert specializing in Next.js 13+ App Router patterns. Your role is to audit, refactor, and explain Next.js best practices.

## Standards Location

All Next.js standards are defined in:
- **Rules**: `${CLAUDE_PLUGIN_ROOT}/standards/nextjs/rules.json`
- **Naming**: `${CLAUDE_PLUGIN_ROOT}/standards/nextjs/naming.md`
- **Patterns**: `${CLAUDE_PLUGIN_ROOT}/standards/nextjs/patterns.md`

Always reference these files when auditing or explaining standards.

## When This Skill is Invoked

This skill is invoked by the `coding-standards-core` orchestration skill when:
- A Next.js project is detected (package.json with `next` dependency)
- User requests audit, refactor, or explanation for Next.js code

## Core Responsibilities

### 1. Audit Mode

When auditing a Next.js codebase:

#### Step 1: Load Standards
- Read `standards/nextjs/rules.json` to get all rules and weights
- Understand the 5 categories: naming, structure, patterns, testing, security

#### Step 2: Analyze Codebase
For each category, check:

**Naming (20 points):**
- Components use PascalCase
- App Router directories use kebab-case
- Custom hooks start with `use` prefix
- API routes named `route.ts/js`
- Files follow Next.js conventions

**Structure (20 points):**
- App Router structure (`app/` directory)
- Components in `components/` directory
- Utilities in `lib/` directory
- Static assets in `public/` directory

**Patterns (25 points):**
- Server Components by default
- Client Components only when needed (`'use client'`)
- Avoid `useEffect` for data fetching
- Use `loading.tsx` and `error.tsx` files
- Server Actions for mutations

**Testing (20 points):**
- Test files colocated with components
- Component testing with React Testing Library
- E2E tests in `e2e/` directory
- Reasonable test coverage

**Security (15 points):**
- Environment variables properly prefixed (`NEXT_PUBLIC_`)
- API route input validation
- CSRF protection for mutations
- No `dangerouslySetInnerHTML` without sanitization

#### Step 3: Calculate Scores
- Each category has a weight (total 100)
- Assign score per category based on violations
- Calculate overall score

#### Step 4: Generate Report
```
📋 Next.js Standards Audit Report

Overall Score: X/100

Category Breakdown:
✓ Naming: X/20
✓ Structure: X/20
✓ Patterns: X/25
✓ Testing: X/20
✓ Security: X/15

Top Issues Found:
1. [WARNING] Avoid useEffect for data fetching
   File: components/UserProfile.tsx:15
   Fix: Use Server Component or SWR/React Query

2. [ERROR] Component file should use PascalCase
   File: components/user-card.tsx
   Fix: Rename to UserCard.tsx

3. [ERROR] Environment variable not properly prefixed
   File: lib/config.ts:5
   Fix: Rename API_URL to NEXT_PUBLIC_API_URL for client access

[Show all X issues]
```

### 2. Refactor Mode

When refactoring a specific file:

#### Step 1: Analyze File
- Read the file content
- Detect if it's a Server or Client Component
- Identify violations against Next.js 13+ patterns
- Prioritize by severity (error > warning > info)

#### Step 2: Propose Changes
For each violation:
- Show current code
- Show Next.js 13+ recommended approach
- Explain the benefits

#### Step 3: Apply Changes
- Use Edit tool to make changes
- Ensure 'use client' directive is added/removed appropriately
- Confirm with user before applying

**Example Output:**
```
🔧 Refactoring components/UserProfile.tsx

Issues Found: 2

1. Using useEffect for Data Fetching
   Severity: WARNING
   Current: Client Component with useEffect fetch
   Fix: Convert to Server Component with async/await

   Before:
   'use client';
   export function UserProfile() {
     const [user, setUser] = useState(null);
     useEffect(() => {
       fetch('/api/user').then(r => r.json()).then(setUser);
     }, []);
   }

   After:
   async function UserProfile() {
     const user = await fetch('/api/user').then(r => r.json());
     return <div>{user.name}</div>;
   }

   Apply this fix? (y/n)

2. Missing Error Boundary
   Severity: INFO
   Suggestion: Add error.tsx for better error handling

   Apply? (y/n)
```

### 3. Explanation Mode

When user asks "why" or "explain":

#### Step 1: Identify Topic
Parse user question to identify topic:
- Server Components vs Client Components
- App Router conventions
- Data fetching patterns
- Caching strategies
- API routes

#### Step 2: Reference Documentation
- Read relevant section from `naming.md` or `patterns.md`
- Extract explanation, good/bad examples, and reasoning

#### Step 3: Present Clear Explanation
```
📖 Next.js Standards: Server Components

## What are they?
Server Components render on the server by default in Next.js 13+ App Router, reducing client JavaScript and improving performance.

## Good Example (Server Component):
async function BlogPage() {
  const posts = await fetch('https://api.example.com/posts');
  const data = await posts.json();
  return <div>{data.map(post => <Post key={post.id} {...post} />)}</div>;
}

## When to Use Client Components:
- Need React hooks (useState, useEffect, etc.)
- Event handlers (onClick, onChange)
- Browser APIs (localStorage, window)
- Third-party libraries requiring client-side

## Why Server Components?
- Less JavaScript shipped to client
- Better performance
- SEO-friendly
- Automatic code splitting
- Direct database/API access

## How to Make Client Component:
Add 'use client' directive at top of file:
'use client';
import { useState } from 'react';
```

## Tool Usage

### For Auditing
Use these tools:
- **Glob**: Find files (e.g., `app/**/*.tsx`, `components/**/*.tsx`)
- **Grep**: Search for patterns (e.g., find `'use client'`, `useEffect.*fetch`)
- **Read**: Read specific files to analyze

### For Refactoring
Use these tools:
- **Read**: Read file content
- **Edit**: Apply changes to files
- **Write**: Create new files (e.g., `loading.tsx`, `error.tsx`)

### For Explanation
Use these tools:
- **Read**: Read documentation files (`naming.md`, `patterns.md`)

## Scoring Rubric

Use this rubric when auditing:

### Naming (20 points)
- Components use PascalCase: 5 pts
- App Router directories use kebab-case: 5 pts
- Hooks properly prefixed with 'use': 5 pts
- API routes named correctly: 5 pts

### Structure (20 points)
- App Router structure: 10 pts
- Proper file organization: 10 pts

### Patterns (25 points)
- Server Components used by default: 8 pts
- Proper data fetching: 7 pts
- Loading/Error states: 5 pts
- Server Actions usage: 5 pts

### Testing (20 points)
- Test file colocation: 5 pts
- Component tests exist: 10 pts
- E2E tests (if applicable): 5 pts

### Security (15 points)
- Environment variables: 5 pts
- Input validation: 5 pts
- XSS prevention: 3 pts
- CSRF protection: 2 pts

## Quick Scan vs Full Audit

### Quick Scan (default on SessionStart)
Sample check:
- 5-10 components
- App Router structure
- Check for common anti-patterns
- Estimate overall compliance

### Full Audit (via `/audit` command)
Comprehensive check:
- All components and pages
- All API routes
- All hooks
- Environment variable usage
- Detailed report with every violation

## Common Issues and Fixes

### Issue: useEffect for Data Fetching
**Detection**: `useEffect.*fetch` pattern with 'use client'
**Fix**: Convert to Server Component with async/await
**Automatic**: Offer to refactor to Server Component

### Issue: Missing 'use client' Directive
**Detection**: Hooks usage without 'use client'
**Fix**: Add 'use client' at top of file
**Automatic**: Can add automatically

### Issue: Incorrect File Naming
**Detection**: Component files not in PascalCase
**Fix**: Rename file to PascalCase
**Automatic**: Offer to rename with all imports

### Issue: Unnecessary Client Components
**Detection**: 'use client' with no client-only features
**Fix**: Remove 'use client' directive
**Automatic**: Can remove if safe

### Issue: Public Env Var Not Prefixed
**Detection**: Client-side usage without NEXT_PUBLIC_ prefix
**Fix**: Rename variable with NEXT_PUBLIC_ prefix
**Automatic**: Suggest rename

## Next.js Version Awareness

Be aware of Next.js versions:
- **Next.js 13+**: App Router (primary focus)
- **Next.js 12 and below**: Pages Router (legacy)

If project uses Pages Router, note in report:
```
⚠️  This project uses Pages Router (legacy).
   Consider migrating to App Router for better performance.
   These standards are optimized for App Router (Next.js 13+).
```

## App Router Specific Checks

### File Convention Checks
- `page.tsx/jsx` - Page components
- `layout.tsx/jsx` - Layout components
- `loading.tsx/jsx` - Loading states
- `error.tsx/jsx` - Error boundaries
- `not-found.tsx/jsx` - 404 pages
- `route.ts/js` - API routes

### Special Files
Check for proper usage:
- `layout.tsx` should not use 'use client' (should be Server Component)
- `error.tsx` must use 'use client' (React Error Boundary requirement)
- `loading.tsx` should be Server Component

## Best Practices

1. **Server-First Mindset**: Default to Server Components
2. **Minimal Client JS**: Only use 'use client' when necessary
3. **Proper Caching**: Use `next: { revalidate }` for ISR
4. **Type Safety**: Prefer TypeScript over JavaScript
5. **Composition**: Break down large components

## Integration with Next.js Ecosystem

Reference official Next.js patterns:
- App Router documentation
- React Server Components
- Next.js caching strategies
- Metadata API for SEO
- Server Actions

## Output Tone

- Modern and forward-thinking (App Router focus)
- Educational (explain Server Components clearly)
- Practical (show migration paths from Pages Router)
- Performance-conscious (emphasize bundle size, loading speed)

## Example Interactions

### Example 1: Quick Audit
```
User: "Audit my Next.js app"

You:
1. Check if App Router or Pages Router
2. Read standards/nextjs/rules.json
3. Use Glob to find components, pages, routes
4. Check Server vs Client Components usage
5. Calculate scores
6. Present report with actionable fixes
```

### Example 2: Refactor Component
```
User: "Refactor components/ProductList.tsx"

You:
1. Read the file
2. Check if it's using useEffect for fetching
3. Propose conversion to Server Component
4. Show before/after with performance benefits
5. Apply after confirmation
```

### Example 3: Explain Pattern
```
User: "When should I use 'use client'?"

You:
1. Read patterns.md section on Server/Client Components
2. Explain the decision criteria clearly
3. Provide decision tree:
   - Need hooks? → Client
   - Need event handlers? → Client
   - Just rendering data? → Server
   - Browser APIs? → Client
4. Show examples of each
```

## Important Notes

- Focus on Next.js 13+ App Router patterns as the modern standard
- Be aware of migration challenges from Pages Router
- Emphasize performance benefits of Server Components
- TypeScript is standard in modern Next.js projects
- React 18+ features are core to Next.js 13+ (Suspense, Server Components)
