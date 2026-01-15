#!/bin/bash
# Validate all rules.json files for correct schema and syntax
# Usage: ./scripts/validate-standards.sh
# Exit code: 0 = valid, 1 = invalid

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
STANDARDS_DIR="$PLUGIN_ROOT/standards"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required but not installed.${NC}"
    echo "Install with: sudo apt install jq (Linux) or brew install jq (macOS)"
    exit 1
fi

echo "Validating standards files in $STANDARDS_DIR..."
echo ""

# Find all rules.json files
for rules_file in "$STANDARDS_DIR"/*/rules.json; do
    if [ ! -f "$rules_file" ]; then
        continue
    fi

    language=$(basename "$(dirname "$rules_file")")
    echo -n "Checking $language/rules.json... "

    # 1. Validate JSON syntax
    if ! jq empty "$rules_file" 2>/dev/null; then
        echo -e "${RED}FAILED${NC}"
        echo "  - Invalid JSON syntax"
        ((ERRORS++))
        continue
    fi

    # 2. Check required top-level fields
    missing_fields=""

    if [ "$(jq 'has("version")' "$rules_file")" != "true" ]; then
        missing_fields+="version "
    fi

    if [ "$(jq 'has("language")' "$rules_file")" != "true" ]; then
        missing_fields+="language "
    fi

    if [ "$(jq 'has("categories")' "$rules_file")" != "true" ]; then
        missing_fields+="categories "
    fi

    if [ -n "$missing_fields" ]; then
        echo -e "${RED}FAILED${NC}"
        echo "  - Missing required fields: $missing_fields"
        ((ERRORS++))
        continue
    fi

    # 3. Validate language field matches directory
    file_language=$(jq -r '.language' "$rules_file")
    if [ "$file_language" != "$language" ]; then
        echo -e "${RED}FAILED${NC}"
        echo "  - Language mismatch: file says '$file_language' but directory is '$language'"
        ((ERRORS++))
        continue
    fi

    # 4. Check each category has rules array
    rule_errors=0
    categories=$(jq -r '.categories | keys[]' "$rules_file")

    for category in $categories; do
        # Check category has rules array
        if [ "$(jq ".categories[\"$category\"] | has(\"rules\")" "$rules_file")" != "true" ]; then
            echo -e "${YELLOW}WARNING${NC}"
            echo "  - Category '$category' missing 'rules' array"
            ((WARNINGS++))
            continue
        fi

        # Check each rule has required fields
        rule_count=$(jq ".categories[\"$category\"].rules | length" "$rules_file")
        for ((i=0; i<rule_count; i++)); do
            rule_id=$(jq -r ".categories[\"$category\"].rules[$i].id // empty" "$rules_file")

            if [ -z "$rule_id" ]; then
                echo -e "${RED}FAILED${NC}"
                echo "  - Rule at index $i in '$category' missing 'id' field"
                ((rule_errors++))
                continue
            fi

            # Check severity
            severity=$(jq -r ".categories[\"$category\"].rules[$i].severity // empty" "$rules_file")
            if [ -z "$severity" ]; then
                echo -e "${YELLOW}WARNING${NC}"
                echo "  - Rule '$rule_id' missing 'severity' field"
                ((WARNINGS++))
            elif [[ ! "$severity" =~ ^(error|warning|info|advisory)$ ]]; then
                echo -e "${YELLOW}WARNING${NC}"
                echo "  - Rule '$rule_id' has invalid severity: '$severity'"
                ((WARNINGS++))
            fi

            # Check message
            message=$(jq -r ".categories[\"$category\"].rules[$i].message // empty" "$rules_file")
            if [ -z "$message" ]; then
                echo -e "${YELLOW}WARNING${NC}"
                echo "  - Rule '$rule_id' missing 'message' field"
                ((WARNINGS++))
            fi
        done
    done

    if [ $rule_errors -gt 0 ]; then
        ((ERRORS++))
        continue
    fi

    echo -e "${GREEN}OK${NC}"
done

echo ""
echo "========================================"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}All standards files are valid!${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}Validation passed with $WARNINGS warning(s)${NC}"
    exit 0
else
    echo -e "${RED}Validation failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    exit 1
fi
