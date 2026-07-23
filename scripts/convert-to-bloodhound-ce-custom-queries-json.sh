#!/usr/bin/env bash
#
# convert-to-bloodhound-ce-custom-queries-json.sh
#
# Export the BloodHound CE Custom Queries as individual JSON files that can be
# imported through the BloodHound CE GUI.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARKDOWN_FILE="$SCRIPT_DIR/../custom_queries/BloodHound_CE_Custom_Queries.md"
OUTPUT_FOLDER="$SCRIPT_DIR/../custom_queries/json"

green() { printf '\033[0;32m%s\033[0m\n' "$*"; }
red()   { printf '\033[0;31m%s\033[0m\n' "$*" >&2; }

if ! command -v jq >/dev/null 2>&1; then
    red "[!] Required tool 'jq' is not installed."
    exit 1
fi

mkdir -p "$OUTPUT_FOLDER"

# write_json COUNTER NAME QUERY
write_json() {
    local num="$1" name="$2" query="$3"
    local fname filepath
    fname="C-${num}_${name}.json"
    # Replace characters that are invalid in filenames.
    fname="$(printf '%s' "$fname" | sed 's/[<>:"/\\|?*]/_/g')"
    filepath="$OUTPUT_FOLDER/$fname"
    jq -n --arg name "[C-$num] $name" --arg query "$query" \
        '{query: $query, name: $name, description: ""}' > "$filepath"
    echo "[*] Wrote $fname"
}

green "[*] Exporting queries to JSON..."

counter=1000
name=""
query=""
in_block=0

while IFS= read -r line || [ -n "$line" ]; do
    if [ "$in_block" -eq 1 ]; then
        if [[ "$line" == '```'* ]]; then
            in_block=0
            write_json "$counter" "$name" "${query%$'\n'}"
            query=""
        else
            query+="$line"$'\n'
        fi
        continue
    fi

    case "$line" in
        '### '*)
            counter=$((counter + 1))
            name="${line#'### '}"
            ;;
        '## '*)
            # Round the counter up to the next multiple of 100.
            counter=$(( ((counter + 99) / 100) * 100 ))
            name="${line#'## '}"
            green "[*] Found category [C-$counter] $name..."
            write_json "$counter" "$name" "-"
            ;;
        '```'*)
            in_block=1
            query=""
            ;;
    esac
done < "$MARKDOWN_FILE"

green "[*] Done."
