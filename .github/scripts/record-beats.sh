#!/usr/bin/env bash
# The host side of the motion review (Tests/WorldScreenshots/MotionBeatTests.swift):
# records one simulator video per beat while the test plays it.
#
#   record-beats.sh <simulator udid> <folder>
#
# The test writes <beat>.request into <folder> when the beat is laid out;
# this starts `simctl io recordVideo`, answers <beat>.recording once the
# recorder runs, waits for <beat>.done, stops the recorder with SIGINT (which
# finalizes the file) and answers <beat>.saved. It exits when the test
# writes all.done, or after an hour.
#
# The first recording on a fresh simulator takes a long while to start, so
# a short warm-up recording runs first, while xcodebuild builds and
# launches the test.
set -uo pipefail

udid="$1"
dir="$2"
mkdir -p "$dir/raw"
deadline=$(( $(date +%s) + 3600 ))

say() {
  echo "[$(date +%T)] $*"
}

# Starts a recording into $1 (log $2) and sets $pid once frames flow.
start_recording() {
  # A background job of a non-interactive shell starts with SIGINT
  # ignored, and an ignored signal stays ignored across exec; recordVideo
  # only finalizes its file on SIGINT, so reset it to the default first.
  python3 -I -c 'import os, signal, sys; signal.signal(signal.SIGINT, signal.SIG_DFL); os.execvp(sys.argv[1], sys.argv[1:])' \
    xcrun simctl io "$udid" recordVideo --codec=h264 --force "$1" >"$2" 2>&1 &
  pid=$!
  # recordVideo says so once frames flow.
  for _ in $(seq 1 1800); do
    grep -qi "recording started" "$2" && return 0
    kill -0 "$pid" 2>/dev/null || { say "recordVideo exited early:"; cat "$2"; return 1; }
    sleep 0.1
  done
  say "recordVideo did not start within 180 s"
  return 1
}

# Stops the recording $pid and waits for the file to be written.
stop_recording() {
  kill -INT "$pid" 2>/dev/null || true
  for _ in $(seq 1 200); do
    kill -0 "$pid" 2>/dev/null || break
    sleep 0.1
  done
  if kill -0 "$pid" 2>/dev/null; then
    say "recordVideo ignored SIGINT; terminating"
    kill -TERM "$pid" 2>/dev/null || true
  fi
  wait "$pid" 2>/dev/null || true
}

say "warming up the recorder"
if start_recording "$dir/raw/warmup.mp4" "$dir/raw/warmup.log"; then
  sleep 1
  say "warm-up recording started"
fi
stop_recording
rm -f "$dir/raw/warmup.mp4"
say "warm-up done"

while [ "$(date +%s)" -lt "$deadline" ]; do
  for request in "$dir"/*.request; do
    [ -e "$request" ] || continue
    beat="$(basename "$request" .request)"
    rm -f "$request"
    say "request for $beat"
    log="$dir/raw/$beat.log"
    start_recording "$dir/raw/$beat.mov" "$log"
    say "recording $beat"
    : >"$dir/$beat.recording"
    while [ ! -e "$dir/$beat.done" ] && [ "$(date +%s)" -lt "$deadline" ]; do
      sleep 0.1
    done
    stop_recording
    say "saved $beat: $(stat -f %z "$dir/raw/$beat.mov" 2>/dev/null || echo missing) bytes"
    cat "$log"
    : >"$dir/$beat.saved"
  done
  [ -e "$dir/all.done" ] && exit 0
  sleep 0.2
done
say "timed out" >&2
exit 1
