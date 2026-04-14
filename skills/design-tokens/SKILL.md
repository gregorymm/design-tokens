---
name: design-tokens
description: Extract design tokens from Figma design system files (variables, styles, component properties) into W3C DTCG or CTI format. Generates tokens.json, tokens.css, tokens.scss, and Style Dictionary config. Supports write-back to push local token changes into Figma variables via REST API. Triggers on "extract tokens", "design tokens", "figma tokens", "token export", "export variables from figma", "write tokens back", "push tokens to figma", "sync tokens".
user-invocable: true
version: 1.0.0
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

**Before choosing the access method, ask the user what Figma plan their org is on.** This is critical because the Figma Variables REST API is **Enterprise-only**.

```
What Figma plan is your organization on?

   1) Starter / Professional / Organization
   2) Enterprise
   3) Not sure — I'll check
```

If the user answers **1 (non-Enterprise)**:
- The REST API cannot read or write Figma Variables (`file_variables:*` scopes don't exist on their plan)
- Recommend the **Figma Desktop MCP path** (works on all plans)
- OR offer **styles-only REST extraction** (typography, effects, color styles — no variables)
- Write-back is not available

If the user answers **2 (Enterprise)**:
- Both MCP and REST API paths work
- Write-back via REST API is available

If the user answers **3 (not sure)**: have them check `figma.com/settings → Personal access tokens → Create new token`. If "File variables" appears as a scope checkbox, they're on Enterprise. If not, they're on a lower tier.

Then present the access method:

```
How to connect to Figma?

   A) Figma Desktop MCP — Figma app must be open (read-only, works on any plan)
   B) REST API — Personal Access Token (Enterprise required for variables; other plans only get styles/nodes)
```

**MCP path:** Use `mcp__Figma__get_variable_defs` and `mcp__Figma__get_design_context`. The Figma desktop app must have the target file open. MCP tools are read-only — cannot write back.

**REST API path (Enterprise):** Prompt for `FIGMA_TOKEN` with scopes `file_variables:read`, `file_variables:write` (if writing back), `file_content:read`.

**REST API path (non-Enterprise, styles-only):** Prompt for `FIGMA_TOKEN` with just `file_content:read`. Skip the `/variables/local` call; use only `/styles` and `/nodes` endpoints. The output will include typography, effects, and color styles but NOT Figma Variables.

**Important:** Write-back flow always requires REST API on **Enterprise**.

Read `references/figma-api.md` for endpoint details and plan requirements table.

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

### E8: Offer Write-Back (ALWAYS PROMPT)

**MANDATORY.** After displaying the extraction summary, always offer to push the extracted tokens back into Figma and rebind existing layers. This is the promise of bidirectional sync — don't skip it.

Write-back works on **all paid plans** (Professional, Organization, Enterprise) — but the method differs:

- **Enterprise** → REST API (fast, headless, batch)
- **Professional / Organization** → generated Figma plugin (skill writes a small plugin, user runs it once in Figma desktop)
- **Starter (free)** → not supported; recommend upgrading or using Tokens Studio

Present the prompt:

```
Push these tokens back to Figma and rebind layers?

   A) Yes — create missing variables AND rebind existing layers
      (components stop using raw hex, start referencing the new variables)
   B) Variables only — create/update Figma variables but DO NOT rebind layers
   C) No — skip write-back, I'll use the generated files only
```

Then route by the plan tier collected in Step 3:

| User's plan | Option A | Option B | Option C |
|------------|----------|----------|----------|
| Enterprise | Run REST Write-Back (W1–W7) → REST Layer Rebind (R1–R4) | Run REST Write-Back only (W1–W7) | End |
| Professional / Organization | Generate Figma Plugin (P1–P4) with variables + rebind | Generate Figma Plugin (P1–P4) with variables only | End |
| Starter (free) | Show note below | Show note below | End |

**For Starter plan users only:**

```
Write-back requires a paid Figma plan (Professional or higher).
Alternatives:
  - Use Tokens Studio plugin to import your tokens.json
  - Upgrade your Figma plan
  - Use the generated CSS/SCSS files directly in code (no Figma sync)
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

## Layer Rebind Flow (Figma Enterprise, after Write-Back)

This flow runs only when the user picks option **A** in step E8 (Push tokens back AND rebind layers). It walks every component/layer in the target Figma file(s) and replaces raw hex values / unbound properties with references to the newly-created or updated variables.

**Prerequisite:** Write-Back Flow (W1–W7) has completed successfully and you have the `{variablePath → variableId}` map from step W3 (expanded with any new IDs returned by the POST call in W6).

### R1: Enumerate All Layers Using Raw Values

For each Figma file in scope, fetch the full document tree:

```bash
curl -s -H "X-FIGMA-TOKEN: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/<KEY>?geometry=paths"
```

Recursively walk every node. For each node, collect properties that could be rebound:

| Node property | Token category | Binding field |
|--------------|----------------|---------------|
| `fills[].color` (SOLID paint) | color | `boundVariables.fills` |
| `strokes[].color` (SOLID paint) | color | `boundVariables.strokes` |
| `effects[].color` (DROP_SHADOW, INNER_SHADOW) | color | `boundVariables.effects` |
| `cornerRadius` (number) | radius | `boundVariables.cornerRadius` |
| `itemSpacing` (number) | spacing | `boundVariables.itemSpacing` |
| `paddingLeft` / `paddingRight` / `paddingTop` / `paddingBottom` | spacing | `boundVariables.paddingLeft` etc. |
| `style.fontSize`, `fontWeight`, `fontFamily`, `lineHeightPx`, `letterSpacing` | font | `boundVariables.<prop>` on text nodes |

**Skip nodes that already have `boundVariables` for a given property** — they're already using a variable.

### R2: Match Raw Values to Tokens

For each unbound raw value found in R1, look up whether a matching variable exists in the `{value → variableId}` reverse map built from the extracted tokens. Matching rules:

- **Colors:** exact hex match (normalize both sides to `#RRGGBB` or `#RRGGBBAA`). For near-matches (ΔE < 2), prompt the user; don't auto-rebind.
- **Numbers (radius, spacing):** exact match.
- **Font properties:** exact family/weight/size match.

Build a **rebind plan** — a list of `{nodeId, property, variableId}` tuples for every match.

### R3: Preview the Rebind

Display a summary before executing any changes:

```
Layer Rebind Preview

  Total layers scanned:      1,248
  Layers using raw values:     312
  Exact matches to tokens:     287
  Near-matches (not rebinding): 18
  No match (kept as raw):       7

  Rebind breakdown:
    fills:          184 layers (color tokens)
    strokes:         42 layers (color tokens)
    effects:         16 layers (color tokens)
    cornerRadius:    28 layers (radius tokens)
    padding/gap:      9 layers (spacing tokens)
    typography:       8 layers (font tokens)

  Proceed with rebind? (y/n)
```

**Never auto-execute.** Wait for explicit user confirmation.

### R4: Execute the Rebind

Figma's variable binding API uses `POST /v1/files/:key/variables` for variable CRUD, but binding variables to layer properties requires a different endpoint. Use the **`PUT /v1/files/:key/nodes`** endpoint (or the equivalent plugin API via a helper plugin) with a request body specifying `boundVariables` for each target node.

**Batch constraints:**
- Group rebinds by file — one request per file
- Max request body size: 4MB; split into multiple requests if exceeded
- Rate limit: Tier 3 writes (50–150 req/min depending on plan)

**Important caveat:** The Figma REST API has limited support for writing `boundVariables` on existing nodes. If the direct REST path fails, the skill should:
1. Report the affected nodes and the target variable IDs
2. Offer to generate a **Figma plugin manifest** that the user can run inside Figma desktop — a plugin has full Plugin API access to `node.setBoundVariable(field, variable)`, which is more reliable than REST for this operation
3. OR tell the user to manually rebind via Figma's variable picker on each flagged layer (only viable for small sets)

After execution, display results:

```
Layer Rebind Complete

  Successfully rebound: 287 properties across 312 layers
  Failed:                 0 layers
  Skipped (near-match):  18 layers — flagged for manual review
  Skipped (no match):     7 layers — kept as raw values

  View in Figma: https://www.figma.com/file/<KEY>/
```

**Benefits of rebinding:**
- Components stop using raw hex and start referencing variables
- Changing a token value in one place now propagates to every bound layer automatically
- Future theme additions (dark mode, brand skin) work immediately on all rebound layers
- Removes "drift" where a color is used in 40 places with slight variations

---

## Figma Plugin Flow (Professional / Organization plans)

When the user is on Professional or Organization and wants to write back, the skill generates a small Figma plugin they load once in the desktop app. The plugin reads `tokens.json` and uses the Plugin API (`figma.variables.*` + `node.setBoundVariable()`) to create/update variables and rebind layers — no Enterprise required.

### P1: Generate Plugin Files

Create a plugin directory alongside the tokens output (default `./design-tokens/figma-plugin/`):

```
design-tokens/figma-plugin/
  manifest.json          # Plugin manifest
  code.js                # Main plugin code (reads tokens, applies to Figma)
  ui.html                # Simple UI with "Apply tokens" + "Rebind layers" buttons
  tokens.json            # Copy of the extracted tokens the plugin reads
```

**manifest.json:**
```json
{
  "name": "Design Tokens Sync",
  "id": "design-tokens-sync",
  "api": "1.0.0",
  "main": "code.js",
  "ui": "ui.html",
  "editorType": ["figma"],
  "networkAccess": { "allowedDomains": ["none"] }
}
```

**code.js** should contain:
- Parse the embedded `tokens.json`
- `ensureCollection(name)` — find or create a variable collection
- `ensureVariable(path, type, collection)` — find or create a variable by path
- `setValue(variable, modeId, value)` — set raw value or `VARIABLE_ALIAS` reference
- `rebindLayers()` — walk `figma.root.findAll()`, match raw fills/strokes/radius/padding to tokens, call `node.setBoundVariable(field, variable)` for each match
- Message bridge to `ui.html` for progress/confirmation

**ui.html:** a minimal UI with:
- Two buttons: `Apply tokens` (variables only) and `Apply + Rebind layers`
- Progress output area
- Error display

### P2: Instruct the User

Show step-by-step setup in the chat:

```
Generated Figma plugin at: ./design-tokens/figma-plugin/

To use it:
  1. Open Figma desktop → right-click your design file → "Plugins" → "Development" → "Import plugin from manifest..."
  2. Select ./design-tokens/figma-plugin/manifest.json
  3. The plugin will appear under "Plugins → Development → Design Tokens Sync"
  4. Run it in each file you want to sync
  5. Click "Apply + Rebind layers" to push tokens AND rebind, or "Apply tokens" for variables only

The plugin reads tokens.json embedded in its folder — re-run extraction to update.
```

### P3: Handle Multi-File Sync

If the user extracted from multiple Figma files, note that:
- The plugin must be run once per file (Figma plugins run inside one document at a time)
- The plugin can share one tokens.json across all runs
- Alternatively, generate per-file plugins if token subsets differ

### P4: Verify

After the user reports the plugin has run, optionally re-run the extraction flow on the same file(s) to verify variables and bindings. Compare the new extraction against the original — all tokens should now exist as Figma variables, and the warnings about "raw values used in components" should be reduced.

### Plugin API Limitations

The Plugin API has some quirks:
- **Cannot publish variables to libraries** from a plugin on Free plan — Team library publishing requires a paid plan UI action
- **`setBoundVariable()` only works on supported fields** — fills, strokes, effects (color), cornerRadius, item spacing, padding, width/height, typography fields
- **Alias chains** — semantic → primitive aliases must be created in order (primitives first) because aliases reference Figma IDs that don't exist until creation completes

---

## Reference Files

Load these on-demand as needed during execution — do NOT preload all at startup.

| File | When to load |
|------|-------------|
| `references/w3c-format.md` | After user chooses W3C DTCG format |
| `references/cti-format.md` | After user chooses CTI format |
| `references/figma-api.md` | Before making any API calls (extract, write-back, or layer rebind) |
| `references/naming-rules.md` | During token classification and naming (step E3) |
| `references/output-templates.md` | When generating output files (step E5) |

---

## Error Handling

| Error | Action |
|-------|--------|
| HTTP 403 on `/variables/local` or `POST /variables` | Likely means the Figma org is NOT on Enterprise plan. The `file_variables:*` scopes only exist on Enterprise. Offer: switch to MCP path, or continue with styles-only extraction via `/styles` + `/nodes` |
| HTTP 403 on `/styles` or `/nodes` | PAT is missing `file_content:read`. Ask user to regenerate the PAT with that scope |
| HTTP 429 (rate limited) | Read `Retry-After` header, wait, retry. Batch requests to minimize calls |
| HTTP 404 | File key is invalid or user lacks access |
| MCP tools unavailable | Fall back to REST API path. Prompt for PAT |
| Invalid/unparseable JSON (write-back) | Show parse error location, ask user to fix |
| Circular alias detected | Report the cycle (A → B → A), skip those tokens, warn user |
| Unresolved alias reference | Skip the token, include in warnings summary |
