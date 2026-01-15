# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] - 2026-01-14

### Added
- **Production Safety Audit**: New "production" category for all frameworks
  - Laravel: debug mode, .env exposure, seeders in routes, dd/dump calls
  - Next.js: console logs, dev-only code, env vars, build config
  - Flutter: debug banner, print statements, release signing, kDebugMode
- **Production Workflow**: `audit-production.yml` for deploy pipelines
  - Triggers on production/release branches
  - Blocks deployment on error-level issues
  - Configurable warning handling
- Production documentation for each framework (`production.md`)

### Changed
- Updated CI config template with production audit settings
- Updated README with production audit documentation

## [1.1.0] - 2026-01-14

### Added
- **CI/CD Integration**: GitHub Actions workflows for automated standards enforcement
  - `audit-pr.yml`: Runs audit on pull requests, posts results as comment
  - `audit-scheduled.yml`: Configurable scheduled audits (notification or full-audit mode)
  - `release.yml`: Automated release workflow with standards validation
- **Configuration Template**: `.github/coding-standards-config.yml` for per-repo CI settings
- **Validation Script**: `scripts/validate-standards.sh` for JSON schema validation
- Scheduled audit can run in "notification" mode (zero tokens) or "full-audit" mode

### Changed
- Updated README with CI/CD integration documentation

## [1.0.0] - 2026-01-14

### Added
- Initial project structure
- Git-based plugin architecture
- Support for Laravel, Next.js, and Flutter standards
- Auto-detection on session start
- Commands: `/audit`, `/refactor`, `/standards`, `/explain-standards`
- Standards reviewer agent
- Configuration system with language selection
- Project override support

---

## Release Notes Format

### Version [X.Y.Z] - YYYY-MM-DD

**Added** - New features
**Changed** - Changes in existing functionality
**Deprecated** - Soon-to-be removed features
**Removed** - Removed features
**Fixed** - Bug fixes
**Security** - Security fixes
