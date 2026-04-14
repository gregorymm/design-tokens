#!/usr/bin/env bash
# One-line installer for the design-tokens Claude Code plugin.
# Usage:  curl -sL https://raw.githubusercontent.com/gregorymm/design-tokens/main/install.sh | bash

set -euo pipefail

REPO_URL="https://github.com/gregorymm/design-tokens.git"
MARKETPLACE_NAME="design-tokens"
PLUGIN_NAME="design-tokens"
GITHUB_REPO="gregorymm/design-tokens"

CLAUDE_DIR="${HOME}/.claude"
PLUGIN_DIR="${CLAUDE_DIR}/plugins/marketplaces/${MARKETPLACE_NAME}"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

blue()  { printf "\033[34m%s\033[0m\n" "$1"; }
green() { printf "\033[32m%s\033[0m\n" "$1"; }
yellow() { printf "\033[33m%s\033[0m\n" "$1"; }
red()   { printf "\033[31m%s\033[0m\n" "$1"; }

blue "→ Installing design-tokens plugin for Claude Code"

# 1) Check dependencies
command -v git >/dev/null 2>&1 || { red "git is required but not installed."; exit 1; }
command -v node >/dev/null 2>&1 || { red "node is required but not installed."; exit 1; }

# 2) Clone or update the plugin repo
mkdir -p "$(dirname "${PLUGIN_DIR}")"
if [ -d "${PLUGIN_DIR}/.git" ]; then
  blue "→ Updating existing clone at ${PLUGIN_DIR}"
  git -C "${PLUGIN_DIR}" pull --ff-only >/dev/null
else
  blue "→ Cloning ${REPO_URL} to ${PLUGIN_DIR}"
  git clone --quiet "${REPO_URL}" "${PLUGIN_DIR}"
fi

# 3) Create settings.json if missing
if [ ! -f "${SETTINGS_FILE}" ]; then
  blue "→ Creating ${SETTINGS_FILE}"
  mkdir -p "${CLAUDE_DIR}"
  echo '{}' > "${SETTINGS_FILE}"
fi

# 4) Merge entries into settings.json via node (safe JSON edit)
blue "→ Registering plugin in ${SETTINGS_FILE}"
node - <<EOF
const fs = require("fs");
const path = "${SETTINGS_FILE}";
const data = JSON.parse(fs.readFileSync(path, "utf8"));
data.enabledPlugins = data.enabledPlugins || {};
data.enabledPlugins["${PLUGIN_NAME}@${MARKETPLACE_NAME}"] = true;
data.extraKnownMarketplaces = data.extraKnownMarketplaces || {};
data.extraKnownMarketplaces["${MARKETPLACE_NAME}"] = {
  source: { source: "github", repo: "${GITHUB_REPO}" }
};
fs.writeFileSync(path, JSON.stringify(data, null, 2) + "\n");
EOF

green "✓ Installed."
yellow "→ Restart Claude Code, then use /design-tokens or say \"extract design tokens\"."
