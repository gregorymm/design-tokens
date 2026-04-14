# Category/Type/Item (CTI) Format Reference

## Overview

CTI is the legacy/widespread naming convention popularized by Style Dictionary. Physical property (Category) leads the hierarchy. Default format for Style Dictionary v3, still widely used in Amazon Cloudscape, Salesforce Lightning, GitHub Primer, and Shopify Polaris.

**File extension:** `.json`

## Token Object Structure

```json
{
  "token-name": {
    "value": "<actual value>",
    "type": "<token type>",
    "comment": "Optional description",
    "description": "Alternative description field"
  }
}
```

**Required:** `value`
**Optional:** `type`, `comment` or `description`, `attributes`, `filePath`, `original`

## Nesting Convention

Category → Type → Item → Sub-item → State

```json
{
  "color": {
    "bg": {
      "primary": {
        "value": "#ffffff",
        "type": "color"
      }
    }
  }
}
```

The key hierarchy IS the naming: `color.bg.primary` → CSS variable `--color-bg-primary`.

## Aliases / References

Same syntax as W3C — curly braces with dot path:

```json
{
  "color": {
    "primitive": {
      "blue": {
        "500": { "value": "#4b64ff" }
      }
    },
    "bg": {
      "primary": {
        "value": "{color.primitive.blue.500}"
      }
    }
  }
}
```

## Complete 3-Layer Example

```json
{
  "color": {
    "primitive": {
      "blue": {
        "500": { "value": "#4b64ff", "type": "color", "comment": "Brand blue" },
        "600": { "value": "#3a50cc", "type": "color" },
        "50": { "value": "#eeeef8", "type": "color" }
      },
      "gray": {
        "900": { "value": "#0d0d11", "type": "color" },
        "50": { "value": "#fafafa", "type": "color" }
      },
      "white": { "value": "#ffffff", "type": "color" }
    },
    "bg": {
      "primary": { "value": "{color.primitive.white}", "type": "color" },
      "primary-hover": { "value": "{color.primitive.gray.50}", "type": "color" },
      "brand": { "value": "{color.primitive.blue.500}", "type": "color" },
      "brand-hover": { "value": "{color.primitive.blue.600}", "type": "color" }
    },
    "text": {
      "primary": { "value": "{color.primitive.gray.900}", "type": "color" },
      "on-brand": { "value": "{color.primitive.white}", "type": "color" },
      "brand": { "value": "{color.primitive.blue.500}", "type": "color" }
    },
    "border": {
      "default": { "value": "{color.primitive.gray.50}", "type": "color" }
    },
    "button": {
      "bg": {
        "accent": { "value": "{color.bg.brand}", "type": "color" },
        "accent-hover": { "value": "{color.bg.brand-hover}", "type": "color" }
      },
      "text": {
        "accent": { "value": "{color.text.on-brand}", "type": "color" }
      }
    }
  },
  "spacing": {
    "primitive": {
      "4": { "value": "4px", "type": "dimension" },
      "8": { "value": "8px", "type": "dimension" },
      "12": { "value": "12px", "type": "dimension" },
      "16": { "value": "16px", "type": "dimension" },
      "24": { "value": "24px", "type": "dimension" }
    },
    "padding": {
      "sm": { "value": "{spacing.primitive.8}", "type": "dimension" },
      "md": { "value": "{spacing.primitive.16}", "type": "dimension" },
      "lg": { "value": "{spacing.primitive.24}", "type": "dimension" }
    }
  },
  "radius": {
    "primitive": {
      "4": { "value": "4px", "type": "dimension" },
      "8": { "value": "8px", "type": "dimension" },
      "full": { "value": "9999px", "type": "dimension" }
    },
    "sm": { "value": "{radius.primitive.4}", "type": "dimension" },
    "md": { "value": "{radius.primitive.8}", "type": "dimension" },
    "full": { "value": "{radius.primitive.full}", "type": "dimension" }
  }
}
```

## Deprecated Tokens

Mark deprecated tokens in the `description` or `comment` field:

```json
{
  "color": {
    "bg": {
      "muted": {
        "value": "#71717A",
        "type": "color",
        "comment": "@deprecated Use color-bg-secondary instead"
      }
    }
  }
}
```

Style Dictionary can auto-generate `console.warn` for deprecated tokens.

## Multi-Theme Support (CTI)

**Option A: Separate files per theme**
```
tokens/
  color/
    primitive.json    (shared)
    light.json        (light theme overrides)
    dark.json         (dark theme overrides)
  spacing/
    base.json         (shared)
```

**Option B: Platform-specific theme files with SD config**
```json
{
  "source": ["tokens/primitive.json", "tokens/light.json"],
  "platforms": {
    "css/light": {
      "transformGroup": "css",
      "buildPath": "build/css/",
      "files": [{ "destination": "light.css", "format": "css/variables" }]
    }
  }
}
```

## Style Dictionary Config (v3)

```json
{
  "source": ["tokens/**/*.json"],
  "platforms": {
    "css": {
      "transformGroup": "css",
      "prefix": "token",
      "buildPath": "build/css/",
      "files": [
        {
          "destination": "variables.css",
          "format": "css/variables"
        }
      ]
    },
    "scss": {
      "transformGroup": "scss",
      "prefix": "token",
      "buildPath": "build/scss/",
      "files": [
        {
          "destination": "_variables.scss",
          "format": "scss/variables"
        }
      ]
    }
  }
}
```

Build: `npx style-dictionary build`

## Figma-to-CTI Type Mapping

| Figma resolvedType | CTI type | CTI category |
|-------------------|----------|-------------|
| `COLOR` | `color` | `color` |
| `FLOAT` (radius scope) | `dimension` | `radius` |
| `FLOAT` (size scope) | `dimension` | `size` |
| `FLOAT` (spacing scope) | `dimension` | `spacing` |
| `FLOAT` (font-size scope) | `dimension` | `font` |
| `FLOAT` (font-weight scope) | `fontWeight` | `font` |
| `FLOAT` (opacity scope) | `opacity` | `opacity` |
| `FLOAT` (generic) | `number` | varies |
| `STRING` (font-family scope) | `fontFamily` | `font` |
| `STRING` (generic) | `string` | varies |
| `BOOLEAN` | `boolean` | varies |
