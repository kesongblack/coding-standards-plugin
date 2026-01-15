#!/bin/bash

# Coding Standards Plugin - Installation Script
# Creates symlink from plugin directory to Claude Code plugins directory

set -e

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Detect plugin root directory
PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_PLUGINS_DIR="${HOME}/.claude/plugins"
PLUGIN_NAME="coding-standards"
SYMLINK_PATH="${CLAUDE_PLUGINS_DIR}/${PLUGIN_NAME}"

echo "Coding Standards Plugin - Installation"
echo "======================================="
echo ""

# Check if Claude Code plugins directory exists
if [ ! -d "${CLAUDE_PLUGINS_DIR}" ]; then
    echo -e "${YELLOW}Warning: Claude Code plugins directory not found at ${CLAUDE_PLUGINS_DIR}${NC}"
    echo "Creating plugins directory..."
    mkdir -p "${CLAUDE_PLUGINS_DIR}"
fi

# Check if symlink already exists
if [ -L "${SYMLINK_PATH}" ]; then
    # Symlink exists, check if it points to correct location
    CURRENT_TARGET="$(readlink "${SYMLINK_PATH}")"
    if [ "${CURRENT_TARGET}" = "${PLUGIN_ROOT}" ]; then
        echo -e "${GREEN}✓ Plugin already installed and up to date${NC}"
        echo "  Location: ${SYMLINK_PATH} -> ${PLUGIN_ROOT}"
        exit 0
    else
        echo -e "${YELLOW}Warning: Symlink exists but points to different location${NC}"
        echo "  Current: ${CURRENT_TARGET}"
        echo "  New: ${PLUGIN_ROOT}"
        echo "Removing old symlink..."
        rm "${SYMLINK_PATH}"
    fi
elif [ -e "${SYMLINK_PATH}" ]; then
    echo -e "${RED}Error: ${SYMLINK_PATH} exists but is not a symlink${NC}"
    echo "Please remove it manually and run this script again."
    exit 1
fi

# Create symlink
echo "Creating symlink..."
ln -s "${PLUGIN_ROOT}" "${SYMLINK_PATH}"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Installation successful!${NC}"
    echo ""
    echo "Plugin installed at: ${SYMLINK_PATH}"
    echo "Source location: ${PLUGIN_ROOT}"
    echo ""
    echo "Next steps:"
    echo "  1. Restart Claude Code or start a new session"
    echo "  2. Run '/standards setup' to configure enabled languages"
    echo "  3. Open a Laravel/Next.js/Flutter project to see auto-detection in action"
    echo ""
else
    echo -e "${RED}✗ Installation failed${NC}"
    exit 1
fi
