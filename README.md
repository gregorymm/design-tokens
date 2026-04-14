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

### Option A: Clone as a plugin (recommended)

```bash
mkdir -p ~/.claude/plugins/marketplaces
cd ~/.claude/plugins/marketplaces
git clone https://github.com/gregorymm/design-tokens.git design-tokens
```

Restart Claude Code.

### Option B: Install as a standalone skill (no plugin wrapper)

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

## How to use in Claude Code

The skill can be invoked two ways:

### 1. Explicit slash command

```
/design-tokens
```

Type `/design-tokens` in Claude Code — the skill runs immediately and walks you through the prompts.

### 2. Natural language (auto-trigger)

Just describe what you want. Claude Code matches the skill's trigger phrases and runs it automatically:

- `extract design tokens from my Figma files`
- `export figma variables as design tokens`
- `extract tokens from https://figma.com/design/<KEY>/...`
- `sync tokens between Figma and code`
- `write my tokens.json back to Figma`
- `pull design tokens from these Figma files: <url1> <url2>`

### What happens next

The skill walks you through:

1. **Mode** — Extract (Figma → Code) or Write-back (Code → Figma)
2. **Format** — W3C DTCG or CTI
3. **Access method** — Figma Desktop MCP (needs app open) or Figma REST API (needs a Personal Access Token)
4. **Files** — paste one or more Figma file URLs
5. **Output directory** — defaults to `./design-tokens/`

It introspects master components to derive semantic + component tokens, runs a self-check, then writes `tokens.json`, `tokens.css`, `tokens.scss`, and `style-dictionary.config.json`.

### Verify the skill is installed

In Claude Code, ask: `what skills do you have?` — `design-tokens` should appear in the list. Or just say `extract design tokens` and see if the skill triggers.

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
