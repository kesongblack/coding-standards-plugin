---
name: standards
description: View and manage coding standards, including language selection
allowed_tools: [Read, Write, Glob, AskUserQuestion]
---

# Standards Command

View and manage coding standards configuration and rules.

## Usage

```
/standards                     # Show current configuration
/standards languages           # View enabled languages
/standards languages add X     # Add a language
/standards languages remove X  # Remove a language
/standards languages set X,Y   # Set specific languages
/standards view [language]     # View standards for a language
/standards update              # Propose a standards update
```

## Subcommands

### /standards (no args)

Display current configuration:
- Enabled languages
- Mode (global/project)
- Strictness level
- Auto-audit setting

### /standards languages

**View:** Show currently enabled languages

**Add:** `/standards languages add flutter`
- Validate language is supported (laravel, nextjs, flutter)
- Add to enabledLanguages array
- Save config

**Remove:** `/standards languages remove nextjs`
- Remove from enabledLanguages array
- Save config

**Set:** `/standards languages set laravel,flutter`
- Replace enabledLanguages with provided list
- Validate all languages are supported
- Save config

### /standards view [language]

Display the standards for a specific language:
1. Read `standards/[language]/rules.json`
2. Read `standards/[language]/naming.md`
3. Present formatted summary of rules and conventions

### /standards update

Interactive workflow to propose a standards change:
1. Ask which language and category
2. Ask for the proposed change
3. Invoke standards-reviewer agent to evaluate
4. If approved, update the appropriate files

## Implementation

```
Parse args to determine subcommand

If no args or "languages":
  Read ${CLAUDE_PLUGIN_ROOT}/.local/config.json
  Display current enabled languages

If "languages add X":
  Validate X is in [laravel, nextjs, flutter]
  Read config, add to array, write config
  Confirm: "✓ Added [X]. Now enabled: [list]"

If "languages remove X":
  Read config, remove from array, write config
  Confirm: "✓ Removed [X]. Now enabled: [list]"

If "languages set X,Y":
  Parse comma-separated list
  Validate all entries
  Write config with new list
  Confirm: "✓ Enabled: [list]"

If "view [language]":
  Read standards/[language]/rules.json
  Read standards/[language]/naming.md
  Format and display

If "update":
  Use AskUserQuestion for language/category
  Use AskUserQuestion for proposed change
  Invoke standards-reviewer agent
  Process result
```

## Supported Languages

- `laravel` - Laravel/PHP standards
- `nextjs` - Next.js/React/TypeScript standards
- `flutter` - Flutter/Dart standards

## Notes

- Config stored in `.local/config.json` (gitignored)
- Standards stored in `standards/[language]/` (version controlled)
- Use `/standards setup` for first-time configuration
