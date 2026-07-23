#!/usr/bin/env bash
#
# create-bloodhound-session.sh
#
# Authenticate against the BloodHound CE API and store a session token that the
# other scripts in this directory can reuse.
#
# The token, host and port are written to a session file (default:
# $HOME/.bloodhound_ce_session) as shell variable assignments. The import and
# JSON scripts read this file automatically.
#

set -euo pipefail

usage() {
    cat <<'EOF'
Usage: create-bloodhound-session.sh -p PASSWORD [options]

Options:
  -u USERNAME   Username (default: admin)
  -p PASSWORD   Password (mandatory; if omitted you will be prompted)
  -H HOSTNAME   Hostname / IP address of the BloodHound API (default: 127.0.0.1)
  -P PORT       Port of the BloodHound API (default: 8080)
  -f FILE       Session file to write (default: $HOME/.bloodhound_ce_session
                or $BH_SESSION_FILE if set)
  -h            Show this help
EOF
}

green() { printf '\033[0;32m%s\033[0m\n' "$*"; }
red()   { printf '\033[0;31m%s\033[0m\n' "$*" >&2; }

USERNAME="admin"
PASSWORD=""
HOSTNAME="127.0.0.1"
PORT="8080"
SESSION_FILE="${BH_SESSION_FILE:-$HOME/.bloodhound_ce_session}"

while getopts "u:p:H:P:f:h" opt; do
    case "$opt" in
        u) USERNAME="$OPTARG" ;;
        p) PASSWORD="$OPTARG" ;;
        H) HOSTNAME="$OPTARG" ;;
        P) PORT="$OPTARG" ;;
        f) SESSION_FILE="$OPTARG" ;;
        h) usage; exit 0 ;;
        *) usage; exit 1 ;;
    esac
done

for tool in curl jq; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        red "[!] Required tool '$tool' is not installed."
        exit 1
    fi
done

if [ -z "$PASSWORD" ]; then
    read -r -s -p "Password: " PASSWORD
    echo
fi

if [ -z "$PASSWORD" ]; then
    red "[!] Password is mandatory."
    exit 1
fi

green "[*] Authenticate..."
body="$(jq -n \
    --arg username "$USERNAME" \
    --arg secret "$PASSWORD" \
    '{login_method: "secret", username: $username, secret: $secret}')"

response="$(curl -sS \
    -X POST "http://${HOSTNAME}:${PORT}/api/v2/login" \
    -H "Content-Type: application/json" \
    -d "$body")"

token="$(printf '%s' "$response" | jq -r '.data.session_token // empty')"

if [ -z "$token" ]; then
    red "[!] Login failed. Server response:"
    printf '%s\n' "$response" >&2
    exit 1
fi

green "[*] Logging in..."
umask 077
cat > "$SESSION_FILE" <<EOF
BH_HOST="${HOSTNAME}"
BH_PORT="${PORT}"
BH_TOKEN="${token}"
EOF

green "[*] Your session:"
printf '    Host  : %s\n' "$HOSTNAME"
printf '    Port  : %s\n' "$PORT"
printf '    File  : %s\n' "$SESSION_FILE"

green "[*] Ready to use the BloodHound CE API!"
