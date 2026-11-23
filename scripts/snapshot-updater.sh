#!/usr/bin/env bash
# Copy a published update site as-is. Never rewrite an index or its signature.
set -euo pipefail

base="${1:?usage: snapshot-updater.sh <source-url> <new-directory>}"
out="${2:?usage: snapshot-updater.sh <source-url> <new-directory>}"
mkdir -p -- "$(dirname -- "$out")"
mkdir -- "$out"

fetch() {
    curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' \
        --retry 2 --max-time 120 --output "$out/$2" "${base%/}/$1"
}

# Bypass the cache for the publication metadata. If a deploy changes files
# during the copy, signature or checksum verification prevents publication.
fresh="snapshot=$(date +%s)-$$"
for name in index.json index.json.sig site-manifest.json; do
    fetch "$name?$fresh" "$name"
done

jq -e '.schema == 1 and (.files | type == "object") and
    (.files | has("updates/stable/latest.json") and has("updates/beta/latest.json"))' \
    "$out/site-manifest.json" >/dev/null

while IFS=$'\t' read -r path expected; do
    if ! [[ "$path" =~ ^(packages|source|updates)/([a-zA-Z0-9_][a-zA-Z0-9_.-]*/)*[a-zA-Z0-9_][a-zA-Z0-9_.-]*$ && "$expected" =~ ^[a-f0-9]{64}$ ]]; then
        printf 'Invalid path or checksum in the site manifest: %q\n' "$path" >&2
        exit 1
    fi
    mkdir -p -- "$out/$(dirname -- "$path")"
    fetch "$path" "$path"
    actual=$(shasum -a 256 "$out/$path" | cut -d ' ' -f 1)
    if [ "$actual" != "$expected" ]; then
        printf 'Checksum mismatch for %s\n' "$path" >&2
        exit 1
    fi
    printf 'Verified %s\n' "$path"
done < <(jq -r '.files | to_entries[] | [.key, .value] | @tsv' "$out/site-manifest.json")

printf 'Copied update index sequence %s (signature must be verified before publishing)\n' \
    "$(jq -er '.sequence' "$out/index.json")"
