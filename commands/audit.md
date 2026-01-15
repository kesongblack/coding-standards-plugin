---
name: audit
description: Run codebase audit against coding standards
allowed_tools: [Read, Glob, Grep, Task]
---

# Audit Command

Analyze codebase against coding standards and generate a scored report.

## Usage

```
/audit              # Run audit on current project (auto-detect language)
/audit --quick      # Quick scan (sample key files only)
/audit --full       # Full comprehensive audit
/audit --language X # Force specific language standards
```

## Behavior

### 1. Detect Project Type

If no `--language` flag:
- Check for `composer.json` → Laravel
- Check for `package.json` with `next` dependency → Next.js
- Check for `pubspec.yaml` → Flutter
- If none detected, prompt user to specify

### 2. Load Standards

Read standards from:
- `standards/[language]/rules.json` - Machine-readable rules
- `standards/[language]/naming.md` - Naming conventions
- `standards/[language]/patterns.md` - Code patterns

### 3. Run Audit

**Quick mode (default for SessionStart):**
- Sample key files: controllers, models, services, components
- Check naming conventions on sampled files
- Identify obvious pattern violations
- Fast execution for session start

**Full mode:**
- Scan all relevant files
- Check every rule in rules.json
- Deep analysis of patterns
- Generate comprehensive report

### 4. Generate Report

Produce scored report with categories:
- **Naming** (1-10): File/class/method naming compliance
- **Structure** (1-10): Directory and file organization
- **Patterns** (1-10): Adherence to design patterns
- **Testing** (1-10): Test coverage and quality
- **Security** (1-10): Security best practices

For each violation found:
- Location (file:line)
- Severity (error/warning/info)
- Rule ID
- Suggested fix
- Link to explanation

### 5. Output Summary

```
📋 [Language] Project Audit Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Overall Score: 78/100

Category Scores:
  Naming:    9/10
  Structure: 8/10
  Patterns:  7/10
  Testing:   6/10
  Security:  8/10

Issues Found: 12
  🔴 Errors:   2
  🟡 Warnings: 7
  🔵 Info:     3

Top Issues:
1. [ERROR] UserController.php:45 - Method 'getData' should be 'getUserData' (naming.methods)
2. [WARN] OrderService.php - Missing interface for service class (patterns.services)
...

Run `/refactor [file]` to fix issues or `/explain-standards [rule-id]` for details.
```

## Implementation

```
Parse flags:
  --quick: Set mode to "quick"
  --full: Set mode to "full"
  --language X: Set language, skip detection

If no language specified:
  Detect project type from manifest files

If language not enabled in config:
  Warn user and suggest /standards setup

Load language-specific skill:
  Invoke coding-standards-core skill
  Route to [language]-standards skill

Run audit based on mode:
  Quick: Sample ~10 key files
  Full: Scan all relevant directories

Collect violations:
  Match files against rules.json patterns
  Check naming conventions
  Identify anti-patterns

Calculate scores:
  Score each category 1-10
  Overall = weighted average

Generate and display report
```

## Categories

| Category | Weight | What it checks |
|----------|--------|----------------|
| Naming | 20% | File, class, method, variable naming |
| Structure | 20% | Directory layout, file organization |
| Patterns | 25% | Design patterns, architectural adherence |
| Testing | 15% | Test presence, coverage, quality |
| Security | 20% | Security best practices, vulnerabilities |

## Notes

- Quick mode is default for auto-audit on SessionStart
- Full mode recommended for PR reviews and releases
- Results can inform `/refactor` suggestions
- Use Task tool to spawn language-specific audit agent for large codebases
