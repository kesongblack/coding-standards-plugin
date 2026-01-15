---
name: refactor
description: Apply coding standards fixes to specific files
allowed_tools: [Read, Edit, Glob, Grep]
---

# Refactor Command

Apply coding standards fixes to specific files or directories.

## Usage

```
/refactor [file]           # Refactor a specific file
/refactor [directory]      # Refactor all files in directory
/refactor --dry-run [file] # Preview changes without applying
/refactor --all            # Refactor all files with violations (use with caution)
```

## Behavior

### 1. Identify Target

- If file path provided: Target that specific file
- If directory provided: Target all relevant files in directory
- If `--all` flag: Target all files with known violations from last audit

### 2. Detect Language

Determine language from:
- File extension (.php → Laravel, .tsx/.ts → Next.js, .dart → Flutter)
- Project context (composer.json, package.json, pubspec.yaml)
- Explicit flag if ambiguous

### 3. Load Applicable Standards

Read from `standards/[language]/`:
- `rules.json` - Rules to apply
- `naming.md` - Naming conventions
- `patterns.md` - Pattern guidelines

### 4. Analyze File

For the target file(s):
- Identify current violations
- Determine safe automated fixes
- Flag changes requiring manual review

### 5. Apply Fixes

**Automated fixes (safe):**
- Rename methods/variables to match conventions
- Reorder imports/use statements
- Add missing type hints
- Format code structure

**Manual review required:**
- Architectural changes
- Logic modifications
- Breaking changes to public APIs

### 6. Report Changes

```
📝 Refactoring: UserController.php
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Applied Changes:
  ✓ Renamed getData() → getUserData() (naming.methods)
  ✓ Added return type hint to index() (patterns.type-hints)
  ✓ Reordered use statements (structure.imports)

Manual Review Needed:
  ⚠ Line 45: Consider extracting to service class (patterns.controllers)
  ⚠ Line 78: Missing validation for user input (security.validation)

Summary: 3 fixes applied, 2 items need manual review
```

## Implementation

```
Parse arguments:
  Extract file/directory path
  Check for --dry-run flag
  Check for --all flag

Validate target exists:
  If file: Verify file exists
  If directory: Verify directory exists
  If --all: Require prior audit results

Detect language from file/project

Read target file(s)

For each file:
  Load standards for language
  Identify violations
  Categorize as auto-fixable or manual

If --dry-run:
  Display proposed changes
  Exit without modifying

Apply auto-fixable changes:
  Use Edit tool for each change
  Track what was modified

Report results:
  List applied changes
  List items needing manual review
  Show before/after for significant changes
```

## Auto-Fixable vs Manual Review

| Auto-Fixable | Manual Review |
|--------------|---------------|
| Method/variable renaming | Architectural refactoring |
| Import ordering | Logic changes |
| Type hint additions | API signature changes |
| Whitespace/formatting | Security-critical code |
| Comment formatting | Database queries |

## Safety Measures

1. **Read file first** - Always read before editing
2. **Single file at a time** - Don't batch edit without confirmation
3. **Preserve functionality** - Never change logic without review
4. **Create backup context** - Note original state for rollback
5. **Dry-run default for --all** - Require explicit confirmation

## Notes

- Works best after running `/audit` to identify violations
- Use `--dry-run` to preview changes before applying
- Complex refactors may require multiple passes
- Always verify functionality after refactoring
