#!/usr/bin/env bash
#
# import-bloodhound-ce-custom-queries.sh
#
# Import the BloodHound CE Custom Queries into a BloodHound CE instance via the
# REST API. Requires a session created by create-bloodhound-session.sh.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARKDOWN_FILE="$SCRIPT_DIR/../custom_queries/BloodHound_CE_Custom_Queries.md"
SESSION_FILE="${BH_SESSION_FILE:-$HOME/.bloodhound_ce_session}"

green() { printf '\033[0;32m%s\033[0m\n' "$*"; }
red()   { printf '\033[0;31m%s\033[0m\n' "$*" >&2; }

for tool in curl jq; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        red "[!] Required tool '$tool' is not installed."
        exit 1
    fi
done

if [ ! -f "$SESSION_FILE" ]; then
    red "[!] Session file '$SESSION_FILE' not found."
    red "    Run create-bloodhound-session.sh first."
    exit 1
fi

# shellcheck disable=SC1090
. "$SESSION_FILE"

: "${BH_HOST:?Session file is missing BH_HOST}"
: "${BH_PORT:?Session file is missing BH_PORT}"
: "${BH_TOKEN:?Session file is missing BH_TOKEN}"

API="http://${BH_HOST}:${BH_PORT}/api/v2/saved-queries"
AUTH="Authorization: Bearer ${BH_TOKEN}"

# create_query NAME QUERY
create_query() {
    local name="$1" query="$2"
    local body
    body="$(jq -n --arg name "$name" --arg query "$query" \
        '{name: $name, query: $query, description: ""}')"
    curl -sS -X POST "$API" \
        -H "$AUTH" \
        -H "Content-Type: application/json" \
        -d "$body" >/dev/null
    sleep 0.1
}

green "[*] Removing all queries starting with [C-..."
existing="$(curl -sS "$API" -H "$AUTH")"
printf '%s' "$existing" \
    | jq -r '.data[]? | select(.name | startswith("[C-")) | .id' \
    | while read -r id; do
        [ -n "$id" ] || continue
        curl -sS -X DELETE "${API}/${id}" -H "$AUTH" >/dev/null
        sleep 0.1
    done
echo

green "[*] Importing queries ..."

counter=1000
name=""
query=""
in_block=0

while IFS= read -r line || [ -n "$line" ]; do
    if [ "$in_block" -eq 1 ]; then
        if [[ "$line" == '```'* ]]; then
            # End of code block: import the accumulated query.
            in_block=0
            echo "[*] Importing query [C-$counter] $name..."
            create_query "[C-$counter] $name" "$query"
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
            create_query "[C-$counter] ########## $name ##########" "MATCH (n) WHERE false RETURN n"
            ;;
        '```'*)
            in_block=1
            query=""
            ;;
    esac
done < "$MARKDOWN_FILE"

green "[*] Done."
