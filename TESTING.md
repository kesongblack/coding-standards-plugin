# Testing the Coding Standards Plugin (Beta)

## Beta Release: v0.9.0-beta

This is a **pre-production testing release**. Use in isolated test projects only.

## Installation for Testing

### Method 1: Install Beta Version Directly

```bash
# Clone the repository
git clone https://github.com/your-username/coding-standards-plugin.git ~/projects/coding-standards-plugin

# Checkout the beta tag
cd ~/projects/coding-standards-plugin
git checkout v0.9.0-beta

# Run installation
./scripts/install.sh

# Restart Claude Code
```

### Method 2: Test Alongside Production Version

If you already have a production version installed, you can test the beta separately:

```bash
# Clone to a different location
git clone https://github.com/your-username/coding-standards-plugin.git ~/projects/coding-standards-plugin-beta
cd ~/projects/coding-standards-plugin-beta
git checkout v0.9.0-beta

# Create a different symlink name
ln -s ~/projects/coding-standards-plugin-beta ~/.claude/plugins/coding-standards-beta

# Restart Claude Code
```

## Testing Checklist

### 1. Installation Tests
- [ ] Plugin appears in Claude Code
- [ ] No errors on session start
- [ ] Symlink created correctly at `~/.claude/plugins/coding-standards`

### 2. Project Detection Tests

**Test with Laravel project:**
```bash
cd your-laravel-project
# Start new Claude Code session
# Expected: "📋 Laravel project detected"
```

**Test with Next.js project:**
```bash
cd your-nextjs-project
# Start new Claude Code session
# Expected: "📋 Next.js project detected"
```

**Test with Flutter project:**
```bash
cd your-flutter-project
# Start new Claude Code session
# Expected: "📋 Flutter project detected"
```

**Test with unsupported project:**
```bash
cd some-python-project
# Start new Claude Code session
# Expected: No message (silent exit)
```

### 3. Configuration Tests

**First-time setup:**
```bash
/standards setup
# Expected: Prompt to select languages
```

**View configuration:**
```bash
/standards
# Expected: Show enabled languages, mode, strictness
```

**Manage languages:**
```bash
/standards languages
/standards languages add flutter
/standards languages remove nextjs
/standards languages set laravel,nextjs
# Expected: Commands work without errors
```

### 4. Command Tests

**Audit command:**
```bash
/audit
# Expected: Full codebase audit with score
```

**Quick audit:**
```bash
/audit --quick
# Expected: Quick sample-based audit
```

**Refactor command:**
```bash
/refactor app/Http/Controllers/UserController.php
# Expected: Analyze file and propose fixes
```

**View standards:**
```bash
/standards view laravel
# Expected: Display Laravel standards
```

**Explain standards:**
```bash
/explain-standards service-layer
# Expected: Explain why service layer pattern exists
```

### 5. Skills Tests

The plugin should automatically use skills when:
- You run `/audit` - invokes `coding-standards-core`
- You run `/refactor` - invokes language-specific skill
- You ask about standards - routes to appropriate skill

**Manual skill test:**
```bash
# In a Laravel project
/coding-standards-core
# Expected: Detects Laravel, routes to laravel-standards
```

### 6. SessionStart Hook Tests

**Test automatic detection:**
1. Close all Claude Code sessions
2. Open a Laravel/Next.js/Flutter project
3. Start new Claude Code session
4. Expected: See project detection message

**Test with no config:**
1. Delete `.local/config.json`
2. Start new session in supported project
3. Expected: Prompt to run `/standards setup`

### 7. Standards Files Tests

**Check Laravel standards:**
```bash
/standards view laravel
# Verify: Naming, Structure, Patterns, Testing, Security categories
```

**Check Next.js standards:**
```bash
/standards view nextjs
# Verify: Naming, Structure, Patterns, Testing, Security categories
```

**Check Flutter standards:**
```bash
/standards view flutter
# Verify: Naming, Structure, Patterns, Testing, Security categories
```

### 8. Edge Cases

**Empty config:**
- Delete `.local/config.json`
- Expected: First-time setup message

**Invalid config:**
- Corrupt `.local/config.json`
- Expected: Graceful error or recreate

**Missing standards files:**
- Temporarily rename `standards/laravel/rules.json`
- Run `/audit` in Laravel project
- Expected: Clear error message

**Mixed project:**
- Project with both `composer.json` and `package.json`
- Expected: Detect first match (Laravel priority)

### 9. Performance Tests

**Large codebase:**
- Run `/audit` on large project (1000+ files)
- Expected: Completes within reasonable time

**Quick audit:**
- Run `/audit --quick` on large project
- Expected: Faster than full audit

### 10. Agent Tests

**Standards reviewer:**
```bash
/standards update
# Follow prompts to propose a change
# Expected: Standards-reviewer agent evaluates proposal
```

## Known Issues (Beta)

### Expected Issues:
1. **jq dependency:** Standards validation script requires jq
   - Non-critical for normal operation
   - Only affects `/validate-standards` script

2. **First session:** No automatic audit on first session
   - Requires `/standards setup` first
   - Expected behavior

### Report Issues:
If you encounter issues during testing, please check:
1. Claude Code version compatibility
2. Plugin file permissions
3. Git submodule status (if applicable)

Create an issue at: https://github.com/your-username/coding-standards-plugin/issues

Include:
- Claude Code version
- Operating system
- Project type being tested
- Error messages or unexpected behavior
- Steps to reproduce

## Test Results Template

```markdown
## Test Results - v0.9.0-beta

**Tester:** [Your Name]
**Date:** [Date]
**Environment:** [OS, Claude Code version]

### Tests Passed ✅
- [ ] Installation
- [ ] Project detection (Laravel)
- [ ] Project detection (Next.js)
- [ ] Project detection (Flutter)
- [ ] /standards setup
- [ ] /standards languages
- [ ] /audit
- [ ] /refactor
- [ ] /explain-standards
- [ ] SessionStart hook
- [ ] Skills invocation

### Tests Failed ❌
[List any failures with details]

### Issues Found 🐛
[List any bugs or unexpected behavior]

### Feedback 💡
[Any suggestions or improvements]
```

## Moving to Production

After successful testing, the beta can be promoted to v1.0.0 stable:

```bash
git checkout main
git merge v0.9.0-beta
git tag -a v1.0.0 -m "Stable release"
git push origin main --tags
```

## Rollback Instructions

If you need to uninstall the beta:

```bash
# Remove symlink
rm ~/.claude/plugins/coding-standards

# Remove cloned repository (if desired)
rm -rf ~/projects/coding-standards-plugin

# Or checkout a different version
cd ~/projects/coding-standards-plugin
git checkout v1.0.0  # or another tag
./scripts/install.sh
```

## Support

For help with beta testing:
- Check [TEST_RESULTS.md](TEST_RESULTS.md) for structural validation results
- Review [README.md](README.md) for usage documentation
- Open issues for bugs or questions
