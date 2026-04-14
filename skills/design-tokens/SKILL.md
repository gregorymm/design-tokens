---
name: design-tokens
description: Extract design tokens from Figma design system files (variables, styles, component properties) into W3C DTCG or CTI format. Generates tokens.json, tokens.css, tokens.scss, and Style Dictionary config. Supports write-back to push local token changes into Figma variables via REST API. Triggers on "extract tokens", "design tokens", "figma tokens", "token export", "export variables from figma", "write tokens back", "push tokens to figma", "sync tokens".
---

# Design Tokens Extractor

Extract design tokens from Figma and write them back. Two flows: **Extract** (Figma to Code) and **Write-back** (Code to Figma).

## Step 1: Mode Selection

Ask the user:

```
What would you like to do?

   A) Extract tokens from Figma → generate JSON, CSS, SCSS files
   B) Write tokens back to Figma → push local tokens.json into Figma variables
```

If the user's initial message already makes the intent clear (e.g., "extract my design tokens"), skip this question and proceed directly.

## Step 2: Format Selection

Present the format choice with descriptions and a concrete example of the same token in each format:

```
Which token naming convention?

   A) W3C DTCG — Modern W3C standard (Style Dictionary v4+, Tokens Studio)
      Component/context leads, property at the end.
      Uses $value, $type, $description fields.

      Example — button primary background hover:
        Path:  button.accent.bg.color.hover
        JSON:  { "$value": "{bg.brand.color.hover}", "$type": "color" }

   B) CTI — Category/Type/Item (Style Dictionary v3 default)
      Physical property leads, component in the middle.
      Uses value, type, comment fields.

      Example — button primary background hover:
        Path:  color.button.bg.accent.hover
        JSON:  { "value": "{color.bg.brand.hover}", "type": "color" }
```

After the user chooses, read the corresponding format reference for detailed structure:
- W3C: `references/w3c-format.md`
- CTI: `references/cti-format.md`

## Step 3: Access Method

```
How to connect to Figma?

   A) Figma Desktop MCP — Figma app must be open (read-only, fast)
   B) REST API — provide a Personal Access Token (works headlessly, supports write-back)
```

**MCP path:** Use `mcp__Figma__get_variable_defs` and `mcp__Figma__get_design_context`. The Figma desktop app must have the target file open. MCP tools are read-only — cannot write back.

**REST API path:** Prompt for `FIGMA_TOKEN` (Personal Access Token with `file_variables:read`, `file_variables:write`, `file_content:read` scopes). Store in a shell variable for the session. Read `references/figma-api.md` for endpoint details.

**Important:** Write-back (flow B) always requires REST API regardless of extract method choice.

## Step 4: Collect Figma Files

Ask the user for one or more Figma file URLs or file keys. Extract the file key from URLs:
- `https://www.figma.com/design/<fileKey>/<name>` → extract `<fileKey>`
- `https://www.figma.com/file/<fileKey>/<name>` → extract `<fileKey>`
- For branch URLs `.../branch/<branchKey>/...` → use `<branchKey>`

Support multiple files (e.g., one for colors, one for components, one for typography).

---

## Extract Flow (Figma → Code)

### E1: Fetch Raw Data — Variables & Styles

**REST API path** — for each file key, run:

```bash
# Variables (collections, modes, values)
curl -s -H "X-FIGMA-TOKEN: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/<KEY>/variables/local"

# Styles metadata (paint, text, effect, grid)
curl -s -H "X-FIGMA-TOKEN: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/<KEY>/styles"

# Resolve style values via node IDs (batch node IDs from styles response)
curl -s -H "X-FIGMA-TOKEN: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/<KEY>/nodes?ids=<comma-separated-node-ids>"
```

**MCP path** — for each file, call:
- `mcp__Figma__get_variable_defs` (variables and their modes)
- `mcp__Figma__get_design_context` (component structure, applied styles)
- `mcp__Figma__get_metadata` (enumerate pages and components)

Read `references/figma-api.md` for full response schemas and rate limit handling.

### E2: Introspect Master Components

**This step is critical.** Variables alone only give you primitive raw values. The semantic and component token layers must be derived from how master components actually use those values.

**Step E2.1: Enumerate ALL master components across ALL pages.**

A Figma file can have multiple pages, each containing different component groups. The skill MUST scan every page — not just the currently visible one.

**REST API path (preferred — scans the entire file automatically):**
```bash
# Get all components in the file (all pages)
curl -s -H "X-FIGMA-TOKEN: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/<KEY>/components"

# Get full file tree to enumerate pages and find component sets
curl -s -H "X-FIGMA-TOKEN: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/<KEY>?depth=2"
```

The `/components` endpoint returns ALL published components across all pages. The `/files/:key?depth=2` call returns the page structure — each top-level child of the document is a page. Use page names to understand grouping (e.g., "Buttons", "Inputs", "Feedback", "Navigation").

**MCP path (requires manual page navigation):**
1. Call `mcp__Figma__get_metadata` with the file's root page ID (`0:1`) to list all pages.
2. For EACH page, call `mcp__Figma__get_metadata` with the page's nodeId to list its top-level frames and components.
3. Collect all component/component-set node IDs across all pages.
4. Important: the user may need to navigate to each page in Figma desktop for MCP to access its contents. Ask the user to switch pages if needed.

Build a component inventory table:

```
Page: "Buttons"
  - Button (component set, node 129:10493) — variants: Type, State, Size
  - IconButton (component set, node 130:200) — variants: State, Size

Page: "Forms"  
  - Input (component set, node 200:100) — variants: State, Size, HasLabel
  - Checkbox (component, node 201:50) — variants: State
  - Radio (component, node 202:30) — variants: State
  ...
```

**Step E2.2: For each master component, inspect its variant properties.**

Figma components have variant properties (visible as the property panel fields). Common properties and their token mapping:

| Figma Variant Property | Token Dimension | Examples |
|----------------------|-----------------|---------|
| `Type` / `Variant` / `Style` | Role | primary, secondary, tertiary, ghost, danger |
| `State` | State | default, hover, active, focus, disabled |
| `Size` | Size modifier | xs, sm, md, lg, xl, 2xl |
| `Theme` / `Mode` | Theme | light, dark |
| `Icon` / `Leading` / `Trailing` | Element | icon, label, leading, trailing |

**MCP path:** Call `mcp__Figma__get_design_context` with the `nodeId` of each master component. This returns the component rendered as code with applied colors, spacing, and typography visible in the output. Parse the generated code to extract:
- Background colors (`bg-[#...]` or `bg-[var(--...)]`)
- Text colors (`text-[#...]`)
- Border/stroke colors and widths
- Border radius values
- Padding/gap values
- Font properties (family, weight, size, line-height)
- Shadow/effect values

**REST API path:** Use `GET /v1/files/:key/nodes?ids=<component-node-id>` to get full node properties including fills, strokes, effects, cornerRadius, padding, and bound variables.

**Step E2.3: Walk the variant matrix.**

For each component, iterate through its variant combinations. The goal is to capture how each property changes across variants and states:

Example — **Button** component with variants `Type=[Primary, Secondary, Ghost]` and `State=[Default, Hover, Active, Disabled]`:

```
Button / Primary / Default  → bg: #275ECE, text: #FFFFFF, radius: 8, shadow: primary-button-regular
Button / Primary / Hover    → bg: #1D4BA0, text: #FFFFFF
Button / Primary / Active   → bg: #143B71, text: #FFFFFF
Button / Primary / Disabled → bg: #275ECE (16% opacity), text: #FFFFFF (40% opacity)
Button / Secondary / Default → bg: transparent, border: #E1E4E4, text: #16181D
...
```

**MCP path:** Select specific variant instances in Figma (or navigate to the variant's node ID) and call `get_design_context` for each. If the component has many variants, prioritize: extract one representative per Type, and Default + Hover + Disabled states for each.

**REST API path:** Fetch the component set node, then iterate child component nodes (each represents a variant). Parse their properties.

### E3: Classify Tokens into 3 Layers

Use the data from E1 (raw variables) and E2 (component introspection) together.

**Primitive (Layer 1)** — raw design values, no semantic meaning:
- Color palette scales (e.g., `accent/500`, `neutrals-d/900`)
- Spacing/radius numeric scales
- Font family, weight, and size primitives
- Raw effect values
- Classification: variables with NO aliases, raw hex/number values, typically in single-mode collections named "Primitives", "Raw", "Core", "Base", "Palette", "Scale"

**Semantic (Layer 2)** — contextual roles derived from how primitives are used across multiple components:
- Look at the extracted component data: if the SAME primitive value appears as background across multiple components (Button primary, Badge primary, Link primary), it becomes a semantic `color-bg-brand` token referencing that primitive.
- If a value appears as text color on a colored surface across multiple components, it becomes `color-text-on-brand`.
- Feedback colors used consistently (success/warning/alert states across components) become semantic feedback tokens.
- Common padding/radius values used across multiple components become semantic spacing/radius tokens.
- Pattern detection:

| Observation across components | Semantic token |
|------------------------------|---------------|
| Same bg color for all "primary" variants | `color-bg-brand` → `{color.primitive.accent.500}` |
| Same bg color for "primary hover" | `color-bg-brand-hover` → `{color.primitive.accent.600}` |
| White text on all colored backgrounds | `color-text-on-brand` → `{color.primitive.basic.white}` |
| Same dark text color for body text | `color-text-primary` → `{color.primitive.neutrals-d.900}` |
| Same muted text color | `color-text-secondary` → `{color.primitive.neutrals-d.400}` |
| Same border color across inputs/cards | `color-border-default` → `{color.primitive.neutrals-l.300}` |
| Same disabled opacity pattern | `color-bg-disabled` → `{color.opacity.accent-500.16}` |
| Common radius across default buttons/inputs | `radius-default` → references a primitive |
| Common padding across containers | `spacing-padding-md` → references a primitive |

**Component (Layer 3)** — component-specific tokens for values unique to a single component:
- If a value is used ONLY by one component (not shared), it becomes a component token.
- Component tokens reference semantic tokens where possible, primitives as fallback.
- Naming includes the component: `color-button-bg-primary`, `radius-button-small-md`, `shadow-primary-button-regular`.
- Per-breakpoint values (md, lg, xl, 2xl) are always component tokens since they're component-specific responsive behavior.

**Fallback:** If a value can't be traced to a component or semantic role, classify as primitive. Ask the user to confirm ambiguous cases.

### E4: Apply Naming Convention

Read `references/naming-rules.md` for the full taxonomy (categories, properties, roles, prominence, states).

**Key rules:**
- Convert Figma `/` separator to `.` for JSON nesting, `-` for CSS/SCSS
- Omit `default` state from names (it's implied)
- Use `on-{role}` prefix for content on colored surfaces
- Convert Figma RGBA (0-1) to hex: `#${Math.round(r*255).toString(16).padStart(2,'0')}${...g...}${...b...}`
- If alpha < 1, append alpha hex byte
- Map Figma variant property values to token name segments:
  - `Type=Primary` → role `primary` or `brand`
  - `Type=Secondary` → role `secondary`
  - `Type=Ghost` → role `ghost`
  - `Type=Danger` → role `danger`
  - `State=Hover` → state `-hover`
  - `State=Disabled` → state `-disabled`
  - `Size=md` → size modifier `-md`

### E4: Merge Multi-Theme Modes

For each multi-mode collection:
1. Identify the default mode (usually "Light" or the collection's `defaultModeId`)
2. Default mode values go into the main token tree
3. Other modes go into a `themes` section (JSON) or `[data-theme="<mode>"]` selectors (CSS)
4. Primitive tokens are shared — they do NOT vary per theme
5. Static tokens (e.g., `color-static-white`) are excluded from theme overrides

### E5: Generate Output Files

Read `references/output-templates.md` for exact templates and formatting rules.

Generate 4 files in the output directory (default `./design-tokens/`):

| File | Content |
|------|---------|
| `tokens.json` | Full token tree in chosen format (W3C or CTI) |
| `tokens.css` | CSS custom properties with `:root` and `[data-theme]` selectors |
| `tokens.scss` | SCSS variables, theme maps, and theme mixin |
| `style-dictionary.config.json` | Style Dictionary build config pointing to tokens.json |

Ask the user for the output directory path. Default to `./design-tokens/`.

### E6: Self-Check — Validate Before Writing

**MANDATORY.** Before writing any output file, review the generated token structure against this checklist. Read `references/naming-rules.md` section "Disambiguation: Radius vs Spacing" if needed.

**Category assignment checks:**
- [ ] **Radius vs Spacing:** Variables with small numeric values (4-18px) that vary per breakpoint — are they `radius` or `spacing`? Check the Figma variable name, sibling tokens in the same collection, and Figma scopes. If the variable sits in a collection alongside `Radius-*` tokens, it is radius. If it sits alongside `Padding-*` or `Gap-*` tokens, it is spacing. Never assume based on value alone.
- [ ] **Spacing vs Size:** `width`/`height` values are `size`, not `spacing`. Only padding, margin, and gap are `spacing`.
- [ ] **Font size vs Dimension:** Font sizes should be under `font.size`, not generic `dimension` or `spacing`.
- [ ] **Opacity colors vs Solid colors:** Hex values with alpha (e.g., `#FFFFFF1F`) should be under `color.opacity`, not mixed into the main palette.
- [ ] **Effect tokens category:** Drop shadows are `shadow`, not `color`. Inner shadows are also `shadow` (with `inset` prefix in CSS).

**Naming consistency checks:**
- [ ] **No duplicate paths:** Verify no two tokens resolve to the same CSS variable name.
- [ ] **Consistent separator:** All JSON keys use the same nesting style (no mix of `.` and `/`).
- [ ] **No `default` in state names:** `color-bg-primary` not `color-bg-primary-default`.
- [ ] **Breakpoint suffixes consistent:** If using `md/lg/xl/2xl`, all groups use the same set — no random `xs` in one group and `sm` in another unless the Figma data supports it.

**Cross-format checks (CSS/SCSS must match JSON):**
- [ ] Every token in `tokens.json` has a corresponding entry in `tokens.css` and `tokens.scss`.
- [ ] CSS variable names match the JSON token path (replace `.` with `-`, add `--` prefix).
- [ ] SCSS variable names match (`$` prefix instead of `--`).
- [ ] Shadow values in CSS are valid `box-shadow` syntax (not broken across lines).

**Structural checks:**
- [ ] Alias references in JSON actually point to existing tokens (no dangling `{color.primitive.foo}` that doesn't exist).
- [ ] Typography composite tokens have all required fields (fontFamily, fontWeight, fontSize, lineHeight, letterSpacing).
- [ ] No empty groups in JSON (every nested object eventually contains a token with a `value`).

If any check fails, fix it before writing the files. If unsure about a classification, flag it in the warnings summary and ask the user.

### E7: Display Summary

Show a summary table:

```
Extraction Complete

  Primitives:    142 tokens (87 color, 24 spacing, 12 radius, 19 other)
  Semantic:       68 tokens (41 color, 15 spacing, 12 radius)
  Component:      23 tokens (button: 8, input: 6, card: 5, modal: 4)
  Themes:         2 modes (Light, Dark)
  Files:          4 files written to ./design-tokens/

  Warnings:
  - 3 variables with unresolved aliases (skipped)
  - 1 variable with unsupported type BOOLEAN (included as-is)
```

---

## Write-Back Flow (Code → Figma)

### W1: Collect Inputs

Prompt for:
1. Path to local `tokens.json` file
2. Target Figma file URL or key (where to write)
3. Figma PAT (if not already set)

### W2: Parse and Validate

Read the JSON file and auto-detect format:
- Has `$value` fields → W3C DTCG
- Has `value` fields (no `$` prefix) → CTI

Validate:
- All alias references resolve to existing tokens
- No circular alias chains
- Token types are valid
- Report any issues before proceeding

### W3: Fetch Current Figma State

Call `GET /v1/files/:key/variables/local` to get existing variables. Build lookup maps:
- `{collectionName → collectionId}`
- `{variablePath → variableId}` (convert Figma `/` names to dot paths)
- `{modeName → modeId}` per collection

### W4: Compute Diff

Compare local tokens against Figma state:

| Status | Meaning |
|--------|---------|
| CREATE | Token exists locally but not in Figma |
| UPDATE | Token exists in both but values differ |
| UNCHANGED | Token exists in both with same values |
| FIGMA-ONLY | Token exists in Figma but not locally (leave untouched) |

### W5: Preview and Confirm

Display the diff summary:

```
Write-Back Preview (dry run)

  Collections:  1 to create (Components), 2 unchanged
  Variables:    12 to create, 5 to update, 130 unchanged
  Modes:        1 to create (High Contrast), 2 unchanged

  New variables:
    - button/bg/accent-disabled (COLOR)
    - button/text/accent-disabled (COLOR)
    ...

  Updated values:
    - color/bg/brand: #4B64FF → #3B5BDB (Light mode)
    ...

  Proceed? (y/n)
```

**Never auto-push.** Wait for explicit user confirmation.

### W6: Push Changes

Read `references/figma-api.md` for the POST request body schema.

Build a single `POST /v1/files/:key/variables` request body with:
1. `variableCollections`: CREATE new collections
2. `variableModes`: CREATE new modes in existing/new collections
3. `variables`: CREATE new variables, UPDATE changed ones
4. `variableModeValues`: Set values per variable per mode

**Ordering:** Create collections first, then modes, then primitive variables, then semantic variables (which alias primitives), then component variables (which alias semantics). Use temporary IDs (`temp-col-1`, `temp-var-1`, etc.) for new items — Figma resolves them.

```bash
curl -s -X POST \
  -H "X-FIGMA-TOKEN: $FIGMA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '<JSON_BODY>' \
  "https://api.figma.com/v1/files/<KEY>/variables"
```

### W7: Display Results

```
Write-Back Complete

  Created: 1 collection, 1 mode, 12 variables
  Updated: 5 variables
  Errors:  0

  View in Figma: https://www.figma.com/file/<KEY>/
```

---

## Reference Files

Load these on-demand as needed during execution — do NOT preload all at startup.

| File | When to load |
|------|-------------|
| `references/w3c-format.md` | After user chooses W3C DTCG format |
| `references/cti-format.md` | After user chooses CTI format |
| `references/figma-api.md` | Before making any API calls (extract or write-back) |
| `references/naming-rules.md` | During token classification and naming (step E3) |
| `references/output-templates.md` | When generating output files (step E5) |

---

## Error Handling

| Error | Action |
|-------|--------|
| HTTP 403 from Figma API | PAT lacks required scopes. Ask user to regenerate with `file_variables:read`, `file_variables:write`, `file_content:read` |
| HTTP 429 (rate limited) | Read `Retry-After` header, wait, retry. Batch requests to minimize calls |
| HTTP 404 | File key is invalid or user lacks access |
| MCP tools unavailable | Fall back to REST API path. Prompt for PAT |
| Invalid/unparseable JSON (write-back) | Show parse error location, ask user to fix |
| Circular alias detected | Report the cycle (A → B → A), skip those tokens, warn user |
| Unresolved alias reference | Skip the token, include in warnings summary |
