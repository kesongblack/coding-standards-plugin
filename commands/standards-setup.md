---
name: standards-setup
description: First-time setup to choose which language standards to enable
allowed_tools: [Read, Write, AskUserQuestion]
---

# Standards Setup Command

First-time setup for the coding standards plugin. Prompts user to select which language standards they want to enable.

## Usage

```
/standards setup
```

## Behavior

1. **Check for existing config:**
   - Read `.local/config.json` if it exists
   - If exists, show current selection and ask if user wants to modify

2. **Present language selection:**
   Use AskUserQuestion with multiSelect: true to let user choose languages:
   - Laravel (PHP) - For Laravel/PHP projects
   - Next.js (React/TypeScript) - For Next.js projects
   - Flutter (Dart) - For Flutter/Dart projects

3. **Save configuration:**
   Write selected languages to `${CLAUDE_PLUGIN_ROOT}/.local/config.json`:
   ```json
   {
     "enabledLanguages": ["laravel", "flutter"],
     "mode": "global",
     "strictness": "advisory",
     "autoAuditOnStart": true
   }
   ```

4. **Confirm to user:**
   Display: "✓ Enabled: [languages]. Run /audit to check your project."

## Implementation

```
1. Read ${CLAUDE_PLUGIN_ROOT}/.local/config.json (may not exist)

2. Use AskUserQuestion:
   - Question: "Which language standards would you like to enable?"
   - Options: Laravel (PHP), Next.js (React/TypeScript), Flutter (Dart)
   - multiSelect: true

3. Create .local directory if needed:
   mkdir -p ${CLAUDE_PLUGIN_ROOT}/.local

4. Write config.json with user selections

5. Confirm: "✓ Enabled: [list]. Run /audit to check your project."
```

## Notes

- This command should be run once per installation
- Can be re-run anytime to modify language selection
- Configuration is stored locally and not tracked in git
