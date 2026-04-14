# Design Tokens — Claude Code Plugin

Extract design tokens from Figma design system files and write them back. Supports **W3C DTCG** and **CTI** (Style Dictionary) naming conventions.

## What it does

- Connects to Figma via **Desktop MCP** or **REST API**
- Extracts variables, styles, and component properties from **all pages** across multiple files
- Classifies tokens into 3 layers: **Primitive** (raw values), **Semantic** (contextual roles), **Component** (per-component overrides)
- Derives semantic tokens from master component variant properties (Type, State, Size)
- Generates 4 output files: `tokens.json`, `tokens.css`, `tokens.scss`, `style-dictionary.config.json`
- Merges multi-theme modes (Light/Dark) into a single file with theme selectors
- **Write-back**: push local token changes to Figma via REST API with diff preview and confirmation

## Install

### Option A: Clone into plugins (recommended)

```bash
cd ~/.claude/plugins/marketplaces
git clone https://github.com/gregorymm/design-tokens.git gregorymm-design-tokens
```

Restart Claude Code. The `design-tokens` skill will be auto-discovered.

### Option B: Copy to local skills (no git)

```bash
mkdir -p ~/.claude/skills/design-tokens/references
curl -sL https://raw.githubusercontent.com/gregorymm/design-tokens/main/skills/design-tokens/SKILL.md \
  -o ~/.claude/skills/design-tokens/SKILL.md
for f in cti-format figma-api naming-rules output-templates w3c-format; do
  curl -sL "https://raw.githubusercontent.com/gregorymm/design-tokens/main/skills/design-tokens/references/${f}.md" \
    -o ~/.claude/skills/design-tokens/references/${f}.md
done
```

Restart Claude Code.

## Usage

Say any of:
- "extract design tokens from my Figma files"
- "figma tokens"
- "write tokens back to Figma"
- `/design-tokens`

The skill walks you through format choice (W3C vs CTI), access method (MCP vs REST API), and file selection.

## Token Format Comparison

| | W3C DTCG | CTI |
|---|---|---|
| **Field prefix** | `$value`, `$type` | `value`, `type` |
| **Naming order** | Component first: `button.primary.bg.color` | Category first: `color.bg.button.primary` |
| **Best for** | Style Dictionary v4+, new projects | Style Dictionary v3, legacy systems |

## Output

```
design-tokens/
  tokens.json                    # Full token tree
  tokens.css                     # CSS custom properties
  tokens.scss                    # SCSS variables + typography mixins
  style-dictionary.config.json   # Build config
```

## License

MIT
