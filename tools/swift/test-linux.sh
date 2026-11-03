#!/usr/bin/env bash
# Run the Linux-clean part of PofuKit's tests locally (needs setup-linux.sh).
# `swift test` builds every target, and some do not compile on Linux yet, so
# this makes a throwaway copy of the package without them (PofuScreenTime:
# `import os`; PofuTuning and PofuGames: a type-checker timeout in
# TuningSpec.swift) and tests that. The copy sits next to the real package so
# the tests' repo-relative paths (design/tokens, Config/Info.plist) resolve.
# Usage: tools/swift/test-linux.sh [swift test args...]
set -euo pipefail
export PATH="${SWIFT_ROOT:-/opt/swift}/usr/bin:$PATH"
repo="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$repo/Packages/.PofuKit-linux"
trap 'rm -rf "$tmp"' EXIT
rm -rf "$tmp"
mkdir "$tmp"
cp -R "$repo/Packages/PofuKit/Sources" "$repo/Packages/PofuKit/Tests" "$repo/Packages/PofuKit/Package.swift" "$tmp/"
rm -rf "$tmp/Tests/PofuScreenTimeTests" "$tmp/Tests/PofuGamesTests" "$tmp/Tests/PofuTuningTests"
python3 -I - "$tmp/Package.swift" <<'EOF'
import re, sys
p = sys.argv[1]
s = open(p).read()
for n in ["PofuScreenTime", "PofuGames", "PofuTuning"]:
    s = re.sub(r'\n *\.library\(name: "%s".*' % n, '', s)
    s = re.sub(r'\n *\.testTarget\(name: "%sTests".*' % n, '', s)
    m = re.search(r'\n        \.target\(\s*name: "%s"' % n, s)
    i = m.start() + 1
    eol = s.index('\n', i)
    if s[i:eol].rstrip().endswith('),'):  # one-line target
        j = eol
    else:  # multi-line target, closed by "        ),"
        j = s.index('\n        )', i) + len('\n        ),')
    s = s[:i] + s[j:]
open(p, 'w').write(s)
EOF
cd "$tmp" && swift test "$@"
