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

```
/install-plugin gregorymm/design-tokens
```

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
