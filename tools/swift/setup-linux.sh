#!/usr/bin/env bash
# Install the official Swift toolchain on Linux x86_64 (Ubuntu 24.04) without
# download.swift.org: pull the layers of Docker Hub's `swift:<tag>-noble`
# image over plain HTTPS and unpack them to $SWIFT_ROOT. No Docker daemon.
# Idempotent. Usage: tools/swift/setup-linux.sh [tag]   (default 6.2.1)
# Then: export PATH="/opt/swift/usr/bin:$PATH"
set -euo pipefail

TAG="${1:-${SWIFT_TAG:-6.2.1}}-noble"
SWIFT_ROOT="${SWIFT_ROOT:-/opt/swift}"
REG=https://registry-1.docker.io/v2/library/swift

if [ -x "$SWIFT_ROOT/usr/bin/swift" ] && [ -f "$SWIFT_ROOT/.tag" ] \
   && [ "$(cat "$SWIFT_ROOT/.tag")" = "$TAG" ]; then
  echo "swift $TAG already installed in $SWIFT_ROOT"
  "$SWIFT_ROOT/usr/bin/swift" --version
  exit 0
fi

# Runtime libraries the toolchain links against.
if ! dpkg -s libncurses6 libxml2 libcurl4t64 libedit2 libsqlite3-0 libpython3.12t64 >/dev/null 2>&1; then
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
    binutils gcc libc6-dev libcurl4t64 libedit2 libgcc-13-dev libncurses6 \
    libpython3.12t64 libsqlite3-0 libstdc++-13-dev libxml2 pkg-config \
    tzdata zlib1g-dev unzip
fi

work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
T="$(curl -fsS "https://auth.docker.io/token?service=registry.docker.io&scope=repository:library/swift:pull" \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["token"])')"
get() { curl -fsSL -H "Authorization: Bearer $T" "$@"; }
ACC='application/vnd.oci.image.index.v1+json,application/vnd.docker.distribution.manifest.list.v2+json'
ACM='application/vnd.oci.image.manifest.v1+json,application/vnd.docker.distribution.manifest.v2+json'

get -H "Accept: $ACC" "$REG/manifests/$TAG" > "$work/index.json"
digest="$(python3 -c '
import sys,json
for m in json.load(open(sys.argv[1]))["manifests"]:
    p=m["platform"]
    if p["architecture"]=="amd64" and p["os"]=="linux":
        print(m["digest"]); break' "$work/index.json")"
get -H "Accept: $ACM" "$REG/manifests/$digest" > "$work/manifest.json"

rm -rf "$SWIFT_ROOT.tmp"; mkdir -p "$SWIFT_ROOT.tmp"
python3 -c 'import sys,json;[print(l["digest"]) for l in json.load(open(sys.argv[1]))["layers"]]' "$work/manifest.json" |
while read -r d; do
  echo "layer $d"
  get "$REG/blobs/$d" | tar -xz -C "$SWIFT_ROOT.tmp" --no-same-owner --exclude='./dev/*' 2>/dev/null || true
done
rm -rf "$SWIFT_ROOT"; mv "$SWIFT_ROOT.tmp" "$SWIFT_ROOT"
echo "$TAG" > "$SWIFT_ROOT/.tag"
"$SWIFT_ROOT/usr/bin/swift" --version
echo "Add to PATH: export PATH=$SWIFT_ROOT/usr/bin:\$PATH"
