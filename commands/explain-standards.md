---
name: explain-standards
description: Explain why a coding standard exists and its benefits
allowed_tools: [Read, Glob]
---

# Explain Standards Command

Explain the reasoning behind a specific coding standard, rule, or convention.

## Usage

```
/explain-standards [topic]           # Explain a topic or rule
/explain-standards [rule-id]         # Explain a specific rule by ID
/explain-standards naming.controllers # Explain controller naming standards
/explain-standards patterns.services  # Explain service pattern standards
```

## Behavior

### 1. Parse Topic

Accept various formats:
- Rule ID: `naming.controllers`, `patterns.services`
- Topic keyword: `controllers`, `services`, `testing`
- Question: "why singular controller names"

### 2. Identify Language Context

- Use current project type if detected
- If ambiguous, explain across all relevant languages
- Allow explicit language: `/explain-standards laravel:naming.controllers`

### 3. Find Relevant Documentation

Search in order:
1. `standards/[language]/rules.json` - Find rule definition
2. `standards/[language]/naming.md` - Naming explanations
3. `standards/[language]/patterns.md` - Pattern explanations

### 4. Generate Explanation

Provide comprehensive explanation including:
- **What**: The rule/standard itself
- **Why**: Reasoning and benefits
- **Examples**: Good and bad examples
- **Exceptions**: When it might not apply
- **References**: Links to official documentation

## Output Format

```
📖 Standard: Controller Naming (naming.controllers)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Rule: Controllers must use singular PascalCase with 'Controller' suffix

Why This Matters:
  • Follows Laravel's PSR-4 autoloading conventions
  • Singular names represent a single resource type
  • Consistent naming improves codebase navigation
  • Matches Laravel's resource controller expectations

Good Examples:
  ✓ UserController
  ✓ OrderController
  ✓ ProductCategoryController

Bad Examples:
  ✗ UsersController (plural)
  ✗ userController (camelCase)
  ✗ User (missing suffix)

Exceptions:
  • Invokable controllers may omit suffix if single-action
  • API versioned controllers may include version: UserV2Controller

References:
  • Laravel Docs: https://laravel.com/docs/controllers
  • PSR-4 Standard: https://www.php-fig.org/psr/psr-4/
```

## Implementation

```
Parse input:
  Extract topic/rule-id
  Check for language prefix (laravel:, nextjs:, flutter:)

Determine language:
  If prefix: Use specified language
  If project detected: Use project language
  Else: Search all languages

Search for topic:
  Check rules.json for matching rule ID
  Search naming.md for topic keywords
  Search patterns.md for topic keywords

If found:
  Read relevant sections
  Format explanation with:
    - Rule definition
    - Reasoning (### Why? sections)
    - Examples (Good/Bad sections)
    - Exceptions if documented

If not found:
  Suggest similar topics
  Offer to search documentation
```

## Searchable Topics

### Laravel
- naming.controllers, naming.models, naming.services
- patterns.repository, patterns.service, patterns.action
- structure.directories, structure.namespaces
- testing.unit, testing.feature
- security.validation, security.authorization

### Next.js
- naming.components, naming.hooks, naming.pages
- patterns.server-components, patterns.client-components
- structure.app-router, structure.api-routes
- testing.unit, testing.integration
- security.api, security.auth

### Flutter
- naming.widgets, naming.blocs, naming.models
- patterns.bloc, patterns.provider, patterns.repository
- structure.features, structure.core
- testing.widget, testing.unit
- security.storage, security.api

## Notes

- Works without prior audit
- Great for onboarding new team members
- Use to understand audit violation reasons
- Can be invoked from audit report (rule IDs link to explanations)
