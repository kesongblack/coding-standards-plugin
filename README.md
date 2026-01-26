# Coding Standards Plugin

A comprehensive, multi-language coding standards system for Claude Code that automatically detects project types and enforces best practices across Laravel, Next.js, Flutter, and Python projects.

## Features

- **Auto-Detection**: Automatically detects project type on session start
- **Multi-Language Support**: Laravel (PHP), Next.js (React/TypeScript), Flutter (Dart), Python (Django/FastAPI/Data Science)
- **Automated Audits**: Quick scans on session start, full audits on demand
- **Interactive Commands**: `/audit`, `/refactor`, `/standards`, and more
- **Version Controlled Standards**: Git-based for team sharing and customization
- **Intelligent Review**: Built-in standards reviewer agent for proposed changes

## Installation

### Quick Install

```bash
# Clone to projects folder
git clone https://github.com/kesongblack/coding-standards-plugin.git ~/projects/coding-standards-plugin

# Run installer (creates symlink to ~/.claude/plugins/)
~/projects/coding-standards-plugin/scripts/install.sh

# Restart Claude Code or start a new session
```

### Manual Install

```bash
# Clone repository
git clone https://github.com/kesongblack/coding-standards-plugin.git ~/projects/coding-standards-plugin

# Create symlink
ln -s ~/projects/coding-standards-plugin ~/.claude/plugins/coding-standards

# Restart Claude Code
```

## First-Time Setup

On first run, you'll be prompted to select which languages to enable:

```
Which language standards would you like to enable?
[ ] Laravel (PHP)
[ ] Next.js (React/TypeScript)
[ ] Flutter (Dart)
[ ] Python (Django/FastAPI/Data Science)
```

Or run manually:

```bash
/standards setup
```

## Usage

### Commands

| Command | Description |
|---------|-------------|
| `/standards setup` | First-time setup: choose enabled languages |
| `/standards languages` | View/modify enabled languages |
| `/audit` | Run full codebase audit |
| `/audit --quick` | Run quick audit (sample files) |
| `/refactor [file]` | Apply standards to specific file |
| `/standards` | View/manage current standards |
| `/explain-standards [topic]` | Explain why a standard exists |

### Language Management

```bash
# View current selection
/standards languages

# Add a language
/standards languages add flutter

# Remove a language
/standards languages remove nextjs

# Set multiple languages
/standards languages set laravel,flutter
```

### Auto-Audit on Session Start

When you open a supported project, the plugin automatically:
1. Detects project type (Laravel/Next.js/Flutter/Python)
2. For Python projects, detects frameworks (Django, FastAPI, Data Science)
3. Runs a quick audit
4. Displays summary: "📋 [Language] project | Score: X/100 | N issues found"

**Python framework detection:**
- Django: Detected from `requirements.txt` or `pyproject.toml`
- FastAPI: Detected from `fastapi` or `uvicorn` dependencies
- Data Science: Detected from `jupyter`, `pandas`, `numpy`, `scikit-learn`, `tensorflow`

Example output: `📋 Python project (Django, FastAPI) detected`

## Configuration

### Global Configuration

Configuration is stored in `~/projects/coding-standards-plugin/.local/config.json`:

```json
{
  "enabledLanguages": ["laravel", "nextjs", "python"],
  "mode": "global",
  "strictness": "advisory",
  "autoAuditOnStart": true,
  "overridesPath": ".claude/standards-overrides.json"
}
```

### Project Overrides

Create `.claude/standards-overrides.json` in your project root:

```json
{
  "extends": "laravel",
  "overrides": {
    "naming.controllers": {
      "pattern": ".*Controller$",
      "severity": "warning"
    }
  }
}
```

## Standards Categories

Each language includes standards for:

- **Naming**: Classes, methods, variables, files
- **File Structure**: Directory organization, file placement
- **Patterns**: Design patterns, best practices
- **Testing**: Test structure, coverage requirements
- **Security**: Common vulnerabilities, secure coding practices

### Python Standards

Python standards follow PEP 8 and include framework-specific best practices:

**Core Standards:**
- **Naming (PEP 8)**: snake_case functions, PascalCase classes, UPPER_SNAKE_CASE constants
- **Type Hints**: Modern Python 3.9+ type annotations
- **Patterns**: Context managers, f-strings, pathlib, list comprehensions
- **Testing**: pytest, 70% minimum coverage, 100% for critical paths
- **Security**: No hardcoded secrets, parameterized queries, input validation

**Django-Specific:**
- Model naming (singular PascalCase)
- ORM optimization (select_related, prefetch_related)
- Class-based views
- CSRF protection, DEBUG=False in production
- Proper signals usage

**FastAPI-Specific:**
- Async/await for I/O operations
- Pydantic models for validation
- Dependency injection patterns
- CORS configuration (no wildcards)
- OAuth2/JWT authentication

**Data Science-Specific:**
- Vectorization over iteration (pandas/NumPy)
- No DataFrame.iterrows() usage
- Reproducible random seeds
- Pipeline patterns for transformations
- Pickle safety (avoid with untrusted data)

**Production Readiness:**
- Use logging module (not print statements)
- Environment variables for configuration
- Error handling for external services
- Health check endpoints

## Updating Standards

```bash
# Pull latest standards from repository
cd ~/projects/coding-standards-plugin && git pull

# Switch to team's fork
git remote add team https://github.com/my-team/coding-standards-plugin.git
git fetch team && git checkout team/main
```

## Contributing

### Proposing New Standards

1. Create a feature branch: `git checkout -b feat/laravel/new-standard`
2. Modify standards files in `standards/[language]/`
3. Test with sample project: `/audit --test tests/[language]-sample`
4. Commit: `git commit -m "feat(laravel): add new standard"`
5. Create PR: `gh pr create --title "Add new standard for Laravel"`

### Standards Review Process

The plugin includes a built-in `standards-reviewer` agent that evaluates:
- Industry best practices alignment
- Conflicts with existing standards
- Anti-pattern detection
- Team onboarding impact
- Performance/maintainability considerations

## Repository Structure

```
coding-standards-plugin/
├── .claude-plugin/          # Plugin metadata
├── hooks/                   # SessionStart automation
├── commands/                # User-invocable commands
├── skills/                  # Language-specific knowledge
├── agents/                  # Review agents
├── scripts/                 # Automation scripts
├── standards/               # Standards definitions
│   ├── laravel/
│   ├── nextjs/
│   ├── flutter/
│   └── python/              # PEP 8, Django, FastAPI, Data Science
│       ├── frameworks/      # Framework-specific standards
│       │   ├── django.md
│       │   ├── fastapi.md
│       │   └── datascience.md
└── tests/                   # Test fixtures
```

## CI/CD Integration

The plugin includes GitHub Actions workflows for automated standards enforcement.

### Setup

1. Copy the config template to your project:
   ```bash
   cp ~/projects/coding-standards-plugin/.github/coding-standards-config.yml .github/
   ```

2. Copy the workflows:
   ```bash
   mkdir -p .github/workflows
   cp ~/projects/coding-standards-plugin/.github/workflows/*.yml .github/workflows/
   ```

### PR Audit

Automatically runs on every pull request:
- Detects project type
- Runs quick audit
- Posts results as PR comment
- Blocks merge if score below threshold

Configure in `.github/coding-standards-config.yml`:
```yaml
pr_audit:
  enabled: true
  threshold: 70
  mode: "quick"
  fail_on_threshold: true
```

### Scheduled Audit

Runs on a schedule (default: Monday 9am UTC) with two modes:

**Notification mode** (default, zero tokens):
```yaml
scheduled_audit:
  mode: "notification"
  cron: "0 9 * * 1"
```
Creates a reminder issue without running the actual audit.

**Full audit mode**:
```yaml
scheduled_audit:
  mode: "full-audit"
  threshold: 70
  create_issue_on_failure: true
```
Runs actual audit and creates issue if score drops below threshold.

### Release Workflow

Triggered when you push a version tag:
```bash
git tag v1.1.0
git push origin v1.1.0
```

Automatically:
- Validates all standards JSON files
- Creates GitHub release with changelog

### Production Audit

Runs production safety checks before deployment:
- Triggers on pushes to `production` or `release/*` branches
- Can be run manually via workflow dispatch
- Checks for debug settings, exposed secrets, debug functions

Configure in `.github/coding-standards-config.yml`:
```yaml
production_audit:
  enabled: true
  fail_on_error: true      # Block deploy on errors
  fail_on_warning: false   # Optionally block on warnings
  branches: ["production", "release/*"]
```

**Checks by framework:**

| Laravel | Next.js | Flutter | Python |
|---------|---------|---------|--------|
| APP_DEBUG=false | No console.log | Debug banner disabled | DEBUG=False (Django) |
| .env not exposed | Env vars set | No print statements | No hardcoded secrets |
| No seeders in routes | Build optimized | Release signing configured | Logging (not print) |
| No dd/dump calls | No dev-only code | kDebugMode checks | Env variables configured |

## Scripts

| Script | Description |
|--------|-------------|
| `scripts/install.sh` | Creates symlink to Claude Code plugins directory |
| `scripts/detect-project.sh` | Detects project type (Laravel/Next.js/Flutter/Python) and Python frameworks |
| `scripts/validate-standards.sh` | Validates rules.json schema and syntax |

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

For issues, feature requests, or contributions:
- GitHub Issues: https://github.com/kesongblack/coding-standards-plugin/issues
- Documentation: See this README and inline documentation in standards files

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes.
