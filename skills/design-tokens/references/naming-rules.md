# Token Naming Rules and Classification Taxonomy

## Three-Layer Model

### Layer 1: Primitive Tokens
Raw design values with no semantic meaning. The foundation all other tokens reference.

**What they contain:** Color palette steps, spacing scale, radius scale, font families, font weight values, raw durations.

**Examples:** `blue/500` = `#4B64FF`, `gray/900` = `#0D0D11`, `spacing/4` = `4`, `radius/8` = `8`

**How to detect in Figma:**
- Variables in collections named "Primitives", "Raw", "Core", "Base", "Palette", "Scale"
- Variables with NO aliases in their values (raw hex, number, or string)
- Single-mode collections (no Light/Dark variants — raw values don't change per theme)
- Variables with `hiddenFromPublishing: true` or scopes `[]` (hidden from UI)
- Variable names follow a `{category}/{scale-step}` pattern (e.g., `blue/100`, `blue/200`, `spacing/xs`)

### Layer 2: Semantic Tokens
Contextual roles assigned to primitive values. These change between themes.

**What they contain:** Background colors, text colors, border colors, functional spacing (padding, gap), feedback colors (success, warning, error).

**Examples:** `color/bg/primary`, `color/text/brand`, `spacing/padding/md`, `radius/component/lg`

**How to detect in Figma:**
- Variables that alias other variables (`type: "VARIABLE_ALIAS"`)
- Multi-mode collections (Light/Dark/High Contrast — semantic tokens switch primitives per theme)
- Collections named "Semantic", "Theme", "Alias", "Color", "Tokens"
- Variable names follow a `{category}/{property}/{role}` pattern (e.g., `color/bg/primary`, `color/text/error`)

### Layer 3: Component Tokens
Component-specific overrides that reference semantic tokens. Used when a component needs to deviate from the semantic default.

**What they contain:** Button background, input border, card shadow, modal overlay — tied to a specific component.

**Examples:** `button/bg/accent`, `input/border/focus`, `card/shadow/default`

**How to detect in Figma:**
- Variables in collections named after components ("Button", "Input", "Card", "Components")
- Variables whose names start with a component name (e.g., `button/...`, `card/...`)
- Variables applied to specific components via scoping
- Variables that alias semantic tokens (component → semantic → primitive chain)

### Fallback Classification
If Figma structure is flat or ambiguous:
1. Variables with NO aliases and raw values → Primitive
2. Variables with aliases to other variables → Semantic (or Component if name contains a component name)
3. If unclear, ask the user to classify the collection

---

## Naming Taxonomy

### Categories (top-level grouping)
| Category | What it covers | CSS property mapping |
|----------|---------------|---------------------|
| `color` | All colors (fills, text, borders, etc.) | `color`, `background-color`, `border-color` |
| `spacing` | Padding, margin, gap | `padding`, `margin`, `gap` |
| `size` | Width, height, icon sizes | `width`, `height` |
| `radius` | Border radius | `border-radius` |
| `shadow` | Box shadows, drop shadows | `box-shadow` |
| `font` | Font family, weight, size, line-height | `font-family`, `font-weight`, `font-size`, `line-height` |
| `opacity` | Transparency values | `opacity` |
| `z-index` | Stacking layers | `z-index` |
| `duration` | Animation timing | `transition-duration`, `animation-duration` |
| `easing` | Animation curves | `transition-timing-function` |

### Properties (what the category applies to)
| Property | Meaning | Used with |
|----------|---------|-----------|
| `bg` / `surface` | Background fill | `color` |
| `text` | Text color | `color` |
| `border` | Border/stroke color | `color` |
| `icon` | Icon color | `color` |
| `outline` / `ring` | Focus ring color | `color` |
| `overlay` | Backdrop/overlay | `color`, `opacity` |
| `padding` | Inner spacing | `spacing` |
| `gap` | Flex/grid gap | `spacing` |
| `margin` | Outer spacing | `spacing` |

### Roles (semantic meaning)
| Role | Meaning |
|------|---------|
| `primary` | Main/default action or surface |
| `secondary` | Supporting action or surface |
| `tertiary` | Third-level, subtle |
| `brand` / `accent` | Brand color |
| `success` | Positive feedback (green) |
| `warning` | Caution feedback (yellow/amber) |
| `danger` / `error` | Negative feedback (red) |
| `neutral` | Gray/neutral tones |
| `inverse` | For dark backgrounds (inverted contrast) |
| `static` | Does not change across themes (always white, always black) |

### Prominence (intensity variants within a role)
| Prominence | Meaning |
|------------|---------|
| `default` / `main` / `base` | Standard — **omitted from name** (implied) |
| `muted` | Softer version |
| `subtle` | Very light, barely visible |
| `intense` | Stronger version |
| `on-{role}` | Content color placed on top of `{role}` surface |

### States (interactive modifiers)
| State | When |
|-------|------|
| `hover` | Mouse over |
| `active` / `pressed` | Mouse down / tap |
| `focus` | Keyboard focus |
| `disabled` | Inactive |
| `selected` | Toggled on |
| `visited` | Link visited |

### Sizes (scale modifiers)
`xs`, `sm`, `md`, `lg`, `xl`, `2xl`, `3xl` — or numeric: `2`, `4`, `8`, `12`, `16`, `24`, `32`

---

## Naming Formulas

### CTI Format
Physical category leads. Category is always first.

**Note on variants:** two CTI orderings exist in the wild. The strict Style Dictionary formula is `Category-Type-Item-Subitem-State` (property before component, e.g. `color-bg-button-primary`). The community convention used by many design systems — and followed by this skill — is `Category-Component-Property-Role-State` (component before property, e.g. `color-button-bg-primary`). The community variant keeps all `button` tokens grouped together in filenames and IDE autocomplete, which is more ergonomic for component-based frontends.

**Semantic:** `{category}-{property}-{role}-{prominence}-{state}`
- `color-bg-primary` (default state implied)
- `color-bg-primary-hover`
- `color-bg-brand`
- `color-text-on-primary`
- `color-text-error-muted`
- `spacing-padding-md`
- `radius-lg`
- `shadow-md`

**Component:** `{category}-{component}-{property}-{role}-{prominence}-{state}`

Component name comes right after the category, then property, then role. Groups all tokens for a component together.
- `color-button-bg-primary` (Category=color, Component=button, Property=bg, Role=primary)
- `color-button-bg-primary-hover`
- `color-button-text-primary`
- `color-input-border-focus`
- `radius-button-md`
- `spacing-button-padding-sm`

### W3C Format
Component/context leads. Category is at the end.

**Semantic:** `{context}-{role}-{prominence}-{category}-{state}`
- `bg-primary-color` (default state implied)
- `bg-primary-color-hover`
- `text-on-primary-color`
- `text-error-muted-color`
- `padding-md-size`
- `radius-lg-size`
- `shadow-md`

**Component:** `{component}-{variant}-{element}-{category}-{state}`
- `button-accent-bg-color`
- `button-accent-bg-color-hover`
- `button-accent-label-color`
- `input-border-color-focus`
- `button-padding-size-sm`
- `button-radius-size`

---

## Figma Name to Token Path Conversion

Figma variable names use `/` as separator: `color/bg/primary`

| Target | Separator | Prefix | Example |
|--------|-----------|--------|---------|
| JSON nesting | `.` (dot) | none | `color.bg.primary` |
| CSS variable | `-` (dash) | `--` | `--color-bg-primary` |
| SCSS variable | `-` (dash) | `$` | `$color-bg-primary` |
| W3C alias ref | `.` (dot) | `{` `}` | `{color.bg.primary}` |
| CTI alias ref | `.` (dot) | `{` `}` | `{color.bg.primary}` |

Conversion: replace `/` with the target separator, add prefix if needed.

---

## Disambiguation: Radius vs Spacing

This is the most common classification mistake. Follow these rules in order — do not skip ahead.

### Rule 1 — Prefix consistency (strongest signal)

**If any token in the file is explicitly prefixed with a category marker (e.g., `Radius-`), then tokens WITHOUT that prefix are NOT in that category.**

Example from a real design system:

```
Radius-Button-small/xl: 6      ← explicit "Radius-" prefix → radius
Radius-Button-icon/xs: 5       ← explicit "Radius-" prefix → radius
Radius-Pop-over/md: 9          ← explicit "Radius-" prefix → radius
Container/Large/xl: 16         ← NO "Radius-" prefix → NOT radius (likely spacing)
Form-large/md: 12              ← NO "Radius-" prefix → NOT radius (likely spacing)
Control-panel/Panel-item/md: 6 ← NO "Radius-" prefix → NOT radius (likely spacing)
```

**Why:** If the author wanted these to be radius tokens, they would have named them `Radius-Container/Large/xl` — consistent with the existing convention. The absence of the prefix is a deliberate signal.

### Rule 2 — Explicit category words

| Token name contains | Category |
|--------------------|----------|
| `Radius`, `radius`, `corner`, `round` | radius |
| `Padding`, `padding`, `gap`, `margin`, `inset`, `space`, `spacing` | spacing |
| `Size`, `width`, `height` | size |
| `Font`, `text`, `type` | font |

### Rule 3 — Figma variable scopes (if available via REST API)

| Scope field | Category |
|------------|----------|
| `CORNER_RADIUS` | radius |
| `GAP`, padding scopes | spacing |
| `WIDTH_HEIGHT` | size |
| `FONT_SIZE`, `FONT_WEIGHT`, etc. | font |

### Rule 4 — Common UI component semantics

| Component name in token | Most likely category |
|-------------------------|---------------------|
| `Container`, `Form`, `Panel`, `Card body` | spacing (inner padding) |
| `Button-icon`, `Button-small`, `Pop-over`, `Avatar` | radius (small rounded shapes) |

### Rule 5 — Ask if ambiguous

If none of the above give a confident answer, ask the user:

> "I found these tokens with ambiguous names: `Container/Large/xl: 16`, `Form-large/md: 12`. These could be either border-radius or padding/spacing values. What category do they belong to?"

**Never guess silently.** A silent misclassification is a bug that ships to the user's code.
