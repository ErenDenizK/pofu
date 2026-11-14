#!/usr/bin/env bash
# Fetch only the named frames of a screenshots ref, never touching the main .git.
# Usage: tools/review/fetch_frames.sh <sha-or-branch> <frame-glob>... <outdir>
#   e.g. tools/review/fetch_frames.sh screenshots/main 'path-d21-0900*' /tmp/frames
# A throwaway blobless clone in a temp dir: only the matching blobs are
# downloaded (tens of MB, not the whole branch), copied to outdir, and the
# clone is deleted. Never `git fetch` a screenshots ref into the main repo:
# its history filled the disk three times.
set -euo pipefail
[ "$#" -ge 3 ] || { echo "usage: $0 <sha-or-branch> <frame-glob>... <outdir>" >&2; exit 2; }
ref="$1"; out="${!#}"; globs=("${@:2:$#-2}")
url="${POFU_REMOTE_URL:-https://github.com/ErenDenizK/pofu}"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/fetch-frames.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$out"
cd "$tmp"
git init -q c && cd c
git remote add origin "$url"
git config extensions.partialClone origin
git config remote.origin.promisor true
git config remote.origin.partialclonefilter blob:none
if [[ "$ref" =~ ^[0-9a-f]{7,40}$ ]]; then want="$ref"; else want="refs/heads/${ref#origin/}"; fi
git fetch -q --depth 1 --filter=blob:none origin "$want"
# Sparse patterns match anywhere in the tree: a bare glob matches at any depth.
git sparse-checkout init --no-cone
git sparse-checkout set --no-cone "${globs[@]/#/**/}" "${globs[@]/#//}"
git checkout -q FETCH_HEAD
n=0
while IFS= read -r f; do
  cp "$f" "$out/$(basename "$f")"; echo "$out/$(basename "$f")"; n=$((n + 1))
done < <(find . -path ./.git -prune -o -type f -print)
echo "fetched $n frame(s); pack bytes: $(du -sb .git | cut -f1)" >&2
