#!/bin/sh
# Story 5.2 — Docker secrets → process env bridge.
#
# compose.prod.yml mounts secret files at /run/secrets/<name>. Application code
# reads `os.environ["VARCO_API_KEY"]` etc., so this shim exports each file's
# contents as the upper-case env var of the file's basename, then exec's CMD.
#
# Convention: file `varco_api_key` → env `VARCO_API_KEY`.
# Dots/dashes in filenames are normalized to underscores.
set -e

if [ -d /run/secrets ]; then
    for f in /run/secrets/*; do
        [ -f "$f" ] || continue
        name=$(basename "$f")
        var=$(printf '%s' "$name" | tr 'a-z' 'A-Z' | tr '.-' '_')
        # shellcheck disable=SC2163
        export "${var}=$(cat "$f")"
    done
fi

exec "$@"
