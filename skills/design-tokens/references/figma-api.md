# Figma REST API Reference for Design Tokens

## ⚠️ Plan Requirements (IMPORTANT)

**The Figma Variables REST API is Enterprise-only.** The `file_variables:read` and `file_variables:write` scopes only appear in PAT settings for users on Figma Enterprise plans.

| Figma Plan | `/styles` endpoint | `/nodes` endpoint | `/variables/local` endpoint | Write-back `POST /variables` |
|------------|-------------------|-------------------|---------------------------|------------------------------|
| Starter / Professional / Organization | ✅ | ✅ | ❌ 403 | ❌ 403 |
| Enterprise | ✅ | ✅ | ✅ | ✅ |

**Before prompting for a PAT, ask the user what Figma plan they're on.** If they're not on Enterprise:
- Recommend the **Figma Desktop MCP path** instead (works on all plans)
- Or fall back to **styles-only extraction** via REST API (no variables, but typography/effects/color styles still work)
- Write-back is not possible — only available on Enterprise

## Authentication

All requests require a Personal Access Token (PAT) in the header:

```
X-FIGMA-TOKEN: <your-pat>
```

**Required scopes:**
- `file_content:read` — read nodes, styles, component properties (all plans)
- `file_variables:read` — read variables and collections (**Enterprise only**)
- `file_variables:write` — create/update variables for write-back (**Enterprise only**)

## Extracting File Keys from URLs

Figma URLs follow these patterns:
```
https://www.figma.com/design/<fileKey>/<fileName>?node-id=<nodeId>
https://www.figma.com/file/<fileKey>/<fileName>
https://figma.com/design/<fileKey>/branch/<branchKey>/<fileName>
```

Extract `fileKey` from the path. For branch URLs, use `branchKey` as the file key.

---

## GET /v1/files/:file_key?depth=2 (File Tree — Page Enumeration)

Returns the document structure at a shallow depth. Use to enumerate all pages in the file.

```bash
curl -s -H "X-FIGMA-TOKEN: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/<FILE_KEY>?depth=2"
```

**Response (relevant fields):**
```json
{
  "document": {
    "children": [
      { "id": "0:1", "name": "Page 1 — Buttons", "type": "CANVAS" },
      { "id": "0:2", "name": "Page 2 — Inputs", "type": "CANVAS" },
      { "id": "0:3", "name": "Page 3 — Feedback", "type": "CANVAS" }
    ]
  }
}
```

Each child with `type: "CANVAS"` is a page. Use page IDs with the `/nodes` endpoint to drill into each page's contents.

---

## GET /v1/files/:file_key/components (All Components)

Returns ALL published components across ALL pages in a file.

```bash
curl -s -H "X-FIGMA-TOKEN: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/<FILE_KEY>/components"
```

**Response:**
```json
{
  "meta": {
    "components": [
      {
        "key": "abc123",
        "file_key": "FILE_KEY",
        "node_id": "129:10493",
        "name": "Type=Primary, State=Default, Size=md",
        "description": "",
        "containing_frame": {
          "name": "Button",
          "nodeId": "129:10490",
          "pageName": "Buttons"
        }
      }
    ]
  }
}
```

**Key fields:**
- `node_id`: Use with `/nodes?ids=` to get full properties
- `name`: Contains variant property values (e.g., `Type=Primary, State=Default, Size=md`)
- `containing_frame.name`: The component set name (e.g., "Button")
- `containing_frame.pageName`: Which page the component lives on

Parse `name` to extract variant properties: split by `, `, then each segment by `=`.

---

## GET /v1/files/:file_key/component_sets (Component Sets)

Returns component sets (the parent frames that group variant components).

```bash
curl -s -H "X-FIGMA-TOKEN: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/<FILE_KEY>/component_sets"
```

**Response:**
```json
{
  "meta": {
    "component_sets": [
      {
        "key": "def456",
        "file_key": "FILE_KEY",
        "node_id": "129:10490",
        "name": "Button",
        "description": "Primary action button with multiple variants"
      }
    ]
  }
}
```

Use component set `node_id` with `/nodes?ids=` to get all variant children and their properties.

---

## GET /v1/files/:file_key/variables/local

Returns all local variables and collections in the file.

**Curl example:**
```bash
curl -s -H "X-FIGMA-TOKEN: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/<FILE_KEY>/variables/local"
```

**Response schema:**
```json
{
  "status": 200,
  "meta": {
    "variableCollections": {
      "VariableCollectionId:1:2": {
        "id": "VariableCollectionId:1:2",
        "name": "Primitives",
        "key": "abc123",
        "modes": [
          { "modeId": "1:0", "name": "Value" }
        ],
        "defaultModeId": "1:0",
        "remote": false,
        "hiddenFromPublishing": false,
        "variableIds": ["VariableID:1:3", "VariableID:1:4"]
      }
    },
    "variables": {
      "VariableID:1:3": {
        "id": "VariableID:1:3",
        "name": "blue/500",
        "key": "def456",
        "variableCollectionId": "VariableCollectionId:1:2",
        "resolvedType": "COLOR",
        "description": "",
        "hiddenFromPublishing": false,
        "scopes": ["ALL_SCOPES"],
        "codeSyntax": {},
        "valuesByMode": {
          "1:0": {
            "r": 0.29411764705882354,
            "g": 0.39215686274509803,
            "b": 1,
            "a": 1
          }
        }
      },
      "VariableID:2:1": {
        "id": "VariableID:2:1",
        "name": "bg/primary",
        "variableCollectionId": "VariableCollectionId:2:0",
        "resolvedType": "COLOR",
        "valuesByMode": {
          "2:0": {
            "type": "VARIABLE_ALIAS",
            "id": "VariableID:1:3"
          },
          "2:1": {
            "type": "VARIABLE_ALIAS",
            "id": "VariableID:1:10"
          }
        }
      }
    }
  }
}
```

**Key fields:**
- `resolvedType`: `COLOR`, `FLOAT`, `STRING`, or `BOOLEAN`
- `valuesByMode`: Map of modeId to value. Values are either:
  - Raw color: `{ r, g, b, a }` (0-1 normalized)
  - Raw number: a plain number (e.g., `16`)
  - Raw string: a plain string
  - Raw boolean: `true`/`false`
  - Alias: `{ type: "VARIABLE_ALIAS", id: "VariableID:x:y" }`
- `scopes`: Controls where variable appears in Figma UI. Values: `ALL_SCOPES`, `ALL_FILLS`, `FRAME_FILL`, `SHAPE_FILL`, `TEXT_FILL`, `STROKE_COLOR`, `CORNER_RADIUS`, `WIDTH_HEIGHT`, `GAP`, `FONT_FAMILY`, `FONT_STYLE`, `FONT_WEIGHT`, `FONT_SIZE`, `LINE_HEIGHT`, `LETTER_SPACING`, `OPACITY`, `EFFECT_COLOR`
- `name`: Figma uses `/` as path separator (e.g., `color/bg/primary`)

---

## GET /v1/files/:file_key/variables/published

Returns only published variables (for library consumption). Same structure but:
- Each variable has an additional `subscribed_id` field
- Modes are omitted from collections
- Includes `updatedAt` timestamps

---

## POST /v1/files/:file_key/variables

Creates, updates, or deletes variable collections, modes, variables, and values.

**Curl example:**
```bash
curl -s -X POST \
  -H "X-FIGMA-TOKEN: $FIGMA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '<JSON_BODY>' \
  "https://api.figma.com/v1/files/<FILE_KEY>/variables"
```

**Request body schema:**
```json
{
  "variableCollections": [
    {
      "action": "CREATE",
      "id": "temp-collection-1",
      "name": "Primitives",
      "initialModeId": "temp-mode-light"
    },
    {
      "action": "UPDATE",
      "id": "VariableCollectionId:existing",
      "name": "Renamed Collection"
    }
  ],
  "variableModes": [
    {
      "action": "CREATE",
      "id": "temp-mode-dark",
      "name": "Dark",
      "variableCollectionId": "temp-collection-1"
    }
  ],
  "variables": [
    {
      "action": "CREATE",
      "id": "temp-var-blue500",
      "name": "blue/500",
      "variableCollectionId": "temp-collection-1",
      "resolvedType": "COLOR",
      "description": "Primary blue",
      "scopes": ["ALL_FILLS"]
    },
    {
      "action": "UPDATE",
      "id": "VariableID:existing",
      "name": "updated-name",
      "description": "Updated description"
    }
  ],
  "variableModeValues": [
    {
      "variableId": "temp-var-blue500",
      "modeId": "temp-mode-light",
      "value": { "r": 0.294, "g": 0.392, "b": 1.0, "a": 1.0 }
    },
    {
      "variableId": "temp-var-bg-primary",
      "modeId": "temp-mode-light",
      "value": { "type": "VARIABLE_ALIAS", "id": "temp-var-blue500" }
    }
  ]
}
```

**Rules:**
- `action` must be `CREATE`, `UPDATE`, or `DELETE`
- For CREATE: use temporary string IDs (e.g., `"temp-var-1"`). The response returns the real IDs.
- Temporary IDs can be referenced within the same request (e.g., a variable referencing a temp collection ID)
- **Order matters for aliases:** Primitive variables must be created before semantic variables that alias them. Include both in the same request — Figma resolves temp IDs internally.
- Color values use 0-1 RGBA: `{ r: 0.294, g: 0.392, b: 1.0, a: 1.0 }`
- Number values are plain numbers: `16`
- String values are plain strings: `"Inter"`
- Boolean values are `true`/`false`
- Maximum request body size: 4MB

**Response:** Returns the created/updated objects with real IDs.

---

## GET /v1/files/:file_key/styles

Returns style metadata (paint, text, effect, grid styles).

```bash
curl -s -H "X-FIGMA-TOKEN: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/<FILE_KEY>/styles"
```

**Response:**
```json
{
  "meta": {
    "styles": [
      {
        "key": "abc123",
        "file_key": "FILE_KEY",
        "node_id": "123:456",
        "style_type": "FILL",
        "name": "Primary Color",
        "description": "Main brand color"
      },
      {
        "key": "def456",
        "node_id": "789:012",
        "style_type": "TEXT",
        "name": "Heading / Large",
        "description": ""
      }
    ]
  }
}
```

**Style types:** `FILL`, `TEXT`, `EFFECT`, `GRID`

This returns metadata only. To get actual values, fetch the nodes.

---

## GET /v1/files/:file_key/nodes?ids=...

Resolves actual property values from style node IDs.

```bash
curl -s -H "X-FIGMA-TOKEN: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/<FILE_KEY>/nodes?ids=123:456,789:012"
```

**Response (relevant fields):**
```json
{
  "nodes": {
    "123:456": {
      "document": {
        "fills": [
          { "type": "SOLID", "color": { "r": 0.2, "g": 0.4, "b": 0.8, "a": 1.0 } }
        ],
        "strokes": [],
        "effects": [
          {
            "type": "DROP_SHADOW",
            "color": { "r": 0, "g": 0, "b": 0, "a": 0.15 },
            "offset": { "x": 0, "y": 2 },
            "radius": 4,
            "spread": 0,
            "visible": true
          }
        ],
        "cornerRadius": 8,
        "paddingLeft": 16,
        "paddingRight": 16,
        "paddingTop": 8,
        "paddingBottom": 8,
        "style": {
          "fontFamily": "Inter",
          "fontWeight": 500,
          "fontSize": 16,
          "lineHeightPx": 24,
          "letterSpacing": 0
        }
      }
    }
  }
}
```

---

## Color Conversion Utilities

**Figma 0-1 RGBA to hex:**
```
r_hex = Math.round(r * 255).toString(16).padStart(2, '0')
g_hex = Math.round(g * 255).toString(16).padStart(2, '0')
b_hex = Math.round(b * 255).toString(16).padStart(2, '0')
hex = '#' + r_hex + g_hex + b_hex
// If alpha < 1: append Math.round(a * 255).toString(16).padStart(2, '0')
```

**Hex to Figma 0-1 RGBA:**
```
r = parseInt(hex.slice(1, 3), 16) / 255
g = parseInt(hex.slice(3, 5), 16) / 255
b = parseInt(hex.slice(5, 7), 16) / 255
a = hex.length === 9 ? parseInt(hex.slice(7, 9), 16) / 255 : 1.0
```

---

## Rate Limits

| Tier | Endpoint | Starter | Professional | Enterprise |
|------|----------|---------|-------------|------------|
| 2 | GET variables | 25/min | 50/min | 100/min |
| 3 | POST variables | 50/min | 100/min | 150/min |
| 2 | GET styles/nodes | 25/min | 50/min | 100/min |

When receiving HTTP 429: read `Retry-After` header (seconds) and wait before retrying.

**Strategy:** Batch all variable reads into a single GET call per file. Batch all writes into a single POST call. For style resolution, batch node IDs in a single GET nodes call (comma-separated IDs, max ~100 per request).
