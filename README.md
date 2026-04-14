# Design Tokens — Claude Code Plugin

Extract design tokens from Figma design system files and write them back. Supports **W3C DTCG** and **CTI** (Style Dictionary) naming conventions.

## What it does

- Connects to Figma via **Desktop MCP** or **REST API**
- Extracts variables, styles, and component properties from **all pages** across multiple files
- Classifies tokens into 3 layers: **Primitive** (raw values), **Semantic** (contextual roles), **Component** (per-component overrides)
- Derives semantic tokens from master component variant properties (Type, State, Size)
- Generates 4 output files: `tokens.json`, `tokens.css`, `tokens.scss`, `style-dictionary.config.json`
- Merges multi-theme modes (Light/Dark) into a single file with theme selectors
- **Write-back** — push tokens to Figma AND rebind existing layers so components reference variables instead of raw hex. Works on all paid plans: REST API for Enterprise, generated Figma plugin for Professional/Organization.

## Install

### Quick install (one line)

```bash
curl -sL https://raw.githubusercontent.com/gregorymm/design-tokens/main/install.sh | bash
```

This clones the plugin into `~/.claude/plugins/marketplaces/design-tokens`, registers it in `~/.claude/settings.json`, and you're done. **Restart Claude Code** and use `/design-tokens`.

Requires `git` and `node`.

### Manual install

**Step 1** — Clone the plugin:

```bash
mkdir -p ~/.claude/plugins/marketplaces
cd ~/.claude/plugins/marketplaces
git clone https://github.com/gregorymm/design-tokens.git design-tokens
```

**Step 2** — Register it in `~/.claude/settings.json`. Merge these two entries into the existing objects (don't overwrite):

```json
{
  "enabledPlugins": {
    "design-tokens@design-tokens": true
  },
  "extraKnownMarketplaces": {
    "design-tokens": {
      "source": {
        "source": "github",
        "repo": "gregorymm/design-tokens"
      }
    }
  }
}
```

**Step 3** — Restart Claude Code.

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
3. **Figma plan** — Starter / Professional / Organization / Enterprise (routes the write-back method)
4. **Access method** — Figma Desktop MCP (needs app open) or Figma REST API (needs a Personal Access Token)
5. **Files** — paste one or more Figma file URLs
6. **Output directory** — defaults to `./design-tokens/`

It introspects master components to derive semantic + component tokens, runs a self-check, then writes `tokens.json`, `tokens.css`, `tokens.scss`, and `style-dictionary.config.json`.

After extraction, it asks if you want to **push the tokens back to Figma and rebind layers** (variables + layer bindings so components reference variables instead of raw hex).

## Write-back & Layer Rebind

The skill can push extracted tokens back to Figma and rebind existing layers. The method depends on your plan:

| Plan | Method | Speed |
|------|--------|-------|
| **Enterprise** | REST API (`POST /v1/files/:key/variables`) | Fast, headless |
| **Professional / Organization** | Generated Figma plugin (manifest.json + code.js you load in Figma desktop) | Manual trigger, runs inside Figma |
| **Starter (free)** | Not supported — use Tokens Studio or upgrade | — |

The **layer rebind** step walks every node across your Figma files, matches raw hex/number values to your new tokens, and replaces them with variable bindings. Result: components stop using `#4B64FF` directly and start referencing `color.primitive.accent.500`. Changing a token value then propagates to every bound layer automatically.

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
