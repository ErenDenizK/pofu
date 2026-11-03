# Recover an interrupted art run

`operator_state.py` records take-fragment evidence for the operator. It does not
automatically generate art, choose takes, change QA, promote, fetch, push, merge,
or repair authentication. Only the lock wrapper executes a caller-supplied command.
The queue, account guards and retry/stop rules in `AGENTS.md` still apply.

From the repository root, with the image-pipeline environment:

```sh
python3 -I tools/imagegen/operator_state.py --batch batch-NN-name reconcile
python3 -I tools/imagegen/operator_state.py --batch batch-NN-name status
```

State defaults to the ignored `build/operator-state/recovery/` directory.
`--runtime` selects the directory containing the operator's per-take callback
JSONs, `*-POSTED.json` flags, successful `*upload*.log` files and active
`GLOBAL_STOP.json`. `--repo` and `--state-dir` allow separate art worktrees.
Never commit the database, WAL, inventories, cached source paths or local logs.

The SQLite database uses WAL and `synchronous=FULL`; each snapshot and its
monotone take high-water marks commit in one transaction. JSON exports use an
fsynced temporary file, atomic replacement and directory fsync. An interrupted
write cannot create a completed stage. Repeating reconciliation does not add
duplicate evidence events. `recovery-manifest.json` contains artifact hashes
and facts; `status.json` lists the next action supported by those facts.

## Resume from evidence

Reconciliation checks original PNGs, ingested sidecars, locked images, complete
QA reports, manual review fragments, committed artifacts and already-fetched Git
refs. It decodes images one at a time to bound memory use. Ingest re-encodes PNGs:
original and inbox file hashes may differ while dimensions and decoded pixels
remain identical. Recovery compares canonical RGBA pixels and retains both byte
identities. Legacy review
fields that hashed the inbox PNG are recognized without pretending those bytes
are the original generated file.

An upload is verified only when the working artifact matches both its committed
blob and an already-fetched remote ref, and a successful `check_upload.py` log
covers the path. This is evidence about that fetched ref, not a fresh network
check or a replacement for the required fetch/upload check after a push. Missing
logs, changed bytes or incomplete bundles stay unverified. Originals without
upload evidence are explicitly marked local-only. A published review preserves
take IDs and retry usage if local caches are lost; completed outputs never become
a fresh generation request merely because an original or cache is unavailable.

Count-only legacy `POSTED` flags are unbound hints. Fresh receipts bind the
complete source and QA hash sets, so a new take or changed content invalidates
them even if the take count stays the same:

```sh
python3 -I tools/imagegen/operator_state.py --batch batch-NN-name \
  checkpoint --job job-id --stage posted
```

Other supported completion stages are `generated`, `reviewed`, `committed` and
`upload_verified`. A checkpoint cannot assert a stage unsupported by the current
files. An active stop marker freezes new receipts and reservations; a partial
stop JSON still means stop. Reconciliation itself remains available to preserve
and inspect finished work. It does not reset the shared failure ledger.

Every snapshot, job and receipt declares `scope: take_fragments_only`. In
particular, `committed` and `upload_verified` refer to the take/contact/review
bundle, not a whole production job. Production masters, raw.webp, provenance,
content nodes and Harmony entries still require the normal pipeline checks.
`take_fragments_verified_no_regeneration` means preserve that verified bundle
and check the remaining batch deliverables; it never asserts production complete.

## Bounded parallel work

Use concurrent image calls for independent ready jobs, in small output groups
(prefer two jobs/four images per exec), within the manifest's image cap. Several
independent exec groups can run concurrently while respecting the total cap
(currently 40 images/run); small groups avoid large IPC display buffers. Persist
every returned source path and callback immediately. Keep each edit chain
sequential and retain every original. Source creation, post-processing, review,
commit and fetched upload verification are separate checkpoints.

Reserve an initial pair only after a fresh main/queue/account/reference preflight:

```sh
python3 -I tools/imagegen/operator_state.py --batch batch-NN-name \
  reserve --job job-id --round 0 --request-key stable-unique-request-id
```

A request key replay returns the existing reservation with **do not redispatch**.
If a worker disconnects after reservation, inspect callbacks and original files;
do not blindly send another generation. Continue independent jobs while that
request is uncertain. A retry reservation uses `--round 1` and an explicit
`--retry-reason`; it requires a completed initial pair. Only one retry pair
exists, and its use survives restarts. Reservations are persisted/exported before
the caller is told to dispatch. The helper never invokes the image tool.

Use one writer per branch. The optional wrapper serializes an explicitly
supplied command and can check the expected local head:

```sh
python3 -I tools/imagegen/operator_state.py --batch batch-NN-name \
  with-branch-lock --expected-head COMMIT -- command arg
```

The child inherits the kernel lock if the wrapper disconnects. A leftover PID
file is descriptive, not a lock that must be deleted. Git writes still need
normal branch leases and identity checks. Wait for each publication and its
upload check to finish before starting another publication on that branch.

## Control plane and worker

The worker performs shell, QA and file operations. An independent control plane
can keep checking GitHub and recording public PR progress when the worker is
temporarily offline. A supplied PR-body checkpoint may be imported locally:

```sh
python3 -I tools/imagegen/operator_state.py --batch batch-NN-name \
  import-control --body saved-pr-body.md
```

The supported marker is `POFU_QUEUE_WATCH_STATE` with version, start/deadline,
next poll, known batches, polls, status and errors. Import copies the evidence;
it never invents a poll, claims worker health or restarts the two-hour clock.
The control plane must re-read the newest `AGENTS.md` and queue and respect
ownership before scheduling another READY batch. It never starts BLOCKED work.

`classify-error MESSAGE` distinguishes temporary worker transport loss and
oversized display payloads from account/usage/refusal stops. A worker outage is
not an actual failed art job. This classification reports evidence only; it does
not waive any stop rule or promise that platform outages cannot occur. Avoid
large image payloads, preserve completed work, and resume from the last verified
step without asking the founder to repair a worker that can reconnect itself.
