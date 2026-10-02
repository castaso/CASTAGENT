#!/usr/bin/env bash
# rebrand-replay.sh — keep rebrand/CASTAGENT current and conflict-free on top of upstream main.
#
# Usage: scripts/rebrand-replay.sh [--push]
#
#   (no args)  fetch upstream, fast-forward main, rebase the overlay, verify branding
#   --push     same, and push main plus the rebased overlay
#
# Exits non-zero if the fast-forward is impossible, the rebase conflicts, or any branding
# marker is missing. A conflicted rebase is aborted, leaving the branch as it was.

set -euo pipefail

REBRANCH="rebrand/CASTAGENT"

# This script lives only on the rebrand branch, so checking that branch out would
# have git rewrite the file while the shell still holds it open — which Windows
# rejects. Re-exec from a copy outside the worktree to release the handle.
if [ -z "${REBRAND_REPLAY_REEXEC:-}" ]; then
  REPLAY_COPY="$(mktemp -t rebrand-replay-XXXXXX.sh)"
  cp "${BASH_SOURCE[0]}" "$REPLAY_COPY"
  chmod +x "$REPLAY_COPY" 2>/dev/null || true
  trap 'rm -f "$REPLAY_COPY"' EXIT
  REBRAND_REPLAY_REEXEC=1 exec bash "$REPLAY_COPY" "$@"
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd || true)"
if [ -z "$REPO_ROOT" ] || [ ! -d "$REPO_ROOT/.git" ]; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
fi
cd "$REPO_ROOT"

# Branding marker => file that must contain it.
MARKERS=(
  "APP_TITLE=CASTAGENT|.env.example"
  "<title>CASTAGENT</title>|client/index.html"
  "name: 'CASTAGENT'|client/vite.config.ts"
  "DEFAULT_APP_TITLE = 'CASTAGENT'|client/src/utils/documentTitle.ts"
  "CASTAGENT Rebranding Notice|LICENSE"
)

for remote in upstream origin; do
  if ! git remote get-url "$remote" >/dev/null 2>&1; then
    echo "ERROR: remote '$remote' is not configured."
    echo "  git remote add upstream https://github.com/LibreChat-AI/LibreChat.git"
    exit 1
  fi
done

if ! git show-ref --verify --quiet "refs/heads/$REBRANCH"; then
  echo "ERROR: branch '$REBRANCH' does not exist."
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: working tree is not clean. Commit or stash first."
  git status --short
  exit 1
fi

echo "==> Fetching upstream/main"
# Narrow the upstream refspec once so this stays fast; upstream has hundreds of
# branches and syncing only needs main.
if ! git config --get-all remote.upstream.fetch | grep -q 'refs/heads/main:'; then
  git config remote.upstream.fetch '+refs/heads/main:refs/remotes/upstream/main'
fi
git fetch upstream --prune

echo "==> Fast-forwarding main to upstream/main"
git checkout main
if ! git merge --ff-only upstream/main; then
  echo "ERROR: main diverged from upstream/main and cannot be fast-forwarded."
  echo "       main must stay a pristine mirror; reset it with:"
  echo "         git checkout main && git reset --hard upstream/main"
  exit 1
fi
git log -1 --oneline main

echo "==> Rebasing $REBRANCH onto main"
if ! git checkout "$REBRANCH"; then
  echo "ERROR: could not check out $REBRANCH (a Windows file lock is the usual cause)."
  echo "       Close any editor or process holding files in the tree, then retry."
  exit 1
fi
if ! git rebase main; then
  git rebase --abort || true
  echo
  echo "ERROR: rebase conflicted; $REBRANCH restored to its pre-rebase state."
  echo "       Resolve manually with: git rebase main"
  echo "       Only the overlay files listed in SYNC.md should ever conflict —"
  echo "       keep upstream's logic and change only the CASTAGENT fallback strings."
  exit 1
fi

echo "==> Verifying branding markers"
fail=0
for entry in "${MARKERS[@]}"; do
  marker="${entry%%|*}"
  file="${entry##*|}"
  if [ ! -f "$file" ]; then
    echo "  MISSING $file (upstream removed it)"
    fail=1
    continue
  fi
  if grep -qF "$marker" "$file"; then
    echo "  OK      $file :: $marker"
  else
    echo "  REVERTED $file no longer contains: $marker"
    fail=1
  fi
done

# A new upstream default would silently reintroduce the old product name.
stray=$(grep -rn "|| 'LibreChat'" \
  --include='*.js' --include='*.ts' \
  api config packages/api/src/shared-links 2>/dev/null || true)
if [ -n "$stray" ]; then
  echo
  echo "  NOTE: upstream reintroduced a 'LibreChat' APP_TITLE fallback:"
  echo "$stray" | sed 's/^/    /'
  echo "       Update these to 'CASTAGENT' to keep branding consistent."
fi

if [ "$fail" -ne 0 ]; then
  echo
  echo "ERROR: branding verification failed. Reapply the reverted overlay edits before pushing."
  exit 1
fi

if [ "${1:-}" = "--push" ]; then
  echo "==> Pushing"
  git push origin main
  git push --force-with-lease origin "$REBRANCH"
fi

echo
echo "Done. (fail=$fail)  current branch: $(git rev-parse --abbrev-ref HEAD)"
exit "$fail"