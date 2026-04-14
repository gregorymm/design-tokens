# W3C Design Tokens Community Group (DTCG) Format Reference

## Overview

The W3C DTCG format is the modern standard for design token interchange (stable v2025.10). Uses `$`-prefixed fields and nested JSON groups. Supported natively by Style Dictionary v4+, Tokens Studio, and other modern tooling.

**File extension:** `.tokens.json` or `.json`

## Token Object Structure

```json
{
  "token-name": {
    "$value": "<actual value>",
    "$type": "<token type>",
    "$description": "Optional description text",
    "$deprecated": true
  }
}
```

**Required:** `$value`
**Optional:** `$type` (can be inherited from parent group), `$description`, `$deprecated`, `$extensions`

## Supported $type Values

### Atomic Types

| Type | $value format | Example |
|------|--------------|---------|
| `color` | Hex string | `"#3b82f6"`, `"#3b82f680"` (with alpha) |
| `dimension` | Number + unit string | `"16px"`, `"1.5rem"`, `"100%"` |
| `fontFamily` | String or array | `"Inter"`, `["Inter", "sans-serif"]` |
| `fontWeight` | Number or keyword | `400`, `"bold"` |
| `duration` | Duration string | `"200ms"`, `"0.3s"` |
| `cubicBezier` | Array of 4 numbers | `[0.4, 0, 0.2, 1]` |
| `number` | Plain number | `1.5`, `0`, `100` |

### Composite Types

| Type | $value format |
|------|--------------|
| `shadow` | `{ "offsetX": "0px", "offsetY": "2px", "blur": "4px", "spread": "0px", "color": "#00000033" }` |
| `border` | `{ "color": "#e5e7eb", "width": "1px", "style": "solid" }` |
| `typography` | `{ "fontFamily": "Inter", "fontSize": "16px", "fontWeight": 400, "lineHeight": "1.5", "letterSpacing": "0" }` |
| `gradient` | `{ "type": "linear", "angle": "180deg", "stops": [{ "color": "#000", "position": "0%" }, ...] }` |
| `transition` | `{ "duration": "200ms", "timingFunction": [0.4, 0, 0.2, 1], "delay": "0ms" }` |
| `strokeStyle` | `"solid"` or `{ "dashArray": ["2px", "4px"], "lineCap": "round" }` |

## Groups (Nesting)

Any JSON object without `$value` is a group. Groups can set `$type` for all children:

```json
{
  "color": {
    "$type": "color",
    "primitive": {
      "blue": {
        "500": { "$value": "#4b64ff" },
        "600": { "$value": "#3a50cc" }
      }
    }
  }
}
```

All tokens under `color` inherit `$type: "color"` without needing to redeclare it.

## Aliases / References

Use `{}` curly braces with dot-separated path:

```json
{
  "color": {
    "$type": "color",
    "primitive": {
      "blue": {
        "500": { "$value": "#4b64ff" }
      }
    },
    "semantic": {
      "bg": {
        "primary": { "$value": "{color.primitive.blue.500}" }
      }
    }
  }
}
```

Aliases can chain: component → semantic → primitive.

## Complete 3-Layer Example

```json
{
  "color": {
    "$type": "color",
    "primitive": {
      "blue": {
        "500": { "$value": "#4b64ff", "$description": "Brand blue" },
        "600": { "$value": "#3a50cc" },
        "50": { "$value": "#eeeef8" }
      },
      "gray": {
        "900": { "$value": "#0d0d11" },
        "50": { "$value": "#fafafa" }
      },
      "white": { "$value": "#ffffff" }
    },
    "semantic": {
      "bg": {
        "primary": { "$value": "{color.primitive.white}" },
        "primary-hover": { "$value": "{color.primitive.gray.50}" },
        "brand": { "$value": "{color.primitive.blue.500}" },
        "brand-hover": { "$value": "{color.primitive.blue.600}" }
      },
      "text": {
        "primary": { "$value": "{color.primitive.gray.900}" },
        "on-brand": { "$value": "{color.primitive.white}" },
        "brand": { "$value": "{color.primitive.blue.500}" }
      },
      "border": {
        "default": { "$value": "{color.primitive.gray.50}" }
      }
    },
    "component": {
      "button": {
        "accent": {
          "bg": { "$value": "{color.semantic.bg.brand}" },
          "bg-hover": { "$value": "{color.semantic.bg.brand-hover}" },
          "text": { "$value": "{color.semantic.text.on-brand}" }
        }
      }
    }
  },
  "spacing": {
    "$type": "dimension",
    "primitive": {
      "4": { "$value": "4px" },
      "8": { "$value": "8px" },
      "12": { "$value": "12px" },
      "16": { "$value": "16px" },
      "24": { "$value": "24px" }
    },
    "semantic": {
      "padding": {
        "sm": { "$value": "{spacing.primitive.8}" },
        "md": { "$value": "{spacing.primitive.16}" },
        "lg": { "$value": "{spacing.primitive.24}" }
      }
    }
  },
  "radius": {
    "$type": "dimension",
    "primitive": {
      "4": { "$value": "4px" },
      "8": { "$value": "8px" },
      "full": { "$value": "9999px" }
    },
    "semantic": {
      "sm": { "$value": "{radius.primitive.4}" },
      "md": { "$value": "{radius.primitive.8}" },
      "full": { "$value": "{radius.primitive.full}" }
    }
  }
}
```

## Multi-Theme Support

Themes are typically handled via `$extensions` or separate files:

**Option A: Extensions (single file)**
```json
{
  "color": {
    "semantic": {
      "bg": {
        "primary": {
          "$value": "{color.primitive.white}",
          "$extensions": {
            "com.tokens.themes": {
              "dark": "{color.primitive.gray.900}"
            }
          }
        }
      }
    }
  }
}
```

**Option B: Separate theme files (recommended for Style Dictionary)**
```
tokens/
  primitives.json       (shared across themes)
  semantic.light.json   (light theme semantic values)
  semantic.dark.json    (dark theme semantic overrides)
  components.json       (component tokens, shared)
```

## Figma-to-W3C Type Mapping

| Figma resolvedType | W3C $type |
|-------------------|-----------|
| `COLOR` | `color` |
| `FLOAT` (with scope CORNER_RADIUS) | `dimension` |
| `FLOAT` (with scope WIDTH_HEIGHT) | `dimension` |
| `FLOAT` (with scope GAP, padding) | `dimension` |
| `FLOAT` (with scope FONT_SIZE) | `dimension` |
| `FLOAT` (with scope FONT_WEIGHT) | `fontWeight` |
| `FLOAT` (with scope OPACITY) | `number` |
| `FLOAT` (other/generic) | `number` |
| `STRING` (with scope FONT_FAMILY) | `fontFamily` |
| `STRING` (other) | (no standard type — use `$extensions`) |
| `BOOLEAN` | (no standard type — use `$extensions`) |
