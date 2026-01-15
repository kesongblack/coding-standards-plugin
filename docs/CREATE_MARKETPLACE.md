# Creating a Plugin Marketplace

If you want to create your own plugin marketplace (like `superpowers-marketplace` or `claude-plugins-official`), follow these steps:

## Step 1: Create a Marketplace Repository

Create a new GitHub repository (e.g., `my-claude-plugins-marketplace`) with this structure:

```
my-claude-plugins-marketplace/
├── marketplace.json          # Main marketplace metadata
├── plugins/
│   └── coding-standards/    # Subdirectory for your plugin
│       └── (plugin files)   # Or git submodule to plugin repo
└── README.md
```

## Step 2: Create marketplace.json at Root

Create `marketplace.json` at the repository root:

```json
{
  "name": "my-plugins",
  "displayName": "My Claude Plugins",
  "description": "Custom Claude Code plugins marketplace",
  "version": "1.0.0",
  "plugins": {
    "coding-standards": {
      "name": "coding-standards",
      "displayName": "Coding Standards",
      "description": "Multi-language coding standards system",
      "author": "Your Name",
      "license": "MIT",
      "repository": "https://github.com/YOUR-USERNAME/coding-standards-plugin",
      "path": "plugins/coding-standards",
      "versions": {
        "0.9.0-beta": {
          "version": "0.9.0-beta",
          "gitRef": "v0.9.0-beta",
          "description": "Beta testing release"
        },
        "1.0.0": {
          "version": "1.0.0",
          "gitRef": "v1.0.0",
          "description": "Stable release"
        }
      },
      "latestVersion": "0.9.0-beta"
    }
  }
}
```

## Step 3: Add Plugin as Submodule (Optional)

```bash
cd my-claude-plugins-marketplace
mkdir -p plugins
git submodule add https://github.com/YOUR-USERNAME/coding-standards-plugin.git plugins/coding-standards
```

Or copy plugin files directly into `plugins/coding-standards/`.

## Step 4: Push Marketplace to GitHub

```bash
git add .
git commit -m "Initial marketplace with coding-standards plugin"
git push origin main
```

## Step 5: Users Add Your Marketplace

Users add your marketplace with:

```bash
/plugin marketplace add https://github.com/YOUR-USERNAME/my-claude-plugins-marketplace
```

Then install plugins from it:

```bash
/plugin install coding-standards
```

## Simpler Alternative: Direct Install

Instead of creating a marketplace, users can install directly:

```bash
/plugin install https://github.com/YOUR-USERNAME/coding-standards-plugin
```

This is **much simpler** and recommended for single-plugin scenarios.

## How Claude Code Finds Plugins

When you run `/plugin install <url>`:

1. Claude Code clones the repository
2. Looks for `.claude-plugin/plugin.json`
3. Validates the structure
4. Copies to `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>`
5. Registers in `installed_plugins.json`

## Current Plugin Marketplaces

Check existing marketplaces:

```bash
cat ~/.claude/plugins/known_marketplaces.json
```

Example marketplaces:
- `claude-plugins-official` - Official Anthropic plugins
- `superpowers-marketplace` - Community superpowers plugins

## Testing Locally

For local testing without GitHub:

```bash
# Manual registration
cp -r /path/to/coding-standards-plugin ~/.claude/plugins/cache/local/coding-standards

# Edit ~/.claude/plugins/installed_plugins.json
# Add your plugin entry (as we did earlier)

# Restart Claude Code
```

## Recommended Approach for Your Plugin

Since you have a single plugin, **skip the marketplace** and just:

1. Push to GitHub: `https://github.com/YOUR-USERNAME/coding-standards-plugin`
2. Tell users to install with: `/plugin install https://github.com/YOUR-USERNAME/coding-standards-plugin`

That's it! No marketplace needed.
