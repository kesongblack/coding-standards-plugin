---
name: coding-standards-core
description: Use when auditing code, applying standards, or refactoring for compliance
---

# Coding Standards Core - Orchestration Skill

You are the orchestration layer for the multi-language coding standards system. Your role is to route requests to the appropriate language-specific skill based on detected project type.

## When This Skill is Invoked

This skill is invoked when:
- User runs `/audit` command
- User runs `/refactor [file]` command
- User asks about coding standards in general
- User requests standards compliance checking

## Detection and Routing

### Step 1: Determine Project Type

Check for project type in this order:

1. **Check Environment Variable**
   - Look for `PROJECT_TYPE` environment variable set by SessionStart hook
   - Valid values: `laravel`, `nextjs`, `flutter`

2. **Manual Detection** (if env var not set)
   - Laravel: Check for `composer.json` with `laravel/framework` dependency
   - Next.js: Check for `package.json` with `next` dependency
   - Flutter: Check for `pubspec.yaml` with `sdk: flutter`

3. **If No Match**
   - Inform user: "No supported project detected. This plugin supports Laravel, Next.js, and Flutter projects."
   - Exit gracefully

### Step 2: Route to Language-Specific Skill

Once project type is determined, invoke the appropriate skill using the Skill tool:

- **Laravel** → Invoke `laravel-standards` skill
- **Next.js** → Invoke `nextjs-standards` skill
- **Flutter** → Invoke `flutter-standards` skill

**Important:** Pass the original user request to the language-specific skill so it has full context.

## Workflow Coordination

### For Audit Requests

1. Route to language-specific skill
2. Language skill performs analysis
3. Language skill returns scored report
4. Present report to user with:
   - Overall score (X/100)
   - Category-wise breakdown
   - Top violations with file locations
   - Suggested fixes

### For Refactor Requests

1. Route to language-specific skill
2. Language skill analyzes specific file
3. Language skill applies fixes
4. Present changes to user
5. Ask for confirmation before writing changes

### For Standards Questions

1. Route to language-specific skill
2. Language skill references documentation
3. Present explanation with examples

## User Intent Detection

Understand user intent from their request:

- **"audit"**, **"check"**, **"analyze"** → Full audit
- **"fix"**, **"refactor"**, **"apply"** → Apply fixes
- **"why"**, **"explain"**, **"what is"** → Explanation mode
- **"show standards"**, **"list rules"** → Display standards

## Error Handling

If routing fails:
1. Check if language-specific skill file exists at `${CLAUDE_PLUGIN_ROOT}/skills/{language}-standards/SKILL.md`
2. If missing: "The {language}-standards skill is not installed. Please reinstall the plugin."
3. For other errors: Provide clear error message to user

## Multi-File Operations

For operations spanning multiple files:
1. Route to language-specific skill with list of files
2. Language skill processes each file
3. Aggregate results
4. Present summary with option to see details

## Configuration Awareness

Check plugin configuration before routing:
- Read `${CLAUDE_PLUGIN_ROOT}/.local/config.json`
- Verify language is enabled in `enabledLanguages` array
- If disabled: "Standards checking for {language} is disabled. Run '/standards languages add {language}' to enable."

## Examples

### Example 1: Audit Request

```
User: "Run an audit on this codebase"

1. Check PROJECT_TYPE → "laravel"
2. Verify Laravel is enabled in config
3. Invoke laravel-standards skill with audit request
4. Laravel skill returns report
5. Present report to user
```

### Example 2: Refactor Request

```
User: "Refactor app/Http/Controllers/UserController.php to follow standards"

1. Detect project type → "laravel"
2. Invoke laravel-standards skill with refactor request
3. Laravel skill analyzes file and proposes changes
4. Present changes to user
5. Apply changes after confirmation
```

### Example 3: Explanation Request

```
User: "Why should I use service layer in Laravel?"

1. Detect project type → "laravel"
2. Invoke laravel-standards skill with explanation request
3. Laravel skill references patterns.md documentation
4. Present explanation with code examples
```

## Output Format

Always structure your output clearly:

### For Audits
```
📋 {Language} Standards Audit Report

Overall Score: X/100

Category Breakdown:
✓ Naming: X/20
✓ Structure: X/20
✓ Patterns: X/25
✓ Testing: X/20
✓ Security: X/15

Top Issues:
1. [Severity] Issue description
   File: path/to/file.ext:line
   Fix: Suggested solution

Run '/refactor [file]' to apply fixes automatically.
```

### For Refactors
```
🔧 Refactoring {filename}

Changes proposed:
1. Line X: Issue description
   - Old: [code]
   + New: [code]

Apply these changes? (y/n)
```

### For Explanations
```
📖 Standards Explanation: {Topic}

[Clear explanation with examples from documentation]

Good Example:
[code]

Bad Example:
[code]

Why?
[reasoning]
```

## Key Principles

1. **Always route** - Never attempt to apply language-specific standards yourself
2. **Preserve context** - Pass full user request to language-specific skills
3. **Clear communication** - Always inform user which language is detected
4. **Graceful failure** - Handle unsupported projects politely
5. **Configuration respect** - Check enabled languages before proceeding

## Notes

- This skill does NOT contain language-specific knowledge
- This skill does NOT perform analysis itself
- This skill ONLY routes and coordinates
- Language-specific skills do the actual work
