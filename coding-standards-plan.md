# Enhanced Coding Standards Agent System - Implementation Plan

## Executive Summary

Build a global, multi-language coding standards system leveraging Claude Code's native plugin architecture: **skills** for knowledge/patterns, **hooks** for automation, **commands** for user interaction, and optionally **MCP** for external tool integration.

---

## Architecture Decision: Git-Based Plugin

**Why Git-based?**
- ✅ Version control for standards changes (track who changed what, when)
- ✅ Shareable across teams via `git clone`
- ✅ Installable on any machine with a single command
- ✅ Fork-friendly for customization
- ✅ CI/CD integration possible (lint standards, run tests)
- ✅ Easy rollback via git history

**Local Repository Location:** `~/projects/coding-standards-plugin`

**Installation:**
```bash
# Clone to projects folder
git clone https://github.com/kesongblack/coding-standards-plugin.git ~/projects/coding-standards-plugin

# Symlink into Claude Code plugins directory
ln -s ~/projects/coding-standards-plugin ~/.claude/plugins/coding-standards

# Or install via Claude Code (if published to marketplace)
# /plugin install coding-standards@your-marketplace
```

**Why Plugin Architecture (Not Custom Agent)?**

Claude Code already provides agent-like capabilities through its plugin system:
- **Skills** = Knowledge base (standards, patterns, best practices)
- **Hooks** = Automation triggers (SessionStart for project detection)
- **Commands** = User-invocable actions (`/audit`, `/refactor`, `/standards`)
- **Agents** = Autonomous subprocesses for complex multi-step workflows

---

## Repository Structure

```
coding-standards-plugin/              # Git repository root
├── .git/                             # Git version control
├── .gitignore                        # Ignore local config, user overrides
├── README.md                         # Setup instructions, usage guide
├── LICENSE                           # Open source license
├── CHANGELOG.md                      # Version history for releases
│
├── .claude-plugin/
│   └── plugin.json              # Plugin metadata
├── hooks/
│   └── hooks.json               # SessionStart for auto-detection
├── commands/
│   ├── audit.md                 # /audit command
│   ├── refactor.md              # /refactor command
│   ├── standards.md             # /standards view/update
│   └── explain-standards.md     # /explain-standards
├── skills/
│   ├── coding-standards-core/
│   │   └── SKILL.md             # Core orchestration logic
│   ├── laravel-standards/
│   │   ├── SKILL.md             # Laravel-specific standards
│   │   └── references/
│   │       └── patterns.md      # Heavy documentation
│   ├── nextjs-standards/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── patterns.md
│   └── flutter-standards/
│       ├── SKILL.md
│       └── references/
│           └── patterns.md
├── agents/
│   └── standards-reviewer.md    # Review agent for proposed changes
├── scripts/
│   ├── detect-project.sh        # Project type detection
│   ├── validate-standards.sh    # Standards validation
│   └── install.sh               # Installation helper script
├── standards/                   # Base standards (version controlled)
│   ├── laravel/
│   │   ├── rules.json
│   │   ├── naming.md
│   │   └── patterns.md
│   ├── nextjs/
│   │   ├── rules.json
│   │   ├── naming.md
│   │   └── patterns.md
│   └── flutter/
│       ├── rules.json
│       ├── naming.md
│       └── patterns.md
├── .local/                      # .gitignore'd - user-specific
│   ├── config.json              # Local configuration overrides
│   └── history/                 # Local change history
│       └── *.json
└── tests/                       # Test fixtures
    ├── laravel-sample/
    ├── nextjs-sample/
    └── flutter-sample/
```

---

## Component Specifications

### 1. SessionStart Hook (Auto-Detection)

**File:** `hooks/hooks.json`

```json
{
  "description": "Coding Standards - Auto-detect project and load standards",
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/detect-project.sh"
          }
        ]
      }
    ]
  }
}
```

**Detection Script Logic:**
1. Load enabled languages from `.local/config.json`
2. If no config exists, prompt user to run `/standards setup`
3. Check for `composer.json` → Laravel (if enabled)
4. Check for `package.json` with Next.js → Next.js (if enabled)
5. Check for `pubspec.yaml` → Flutter (if enabled)
6. Set `$PROJECT_TYPE` in `$CLAUDE_ENV_FILE`
7. Output brief status message (or skip if language not enabled)

### 2. Core Skills

#### coding-standards-core (Orchestration)

```yaml
---
name: coding-standards-core
description: Use when auditing code, applying standards, or refactoring for compliance
---
```

**Responsibilities:**
- Route to language-specific skill based on detected project type
- Coordinate audit → refactor → apply workflow
- Handle "fix vs explain" decision based on user prompt

#### Language-Specific Skills (laravel/nextjs/flutter-standards)

Each skill contains:
- **Trigger description**: "Use when working with [Laravel/Next.js/Flutter] projects"
- **Standards categories**: Naming, file structure, patterns, testing, security
- **Scoring rubrics**: 1-10 scale per category (like existing laravel-audit)
- **Quick reference**: Common patterns, anti-patterns
- **references/**: Heavy documentation (>100 lines)

### 3. Commands

| Command | Purpose | Tools Allowed |
|---------|---------|---------------|
| `/standards setup` | First-time setup: choose enabled languages | Read, Write |
| `/standards languages` | View/modify enabled languages | Read, Write |
| `/audit` | Run codebase audit (enabled languages only) | Read, Glob, Grep |
| `/refactor [file]` | Apply standards to specific file | Read, Edit |
| `/standards` | View/manage current standards | Read, Write |
| `/explain-standards [topic]` | Explain why a standard exists | Read |

**Setup Flow:**
```
User runs /standards setup (or first SessionStart)
    │
    ▼
Prompt: "Which languages do you want to enable?"
    │
    ▼
User selects: [x] Laravel  [x] Flutter  [ ] Next.js
    │
    ▼
Save to .local/config.json
    │
    ▼
"✓ Enabled: Laravel, Flutter. Run /audit to check your project."
```

### 4. Standards Reviewer Agent

**File:** `agents/standards-reviewer.md`

```yaml
---
name: standards-reviewer
description: Use when user proposes new standards or modifications
model: sonnet
tools: ["Read", "Grep", "WebSearch"]
---
```

**Review Criteria:**
- Industry best practices alignment
- Conflicts with existing standards
- Anti-pattern detection
- Team onboarding impact
- Performance/maintainability considerations

### 5. Persistent Standards Storage

**Format:** Hybrid (JSON for rules + Markdown for explanations)

```
standards/
├── laravel/
│   ├── rules.json           # Machine-readable rules
│   ├── naming.md            # Human-readable explanations
│   ├── patterns.md          # Code examples and anti-patterns
│   └── history.json         # Version history
├── nextjs/
│   ├── rules.json
│   ├── naming.md
│   ├── patterns.md
│   └── history.json
└── flutter/
    ├── rules.json
    ├── naming.md
    ├── patterns.md
    └── history.json
```

**rules.json structure:**
```json
{
  "version": "1.0.0",
  "language": "laravel",
  "lastUpdated": "2024-01-14T10:00:00Z",
  "categories": {
    "naming": {
      "rules": [
        {
          "id": "controller-suffix",
          "pattern": ".*Controller$",
          "severity": "error",
          "message": "Controllers must end with 'Controller'",
          "docs": "naming.md#controllers"
        }
      ]
    }
  }
}
```

**naming.md structure:**
```markdown
# Naming Standards

## Controllers

Controllers should use singular PascalCase with `Controller` suffix.

**Good:**
- `UserController`
- `OrderController`

**Bad:**
- `UsersController` (plural)
- `userController` (camelCase)

### Why?
Laravel convention for PSR-4 autoloading...
```

---

## Workflow Diagrams

### Project Detection Flow (Always Audit)

```
SessionStart
    │
    ▼
detect-project.sh
    │
    ├─► Laravel detected → Set PROJECT_TYPE=laravel → Run quick audit
    ├─► Next.js detected → Set PROJECT_TYPE=nextjs → Run quick audit
    ├─► Flutter detected → Set PROJECT_TYPE=flutter → Run quick audit
    └─► Unknown → Display "Unsupported project type"
    │
    ▼
Display summary: "📋 [Language] project | Score: X/100 | N issues found"
```

**Note:** Auto-audit runs on every detected project. For large codebases, the initial audit is a "quick scan" (sampling key files). Full audit available via `/audit --full`.

### Audit Workflow

```
/audit command
    │
    ▼
coding-standards-core skill triggered
    │
    ▼
Route to language-specific skill
    │
    ▼
Analyze codebase against standards
    │
    ▼
Generate scored report (per category)
    │
    ▼
Identify violations with:
  - Location (file:line)
  - Severity
  - Suggested fix
  - Explanation
```

### Standards Update Workflow

```
User proposes standard update
    │
    ▼
/standards update [category] [rule]
    │
    ▼
standards-reviewer agent evaluates:
  ├─ Industry alignment?
  ├─ Conflicts with existing?
  ├─ Anti-patterns?
  └─ Practical concerns?
    │
    ▼
Present findings to user
    │
    ▼
User approves/modifies/rejects
    │
    ▼
If approved:
  ├─ Update standards JSON
  ├─ Record in history
  └─ Apply globally going forward
```

---

## Implementation Phases

### Phase 1: Repository Setup
- [ ] Create `~/projects/` directory if not exists
- [ ] Initialize git repository at `~/projects/coding-standards-plugin/`
- [ ] Create `README.md` with installation instructions
- [ ] Create `LICENSE` (MIT)
- [ ] Create `.gitignore` (exclude .local/, IDE files)
- [ ] Create `CHANGELOG.md`

### Phase 2: Plugin Foundation
- [ ] Create `.claude-plugin/plugin.json` metadata
- [ ] Create `scripts/install.sh` (symlinks to ~/.claude/plugins/)
- [ ] Create `scripts/detect-project.sh` with Laravel/Next.js/Flutter detection
- [ ] Set up `hooks/hooks.json` for SessionStart with always-audit behavior

### Phase 3: Standards Content (All Languages in Parallel)
- [ ] Create `standards/laravel/rules.json` + `*.md` documentation
- [ ] Create `standards/nextjs/rules.json` + `*.md` documentation
- [ ] Create `standards/flutter/rules.json` + `*.md` documentation
- [ ] Define common categories across all: naming, structure, patterns, testing, security

### Phase 4: Core Skills (All Languages in Parallel)
- [ ] Create `coding-standards-core` skill (orchestration/routing)
- [ ] Create `laravel-standards` skill (builds on existing laravel-audit)
- [ ] Create `nextjs-standards` skill
- [ ] Create `flutter-standards` skill

### Phase 5: Commands
- [ ] Implement `/standards setup` command (language selection prompt)
- [ ] Implement `/standards languages` subcommand (add/remove/set)
- [ ] Implement `/audit` command with `--full` and `--quick` flags
- [ ] Implement `/refactor` command for applying fixes
- [ ] Implement `/standards` command for viewing/updating
- [ ] Implement `/explain-standards` command for explanations

### Phase 6: Review System
- [ ] Create `standards-reviewer` agent
- [ ] Implement review criteria (industry alignment, conflicts, anti-patterns)
- [ ] Add conflict detection between proposed and existing standards
- [ ] Implement approval → persist → apply workflow

### Phase 7: Testing & Documentation
- [ ] Create `tests/laravel-sample/` fixture project
- [ ] Create `tests/nextjs-sample/` fixture project
- [ ] Create `tests/flutter-sample/` fixture project
- [ ] Test installation script on clean system
- [ ] Test cross-project workflow (switching between project types)
- [ ] Finalize README.md with complete documentation

### Phase 8: Release
- [ ] Create initial git commit with all files
- [ ] Tag v1.0.0 release
- [ ] Push to GitHub
- [ ] (Optional) Submit to Claude Code plugin marketplace

---

## Configuration Options

### Language Selection

Users can choose which language standards to enable (one or multiple):

**First-time setup prompt (via `/standards setup` or on first run):**
```
Which language standards would you like to enable?
[ ] Laravel (PHP)
[ ] Next.js (React/TypeScript)
[ ] Flutter (Dart)

Select one or more, then confirm.
```

**Configuration file:**
```json
// ~/projects/coding-standards-plugin/.local/config.json
{
  "enabledLanguages": ["laravel", "nextjs"],  // User's selection
  "mode": "global",           // "global" | "project"
  "strictness": "advisory",   // "strict" | "advisory"
  "autoAuditOnStart": true,
  "overridesPath": ".claude/standards-overrides.json"
}
```

**Changing selection later:**
```bash
# Via command
/standards languages          # Show current selection
/standards languages add flutter
/standards languages remove nextjs
/standards languages set laravel,flutter

# Or edit config directly
nano ~/projects/coding-standards-plugin/.local/config.json
```

### Global vs Project-Specific

### Project Overrides

```json
// .claude/standards-overrides.json (in project root)
{
  "extends": "laravel",
  "overrides": {
    "naming.controllers": {
      "pattern": ".*Controller$",
      "severity": "warning"  // Downgrade from error
    }
  }
}
```

---

## Git Workflow

### For Users (Installing/Updating)

```bash
# Initial install
git clone https://github.com/your-org/coding-standards-plugin.git ~/projects/coding-standards-plugin
~/projects/coding-standards-plugin/scripts/install.sh

# Update to latest standards
cd ~/projects/coding-standards-plugin && git pull

# Switch to team's fork
git remote add team https://github.com/my-team/coding-standards-plugin.git
git fetch team && git checkout team/main
```

### For Contributors (Modifying Standards)

```bash
# Create feature branch for new standard
git checkout -b feat/add-api-versioning-standard

# Make changes to standards/laravel/rules.json, etc.
# Test with sample project
/audit --test tests/laravel-sample

# Commit with conventional commits
git commit -m "feat(laravel): add API versioning standard"

# Create PR for review
gh pr create --title "Add API versioning standard for Laravel"
```

### Standards Update Flow (with Git)

```
User proposes standard change
    │
    ▼
Create branch: feat/[language]/[change-name]
    │
    ▼
Modify standards/*.json and *.md files
    │
    ▼
standards-reviewer agent evaluates changes
    │
    ▼
Commit changes locally
    │
    ▼
Push to remote (personal fork or team repo)
    │
    ▼
Create PR for team review (optional)
    │
    ▼
Merge → Available to all users on next `git pull`
```

### .gitignore Contents

```gitignore
# User-specific files (not shared)
.local/
*.local.json

# IDE files
.vscode/
.idea/

# OS files
.DS_Store
Thumbs.db

# Test outputs
tests/**/output/
```

---

## Verification Plan

1. **Unit Testing**
   - Project detection script correctly identifies all supported languages
   - Standards JSON schema validates correctly
   - Version history records changes properly

2. **Integration Testing**
   - SessionStart hook triggers on new project
   - Commands invoke correct skills
   - Reviewer agent provides meaningful feedback

3. **End-to-End Testing**
   - Full workflow: new project → auto-detect → audit → refactor → verify
   - Standards update: propose → review → approve → persist

---

## Key Differences from Original Plan

| Original | Enhanced |
|----------|----------|
| Custom "agent tools" | Native Claude Code components (skills, hooks, commands, agents) |
| Abstract architecture | Concrete file structure and implementations |
| Generic storage | JSON with versioning + history directory |
| Undefined "review_standard_suggestion" | Dedicated `standards-reviewer` agent with specific criteria |
| Unclear detection | SessionStart hook with `detect-project.sh` |
| No UI/UX | Slash commands for user interaction |

---

## Files to Create

### Repository Root (Git)
1. `README.md` - Setup instructions, usage guide
2. `LICENSE` - Open source license (MIT recommended)
3. `CHANGELOG.md` - Version history for releases
4. `.gitignore` - Ignore .local/, IDE files, OS files

### Plugin Infrastructure
5. `.claude-plugin/plugin.json` - Plugin metadata
6. `hooks/hooks.json` - SessionStart hook config

### Scripts
7. `scripts/detect-project.sh` - Project detection logic
8. `scripts/validate-standards.sh` - Validate JSON schemas
9. `scripts/install.sh` - One-command installation helper

### Skills (4 total)
10. `skills/coding-standards-core/SKILL.md` - Orchestration
11. `skills/laravel-standards/SKILL.md` - Laravel standards
12. `skills/nextjs-standards/SKILL.md` - Next.js standards
13. `skills/flutter-standards/SKILL.md` - Flutter standards

### Commands (5 total)
14. `commands/standards-setup.md` - `/standards setup` first-time language selection
15. `commands/audit.md` - `/audit` command
16. `commands/refactor.md` - `/refactor` command
17. `commands/standards.md` - `/standards` command (includes `languages` subcommand)
18. `commands/explain-standards.md` - `/explain-standards` command

### Agents (1 total)
19. `agents/standards-reviewer.md` - Review proposed changes

### Standards Storage (Hybrid format per language)
20. `standards/laravel/rules.json` - Laravel rules
21. `standards/laravel/naming.md` - Laravel naming docs
22. `standards/laravel/patterns.md` - Laravel patterns docs
23. `standards/nextjs/rules.json` - Next.js rules
24. `standards/nextjs/naming.md` - Next.js naming docs
25. `standards/nextjs/patterns.md` - Next.js patterns docs
26. `standards/flutter/rules.json` - Flutter rules
27. `standards/flutter/naming.md` - Flutter naming docs
28. `standards/flutter/patterns.md` - Flutter patterns docs

### Test Fixtures
29. `tests/laravel-sample/` - Sample Laravel project for testing
30. `tests/nextjs-sample/` - Sample Next.js project for testing
31. `tests/flutter-sample/` - Sample Flutter project for testing

**Total: 31 files/directories**

---

## Quick Start (After Implementation)

```bash
# 1. Clone the repository to your projects folder
git clone https://github.com/your-org/coding-standards-plugin.git ~/projects/coding-standards-plugin

# 2. Run installer (creates symlink to ~/.claude/plugins/)
~/projects/coding-standards-plugin/scripts/install.sh

# 3. Restart Claude Code or start new session
# 4. Open any Laravel/Next.js/Flutter project
# 5. See auto-audit summary on session start!
```
