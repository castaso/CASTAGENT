---
name: sync-castagent
description: Use when the user asks to sync the CASTAGENT fork with upstream deepseek-ai/deepseek-harness. Fast-forwards the clean master mirror, rebases the rebrand/castagent branding overlay onto it, and publishes both branches.
---

# Sync CASTAGENT

Sync the `castaso/CASTAGENT` fork with `deepseek-ai/deepseek-harness` while keeping the branch split intact: `master` is the pristine upstream mirror (fast-forward only, never force-pushed, never carries branding), and `rebrand/castagent` is the CASTAGENT branding overlay (exactly one commit series on top of `master`, currently `README.md`, `README.zh.md`, `README.i18n.yaml`, `LICENSE`, and this skill). Never merge the overlay into `master`, and never commit branding to `master`.

## Preflight

1. Confirm a clean worktree and record the starting state.

```sh
git status --short --branch
git rev-parse --show-toplevel
```

Stop if the worktree is not clean. Do not stash or discard user changes to make it clean.

2. Verify the remotes, then record the exact OIDs that later steps lease against.

```sh
git remote -v
git rev-parse master origin/master rebrand/castagent origin/rebrand/castagent upstream/master
```

`origin` must be `castaso/CASTAGENT` and `upstream` must be `deepseek-ai/deepseek-harness`. Stop if either remote is missing or points elsewhere.

## Phase 1: fast-forward the clean mirror

```sh
git fetch upstream
git checkout master
git merge --ff-only upstream/master
git push origin master
```

If the `--ff-only` merge fails, `master` has diverged from upstream. Stop and report the divergence. Never merge, resolve, or force-push `master`.

## Phase 2: rebase and publish the overlay

Record the live `origin/rebrand/castagent` OID first, then rebase the overlay onto the freshly synced `master`.

```sh
git rev-parse origin/rebrand/castagent
git checkout rebrand/castagent
git rebase master
git push --force-with-lease=rebrand/castagent:<observed-oid> origin rebrand/castagent
```

Replace `<observed-oid>` with the OID recorded before the rebase. A lease failure means the remote moved concurrently: refetch, re-verify, and stop. Raw `--force` is never allowed.

## Rebase conflicts

Auto-resolve only conflicts inside the overlay files (`README.md`, `README.zh.md`, `README.i18n.yaml`, `LICENSE`, `.agents/skills/sync-castagent/SKILL.md`): keep upstream's functional lines, re-apply the CASTAGENT banner, title, copyright notice, or skill content on top, re-record the i18n blob hashes with `git hash-object README.md README.zh.md`, and run `git rebase --continue`. If a conflict touches any other file, looks ambiguous, or cannot be resolved by re-applying the overlay, run `git rebase --abort`, leave the branches unpushed, and report the conflicted files. Never push a half-resolved overlay.

## Finish on master and verify

```sh
git checkout master
git ls-remote --heads origin
git rev-parse master upstream/master origin/master
git diff master...rebrand/castagent --stat
```

`master`, `upstream/master`, and `origin/master` must agree. The `master...rebrand/castagent` diff must list only overlay files. Report the synced OIDs and the overlay diff stat when done.
