#!/bin/bash

# Coding Standards Plugin - Project Detection Script
# Detects project type and runs quick audit on session start

set -e

# Determine plugin root directory
if [ -n "${CLAUDE_PLUGIN_ROOT}" ]; then
    PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"
else
    PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

CONFIG_FILE="${PLUGIN_ROOT}/.local/config.json"
PROJECT_DIR="${PWD}"

# Function to check if config exists and has enabled languages
check_config() {
    if [ ! -f "${CONFIG_FILE}" ]; then
        echo "⚙️  Coding Standards Plugin: First-time setup required"
        echo "   Run '/standards setup' to configure enabled languages"
        exit 0
    fi

    # Check if jq is available (optional, graceful fallback)
    if ! command -v jq &> /dev/null; then
        # jq not available, assume config is valid
        return 0
    fi

    # Check if enabledLanguages array is empty
    ENABLED_LANGS=$(jq -r '.enabledLanguages | length' "${CONFIG_FILE}" 2>/dev/null || echo "0")
    if [ "${ENABLED_LANGS}" = "0" ]; then
        echo "⚙️  Coding Standards Plugin: No languages enabled"
        echo "   Run '/standards setup' to configure enabled languages"
        exit 0
    fi
}

# Function to check if language is enabled
is_language_enabled() {
    local lang="$1"

    if ! command -v jq &> /dev/null; then
        # jq not available, assume all languages enabled for backwards compatibility
        return 0
    fi

    local enabled=$(jq -r ".enabledLanguages | index(\"${lang}\") // \"null\"" "${CONFIG_FILE}" 2>/dev/null)
    if [ "${enabled}" != "null" ]; then
        return 0
    else
        return 1
    fi
}

# Function to detect project type
detect_project_type() {
    # Check for Laravel (composer.json with laravel/framework)
    if [ -f "${PROJECT_DIR}/composer.json" ]; then
        if grep -q '"laravel/framework"' "${PROJECT_DIR}/composer.json" 2>/dev/null; then
            if is_language_enabled "laravel"; then
                echo "laravel"
                return 0
            fi
        fi
    fi

    # Check for Next.js (package.json with next dependency)
    if [ -f "${PROJECT_DIR}/package.json" ]; then
        if grep -q '"next"' "${PROJECT_DIR}/package.json" 2>/dev/null; then
            if is_language_enabled "nextjs"; then
                echo "nextjs"
                return 0
            fi
        fi
    fi

    # Check for Flutter (pubspec.yaml with flutter SDK)
    if [ -f "${PROJECT_DIR}/pubspec.yaml" ]; then
        if grep -q 'sdk: flutter' "${PROJECT_DIR}/pubspec.yaml" 2>/dev/null; then
            if is_language_enabled "flutter"; then
                echo "flutter"
                return 0
            fi
        fi
    fi

    # Check for Python (requirements.txt or pyproject.toml)
    if [ -f "${PROJECT_DIR}/requirements.txt" ] || [ -f "${PROJECT_DIR}/pyproject.toml" ]; then
        if is_language_enabled "python"; then
            echo "python"
            return 0
        fi
    fi

    echo "unknown"
    return 1
}

# Function to detect Python frameworks
detect_python_frameworks() {
    local frameworks=()

    # Check requirements.txt
    if [ -f "${PROJECT_DIR}/requirements.txt" ]; then
        grep -qi "django" "${PROJECT_DIR}/requirements.txt" 2>/dev/null && frameworks+=("django")
        grep -qi "fastapi\|uvicorn" "${PROJECT_DIR}/requirements.txt" 2>/dev/null && frameworks+=("fastapi")
        grep -qi "jupyter\|pandas\|scikit-learn\|tensorflow\|numpy" "${PROJECT_DIR}/requirements.txt" 2>/dev/null && frameworks+=("datascience")
    fi

    # Check pyproject.toml
    if [ -f "${PROJECT_DIR}/pyproject.toml" ]; then
        grep -qi "django" "${PROJECT_DIR}/pyproject.toml" 2>/dev/null && frameworks+=("django")
        grep -qi "fastapi" "${PROJECT_DIR}/pyproject.toml" 2>/dev/null && frameworks+=("fastapi")
        grep -qi "jupyter\|pandas\|numpy\|scikit-learn" "${PROJECT_DIR}/pyproject.toml" 2>/dev/null && frameworks+=("datascience")
    fi

    # Remove duplicates and output
    echo "${frameworks[@]}" | tr ' ' '\n' | sort -u | tr '\n' ',' | sed 's/,$//'
}

# Function to get project display name
get_project_name() {
    local project_type="$1"
    local frameworks="$2"
    case "${project_type}" in
        laravel)
            echo "Laravel"
            ;;
        nextjs)
            echo "Next.js"
            ;;
        flutter)
            echo "Flutter"
            ;;
        python)
            if [ -n "${frameworks}" ]; then
                # Convert comma-separated frameworks to readable format
                local fw_display=$(echo "${frameworks}" | sed 's/,/, /g' | sed 's/django/Django/g; s/fastapi/FastAPI/g; s/datascience/Data Science/g')
                echo "Python (${fw_display})"
            else
                echo "Python"
            fi
            ;;
        *)
            echo "Unknown"
            ;;
    esac
}

# Main execution
main() {
    # Check config
    check_config

    # Detect project type
    PROJECT_TYPE=$(detect_project_type)

    if [ "${PROJECT_TYPE}" = "unknown" ]; then
        # No supported project detected, exit silently
        exit 0
    fi

    # Detect Python frameworks if Python project
    PYTHON_FRAMEWORKS=""
    if [ "${PROJECT_TYPE}" = "python" ]; then
        PYTHON_FRAMEWORKS=$(detect_python_frameworks)
    fi

    PROJECT_NAME=$(get_project_name "${PROJECT_TYPE}" "${PYTHON_FRAMEWORKS}")

    # Set environment variables for other scripts/skills
    if [ -n "${CLAUDE_ENV_FILE}" ]; then
        echo "PROJECT_TYPE=${PROJECT_TYPE}" >> "${CLAUDE_ENV_FILE}"
        if [ "${PROJECT_TYPE}" = "python" ] && [ -n "${PYTHON_FRAMEWORKS}" ]; then
            echo "PYTHON_FRAMEWORKS=${PYTHON_FRAMEWORKS}" >> "${CLAUDE_ENV_FILE}"
        fi
    fi

    # Output brief status message
    echo "📋 ${PROJECT_NAME} project detected"
    echo "   Coding standards monitoring active"
    echo "   Run '/audit' for full analysis or '/standards' to configure"
}

main
