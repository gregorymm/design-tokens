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
Physical property leads. Category is always first.

**Semantic:** `{category}-{property}-{role}-{prominence}-{state}`
- `color-bg-primary` (default state implied)
- `color-bg-primary-hover`
- `color-text-on-primary`
- `color-text-error-muted`
- `spacing-padding-md`
- `radius-lg`
- `shadow-md`

**Component:** `{category}-{component}-{property}-{role}-{prominence}-{state}`
- `color-button-bg-accent`
- `color-button-bg-accent-hover`
- `color-button-text-accent`
- `color-input-border-focus`
- `spacing-button-padding-sm`
- `radius-button-md`

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

Figma variables sometimes lack a category prefix. Use these heuristics to distinguish radius from spacing:

| Signal | → Radius | → Spacing |
|--------|----------|-----------|
| Name contains `Radius`, `radius`, `corner`, `round` | Yes | |
| Name contains `padding`, `gap`, `margin`, `space`, `inset` | | Yes |
| Sibling variables in the same collection are named `Radius-*` | Likely radius | |
| Values are small (4-18px) and vary per breakpoint (md/lg/xl/2xl) | Could be either — check siblings |
| Component name is a container/panel/form AND sibling tokens are radius tokens | Likely radius | |
| Figma scope includes `CORNER_RADIUS` | Yes | |
| Figma scope includes `GAP` or `PADDING` | | Yes |

**Rule:** When a variable name like `Container/Large/xl: 16` has no category prefix, check its Figma variable scopes (if available via REST API). If scopes aren't available, check sibling tokens in the same collection — if the collection contains `Radius-*` tokens, assume these are also radius. If truly ambiguous, ask the user.
