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
# -no-emit-module-separately: one module emit per target, lower peak memory.
# Each run appends one line to $POFU_SWIFT_LOG: time, worktree, wait seconds
# (to get the lock), run seconds, exit code. POFU_SWIFT_CMD replaces `swift`
# and POFU_SWIFT_LOCK the lock file (both used only by the test of this script).
log="${POFU_SWIFT_LOG:-/tmp/pofu-swift-runs.log}"
wt="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cmd="${POFU_SWIFT_CMD:-swift}"
t0=$SECONDS; rc=0
exec 9>"${POFU_SWIFT_LOCK:-/tmp/pofu-swift-build.lock}"
flock 9
t1=$SECONDS
"$cmd" test ${jobs[@]+"${jobs[@]}"} -Xswiftc -no-emit-module-separately "$@" || rc=$?
printf '%s %s wait=%ss run=%ss exit=%s\n' "$(date -u +%FT%TZ)" "$wt" "$((t1 - t0))" "$((SECONDS - t1))" "$rc" >> "$log" 2>/dev/null || true
exit "$rc"
