# Python Standards Integration Design

**Date:** 2026-01-27
**Status:** Approved
**Scope:** Add Python language support with Django, FastAPI, and Data Science framework detection

## Overview

Add comprehensive Python coding standards to the plugin with automatic framework detection. The system will detect Python projects and identify which frameworks are in use (Django, FastAPI, Data Science tools), then apply relevant standards accordingly.

## 1. Project Detection & Framework Identification

### Detection Logic

Extend `scripts/detect-project.sh` to detect Python projects by checking for:
- `requirements.txt`
- `pyproject.toml`

### Framework Sub-Detection

Once Python is detected, identify active frameworks by analyzing dependencies:

```bash
detect_python_frameworks() {
    local frameworks=()

    # Check requirements.txt
    if [ -f "requirements.txt" ]; then
        grep -qi "django" requirements.txt && frameworks+=("django")
        grep -qi "fastapi\|uvicorn" requirements.txt && frameworks+=("fastapi")
        grep -qi "jupyter\|pandas\|scikit-learn\|tensorflow" requirements.txt && frameworks+=("datascience")
    fi

    # Check pyproject.toml
    if [ -f "pyproject.toml" ]; then
        grep -qi "django" pyproject.toml && frameworks+=("django")
        grep -qi "fastapi" pyproject.toml && frameworks+=("fastapi")
        grep -qi "jupyter\|pandas\|numpy" pyproject.toml && frameworks+=("datascience")
    fi

    echo "${frameworks[@]}"
}
```

### Detection Output

**Single framework:**
```
📋 Python project detected (Django)
   Coding standards monitoring active
   Run '/audit' for full analysis or '/standards' to configure
```

**Multiple frameworks:**
```
📋 Python project detected (Django, FastAPI)
   Coding standards monitoring active
   Run '/audit' for full analysis or '/standards' to configure
```

**Environment Variable:**
Store detected frameworks: `PYTHON_FRAMEWORKS=django,fastapi`

## 2. Standards File Structure

### Directory Layout

```
standards/python/
├── rules.json              # Main rules with framework filters
├── naming.md              # PEP 8 naming conventions
├── patterns.md            # Python best practices
├── testing.md             # pytest, coverage requirements
├── security.md            # OWASP, injection prevention
├── folder-structure.md    # Package organization
├── production.md          # Production readiness
├── frameworks/
│   ├── django.md         # Django-specific patterns
│   ├── fastapi.md        # FastAPI-specific patterns
│   └── datascience.md    # Jupyter, pandas best practices
```

### Rules.json Schema

```json
{
  "version": "1.0.0",
  "language": "python",
  "lastUpdated": "2026-01-27T00:00:00Z",
  "categories": {
    "naming": {
      "weight": 20,
      "rules": [
        {
          "id": "class-naming",
          "pattern": "^[A-Z][a-zA-Z0-9]*$",
          "severity": "error",
          "message": "Classes must use PascalCase (PEP 8)",
          "docs": "naming.md#classes",
          "frameworks": ["*"]
        },
        {
          "id": "django-model-naming",
          "pattern": "^[A-Z][a-zA-Z0-9]*$",
          "filePattern": ".*/models\\.py$",
          "severity": "error",
          "message": "Django models must use singular PascalCase",
          "docs": "frameworks/django.md#models",
          "frameworks": ["django"]
        }
      ]
    },
    "structure": { "weight": 20 },
    "patterns": { "weight": 25 },
    "testing": { "weight": 20 },
    "security": { "weight": 15 }
  }
}
```

### Framework Filtering

Each rule includes a `frameworks` field:
- `["*"]` - Applies to all Python projects
- `["django"]` - Django-specific only
- `["fastapi"]` - FastAPI-specific only
- `["datascience"]` - Data Science projects only
- `["django", "fastapi"]` - Multiple frameworks

During audit, only rules matching detected frameworks are evaluated.

## 3. Core Python Standards

### Naming (20 points) - PEP 8 Compliance

| Element | Convention | Example |
|---------|-----------|---------|
| Classes | PascalCase | `UserAccount`, `DataProcessor` |
| Functions/Methods | snake_case | `get_user_data`, `process_request` |
| Variables | snake_case | `user_id`, `total_count` |
| Constants | UPPER_SNAKE_CASE | `MAX_RETRIES`, `API_KEY` |
| Private members | Leading underscore | `_internal_method`, `_cache` |
| Modules/Packages | snake_case, short | `user_auth`, `data_utils` |

### Structure (20 points) - Package Organization

**Core Python:**
- Standard layout: `src/`, `tests/`, `docs/`
- `__init__.py` in all package directories
- No circular imports

**Framework-Specific:**
- **Django**: `apps/`, `settings/`, `migrations/`, standard app structure
- **FastAPI**: `routers/`, `schemas/`, `dependencies/`, `main.py`
- **Data Science**: `notebooks/`, `data/`, `models/`, `pipelines/`

### Patterns (25 points) - Best Practices

**Core Python:**
- Type hints on function signatures (Python 3.9+)
- Context managers for resources (`with` statements)
- List comprehensions over loops (when readable)
- No mutable default arguments
- Use `pathlib` over `os.path`
- F-strings over `.format()` or `%`

**Django-Specific:**
- Class-based views preferred
- ORM best practices (select_related, prefetch_related)
- Proper signals usage
- Custom managers for complex queries

**FastAPI-Specific:**
- Dependency injection pattern
- Async/await for I/O operations
- Pydantic models for validation
- Proper router organization

**Data Science-Specific:**
- Vectorization over iteration
- Avoid iterating DataFrames
- Pipeline patterns for transformations
- Reproducible random seeds

## 4. Testing & Security Standards

### Testing (20 points)

**Test Structure:**
- Tests in `tests/` mirroring `src/` structure
- Naming: `test_*.py` or `*_test.py`
- Test functions: `test_function_name_scenario()`

**Framework & Coverage:**
- pytest preferred over unittest
- Use fixtures for setup/teardown
- Parametrize tests for multiple cases
- Minimum 70% code coverage
- 100% for critical paths (auth, payments, validation)

**Framework-Specific:**
- **Django**: `TestCase`, factory patterns, mock external services
- **FastAPI**: `TestClient`, async test support, dependency overrides
- **Data Science**: Test pipelines, validate model outputs, ensure reproducibility

### Security (15 points)

**Core Security:**
- No hardcoded secrets (detect `password=`, `api_key=`, `token=`)
- SQL injection prevention (parameterized queries only)
- Path traversal checks (validate user paths)
- Input validation on all external data

**Framework-Specific:**
- **Django**: CSRF enabled, XSS prevention, `DEBUG=False` in production, secure session settings
- **FastAPI**: CORS configuration, OAuth2/JWT validation, rate limiting
- **Data Science**: Pickle safety warnings, validate data sources, sanitize outputs before display

### Production Checks (production.md)

- No `print()` statements (use logging module)
- No `DEBUG=True` or development mode
- Environment variables for configuration
- Error handling for external services
- Secrets in environment, not code

## 5. Integration & Implementation

### Skill File Structure

Create `skills/python-standards/SKILL.md` following existing pattern:

```markdown
---
name: python-standards
description: Use when working with Python projects for standards enforcement and auditing
---

# Python Coding Standards

Standards Location:
- Rules: ${CLAUDE_PLUGIN_ROOT}/standards/python/rules.json
- Core docs: ${CLAUDE_PLUGIN_ROOT}/standards/python/*.md
- Framework docs: ${CLAUDE_PLUGIN_ROOT}/standards/python/frameworks/*.md

## Audit Mode
1. Load rules from rules.json
2. Filter rules by detected frameworks (PYTHON_FRAMEWORKS env var)
3. Analyze codebase across 5 categories
4. Calculate weighted score
5. Output framework-aware results

## Refactor Mode
Apply framework-appropriate fixes based on context

## Explain Mode
Reference PEP 8 and framework documentation
```

### Configuration Updates

**1. Config file (`.local/config.json`):**
```json
{
  "enabledLanguages": ["laravel", "nextjs", "flutter", "python"],
  "mode": "global",
  "strictness": "advisory",
  "autoAuditOnStart": true
}
```

**2. Detection script (`scripts/detect-project.sh`):**
- Add Python detection after Flutter check
- Call `detect_python_frameworks()` sub-function
- Store frameworks in environment variable
- Display detected frameworks in output

**3. Plugin metadata (`plugin.json`):**
- Add "python" to supported languages array

### Commands Support

All existing commands work automatically:
- `/audit` - Detects Python + frameworks, applies relevant rules
- `/audit --quick` - Quick scan with framework filtering
- `/refactor [file]` - Framework-aware Python fixes
- `/standards` - Includes Python in language selection
- `/standards languages add python` - Enable Python standards
- `/explain-standards [topic]` - References PEP 8 + framework docs

### Audit Output Example

```
📋 Python project (Django, FastAPI) detected
Score: 82/100

Naming: 18/20 ⚠️
  - 2 functions not using snake_case (app/utils.py:45, app/helpers.py:12)

Structure: 20/20 ✓

Patterns: 22/25 ⚠️
  - Missing type hints in 3 functions (Django views)
  - Mutable default argument in app/services.py:34

Testing: 16/20 ⚠️
  - Coverage: 68% (below 70% threshold)
  - Missing tests for FastAPI endpoints

Security: 15/15 ✓
```

## Implementation Tasks

1. **Create standards files** (standards/python/)
   - rules.json with framework filtering
   - Core markdown files (naming, patterns, testing, security, etc.)
   - Framework-specific markdown files

2. **Create skill file** (skills/python-standards/)
   - SKILL.md following existing pattern
   - Framework-aware audit logic

3. **Update detection script** (scripts/detect-project.sh)
   - Add Python project detection
   - Add framework sub-detection function
   - Set environment variables

4. **Update configuration**
   - Add Python to plugin.json
   - Update default config example in README

5. **Update documentation**
   - Add Python to README feature list
   - Document framework detection logic
   - Add Python examples to usage section

6. **Testing**
   - Test with Django-only project
   - Test with FastAPI-only project
   - Test with multi-framework project (Django + Data Science)
   - Test with pure Python (no frameworks)

## Success Criteria

- ✓ Python projects auto-detected on session start
- ✓ Frameworks correctly identified from dependencies
- ✓ Audit scores framework-relevant rules only
- ✓ All commands work with Python projects
- ✓ Framework-specific advice in refactor mode
- ✓ Documentation references PEP 8 and framework docs
