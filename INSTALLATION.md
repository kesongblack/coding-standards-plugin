# Installation Guide

## Quick Install (From GitHub)

Once you've pushed this repository to GitHub:

```bash
# In any Claude Code session, run:
/plugin install https://github.com/YOUR-USERNAME/coding-standards-plugin
```

Claude Code will:
1. Clone the repository to `~/.claude/plugins/cache/`
2. Register it in the plugin system
3. Make commands and skills available globally

## Local Development Install (For Testing)

For local testing before publishing to GitHub:

### Method 1: Direct Copy (Recommended for Testing)

```bash
# Copy plugin to Claude's cache directory
mkdir -p ~/.claude/plugins/cache/local
cp -r /home/kesongblack/projects/coding-standards-plugin ~/.claude/plugins/cache/local/coding-standards

# Manually register in installed_plugins.json
```

Then edit `~/.claude/plugins/installed_plugins.json`:

```json
{
  "version": 2,
  "plugins": {
    "coding-standards@local": [
      {
        "scope": "user",
        "installPath": "/home/kesongblack/.claude/plugins/cache/local/coding-standards",
        "version": "0.9.0-beta",
        "installedAt": "2026-01-15T00:00:00.000Z",
        "lastUpdated": "2026-01-15T00:00:00.000Z"
      }
    ]
  }
}
```

### Method 2: GitHub Local Repository

```bash
# Initialize as git repo (already done)
cd /home/kesongblack/projects/coding-standards-plugin

# Create a GitHub repository
# Then push:
git remote add origin https://github.com/YOUR-USERNAME/coding-standards-plugin.git
git push -u origin main
git push --tags

# Install from GitHub
# In Claude Code:
/plugin install https://github.com/YOUR-USERNAME/coding-standards-plugin
```

## Post-Installation

After installation by either method:

1. **Restart Claude Code** or start a new session
2. **Verify installation:** Commands should appear when you type `/`
3. **Configure languages:**
   ```bash
   /standards setup
   ```
4. **Test in a project:**
   ```bash
   cd ~/path/to/laravel-project
   # Start new session - should see detection message
   /audit
   ```

## Troubleshooting

### Commands Don't Appear

**Problem:** After installation, `/standards`, `/audit`, etc. don't show in autocomplete

**Solutions:**
1. Restart Claude Code completely (not just new session)
2. Check `~/.claude/plugins/installed_plugins.json` - plugin should be listed
3. Verify plugin structure:
   ```bash
   ls ~/.claude/plugins/cache/*/coding-standards/.claude-plugin/plugin.json
   ```

### "Plugin Not Found"

**Problem:** `/plugin install` says plugin not found

**Solutions:**
1. Ensure GitHub repository is public
2. Verify `.claude-plugin/plugin.json` exists and is valid
3. Check repository URL is correct

### SessionStart Hook Doesn't Run

**Problem:** No detection message when opening supported projects

**Solutions:**
1. Verify `hooks/hooks.json` exists
2. Check script permissions:
   ```bash
   chmod +x ~/.claude/plugins/cache/*/coding-standards/scripts/*.sh
   ```
3. Test script manually:
   ```bash
   cd ~/your-laravel-project
   bash ~/.claude/plugins/cache/*/coding-standards/scripts/detect-project.sh
   ```

### Skills Don't Load

**Problem:** Commands run but don't invoke skills

**Solutions:**
1. Check skills directory exists: `skills/*/SKILL.md`
2. Verify plugin.json lists all skills
3. Test skill manually:
   ```bash
   /coding-standards-core
   ```

## Uninstallation

### Via Claude Code
```bash
/plugin uninstall coding-standards
```

### Manual
```bash
# Remove from installed plugins (edit ~/.claude/plugins/installed_plugins.json)
# Delete cache directory
rm -rf ~/.claude/plugins/cache/*/coding-standards
```

## Development Workflow

When developing locally:

1. **Make changes** to source files in `/home/kesongblack/projects/coding-standards-plugin`
2. **Sync to cache:**
   ```bash
   rsync -av --delete \
     /home/kesongblack/projects/coding-standards-plugin/ \
     ~/.claude/plugins/cache/local/coding-standards/
   ```
3. **Restart Claude Code session** to reload plugin
4. **Test changes** in a project

Or use a watch script:

```bash
# Create watch script
cat > ~/sync-plugin.sh << 'EOF'
#!/bin/bash
while inotifywait -r -e modify,create,delete \
  /home/kesongblack/projects/coding-standards-plugin; do
  rsync -av --delete \
    /home/kesongblack/projects/coding-standards-plugin/ \
    ~/.claude/plugins/cache/local/coding-standards/
  echo "Plugin synced at $(date)"
done
EOF
chmod +x ~/sync-plugin.sh

# Run in background
~/sync-plugin.sh &
```

## Publishing to Plugin Marketplace

To make your plugin installable by others:

1. **Push to GitHub** (public repository)
2. **Users install with:**
   ```bash
   /plugin install https://github.com/YOUR-USERNAME/coding-standards-plugin
   ```

Optional: Submit to official marketplace (if available).
