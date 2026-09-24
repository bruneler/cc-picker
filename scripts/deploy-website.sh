#!/usr/bin/env bash
# CI only: receive no general-purpose shell or administrative VPS access.
set -euo pipefail
: "${DEPLOY_KEY:?Missing deployment key}"
: "${KNOWN_HOSTS:?Missing pinned host key}"
: "${GITHUB_SHA:?}"
: "${GITHUB_RUN_NUMBER:?}"
: "${GITHUB_RUN_ATTEMPT:?}"
[[ "$GITHUB_SHA" =~ ^[0-9a-f]{40}$ ]]
[[ "$GITHUB_RUN_NUMBER" =~ ^[1-9][0-9]*$ ]]
[[ "$GITHUB_RUN_ATTEMPT" =~ ^[1-9][0-9]*$ ]]
# A delayed workflow must not publish an older main revision.
latest=$(gh api repos/bruneler/cc-picker/git/ref/heads/main --jq .object.sha)
if [[ "$latest" != "$GITHUB_SHA" ]]; then
    echo 'Skipped: main has advanced.'
    exit 0
fi
umask 077
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
printf '%s\n' "$DEPLOY_KEY" > "$scratch/key"
printf '%s\n' "$KNOWN_HOSTS" > "$scratch/known_hosts"
unset DEPLOY_KEY KNOWN_HOSTS
# Tar contains only the tracked website, no Git metadata or runtime credentials.
git archive --format=tar "$GITHUB_SHA:website" > "$scratch/website.tar"
ssh -i "$scratch/key" -o IdentitiesOnly=yes -o BatchMode=yes \
    -o StrictHostKeyChecking=yes -o "UserKnownHostsFile=$scratch/known_hosts" \
    -o ConnectTimeout=15 -o ServerAliveInterval=15 -o ServerAliveCountMax=4 \
    ccdeploy@159.195.145.55 \
    "deploy $GITHUB_SHA $GITHUB_RUN_NUMBER $GITHUB_RUN_ATTEMPT" < "$scratch/website.tar"
# Independent external HTTPS check; the receiver already verifies every file
# against Caddy locally and rolls back transactionally if that verification fails.
curl --fail --silent --show-error --retry 3 --max-time 20 \
    https://cc-picker.brue.nu/release-info.json > "$scratch/receipt.json"
python3 - "$scratch/receipt.json" "$GITHUB_SHA" <<'PY'
import json, sys
assert json.load(open(sys.argv[1]))['sha'] == sys.argv[2], 'Unexpected live revision'
PY
printf 'Published https://cc-picker.brue.nu/ from %s\n' "$GITHUB_SHA"
