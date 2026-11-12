#!/usr/bin/env bash
# Run PofuKit's tests locally on Linux (needs tools/swift/setup-linux.sh).
# Apple-only code is behind #if os(iOS) / canImport guards, so a plain
# `swift test` works. Usage: tools/swift/test-linux.sh [swift test args...]
#
# One Swift build at a time on this machine. Two compiles of PofuWorld at
# once, or one with `-j 4`, run out of memory (15 GB, no swap) and are
# killed. The lock makes builds in other worktrees wait their turn, and
# `-j 1` is the default unless you pass your own `-j`.
set -euo pipefail
export PATH="${SWIFT_ROOT:-/opt/swift}/usr/bin:$PATH"
cd "$(dirname "$0")/../../Packages/PofuKit"
jobs=(-j 1)
for a in "$@"; do case "$a" in -j|-j[0-9]*|--jobs|--jobs=*) jobs=() ;; esac; done
exec flock /tmp/pofu-swift-build.lock swift test ${jobs[@]+"${jobs[@]}"} "$@"
