#!/usr/bin/env bash
# Builds the dictation runtime files that the Pofu Hub artifact publishes next to its page:
#
#   design/hub/dictation/vendor/transformers.min.js   Transformers.js 3.8.1 (Apache-2.0), bundles ONNX Runtime Web
#   design/hub/dictation/vendor/ort-wasm.js           ONNX Runtime's WebAssembly binary as gzip + base64 in a JS module
#
# The artifact sandbox blocks fetches to CDNs, so the worker cannot load ONNX Runtime's .wasm from
# jsDelivr; and a published binary file is capped at 15 MB while the .wasm is 21.6 MB. Wrapping the
# gzipped binary (5 MB) in a JS module keeps it a script, which the page may load from its own
# origin. The output is generated, so it is not committed (see .gitignore). The npm tarball is
# checked against the registry's published SHA-512 before anything is extracted.
#
#   bash design/hub/tools/vendor-dictation.sh
set -euo pipefail

VERSION=3.8.1
INTEGRITY='sha512-tsTk4zVjImqdqjS8/AOZg2yNLd1z9S5v+7oUPpXaasDRwEDhB+xnglK1k5cad26lL5/ZIaeREgWWy0bs9y9pPA=='
HERE="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$HERE/dictation/vendor"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

curl -fsSL -o "$TMP/t.tgz" "https://registry.npmjs.org/@huggingface/transformers/-/transformers-$VERSION.tgz"
GOT="sha512-$(openssl dgst -sha512 -binary "$TMP/t.tgz" | base64 -w0)"
if [ "$GOT" != "$INTEGRITY" ]; then echo "integrity mismatch: $GOT" >&2; exit 1; fi
mkdir -p "$TMP/x" "$OUT"
tar xzf "$TMP/t.tgz" -C "$TMP/x" package/dist/transformers.min.js package/dist/ort-wasm-simd-threaded.jsep.wasm package/LICENSE

# The bundle holds a few non-ASCII characters (U+FFFD among them) in string literals; the artifact
# publisher refuses U+FFFD in text files, so every non-ASCII character becomes a \uXXXX escape,
# which means the same thing anywhere it can appear in JS source.
{
  echo "/* Transformers.js $VERSION, https://github.com/huggingface/transformers.js, Apache-2.0 */"
  node -e 'const s=require("fs").readFileSync(process.argv[1],"utf8");process.stdout.write(s.replace(/[^\x00-\x7e]/g,(c)=>"\\u"+c.charCodeAt(0).toString(16).padStart(4,"0")))' "$TMP/x/package/dist/transformers.min.js"
} > "$OUT/transformers.min.js"

{
  echo "// ONNX Runtime Web WebAssembly binary (ort-wasm-simd-threaded.jsep.wasm from @huggingface/transformers@$VERSION, MIT),"
  echo "// gzip-compressed and base64-encoded. Decoded by ../worker.js."
  printf 'export default "'
  gzip -9 -n -c "$TMP/x/package/dist/ort-wasm-simd-threaded.jsep.wasm" | base64 -w0
  printf '";\n'
} > "$OUT/ort-wasm.js"

ls -l "$OUT"
