#!/usr/bin/env bash
# Run PofuKit's tests locally on Linux (needs tools/swift/setup-linux.sh).
# Apple-only code is behind #if os(iOS) / canImport guards, so a plain
# `swift test` works. Usage: tools/swift/test-linux.sh [swift test args...]
set -euo pipefail
export PATH="${SWIFT_ROOT:-/opt/swift}/usr/bin:$PATH"
cd "$(dirname "$0")/../../Packages/PofuKit"
exec swift test "$@"
