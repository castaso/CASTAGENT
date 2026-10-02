# Syncing CASTAGENT with upstream LibreChat

This fork keeps two branches so that upstream work stays a routine operation instead of a merge
project.

## Branch model

| Branch | Contents |
|---|---|
| `main` | Byte-identical mirror of `upstream/main`. Never edited, never force-pushed with local work. |
| `rebrand/CASTAGENT` | `main` + the CASTAGENT branding overlay + fork docs and tooling. |

Flow is always forward:

```
upstream/main  ──▶  main  ──▶  rebrand/CASTAGENT
```

Verify the invariant at any time — this must print nothing:

```bash
git diff upstream/main main --stat
```

## Routine sync

```bash
./scripts/rebrand-replay.sh          # fetch upstream, ff main, rebase overlay, verify branding
./scripts/rebrand-replay.sh --push   # same, and push both branches
```

The script aborts and restores `rebrand/CASTAGENT` to its pre-rebase state if the rebase
conflicts, so a failed sync never leaves the branch half-rebased.

### Doing it by hand

```bash
git fetch upstream --prune

git checkout main
git merge --ff-only upstream/main     # fails loudly if main ever diverges
git push origin main

git checkout rebrand/CASTAGENT
git rebase main
# resolve conflicts — only overlay files should ever conflict (see the file list below)
git rebase --continue
git push --force-with-lease origin rebrand/CASTAGENT
```

### Rebase vs merge

- **rebase** (default here) — rewrites the overlay commits on top of the new `main`, keeping
  history linear and the diff to upstream readable. Requires `--force-with-lease` on push.
- **merge** — preserves exact commit SHAs and never rewrites published history, at the cost of a
  merge commit on every sync.

If anyone else pushes to `rebrand/CASTAGENT`, use merge. For a single-maintainer fork, rebase
keeps the log cleaner.

## Why this stays conflict-free

The overlay is 16 paths. Everything else is byte-identical to upstream, so an upstream change to
any other file applies without ever meeting your changes.

**Branding defaults (12 modified)**

1. `api/server/routes/config.js` — `appTitle` for the startup config payload
2. `api/server/services/AuthService.js` — `appName` in 4 transactional/invite email templates
3. `api/server/controllers/TwoFactorController.js` — `safeAppTitle` for 2FA account labels
4. `config/invite-user.js` — `appName` in the CLI invite email
5. `packages/api/src/shared-links/config.ts` — `appTitle` for shared-link pages
6. `client/src/utils/documentTitle.ts` — `DEFAULT_APP_TITLE` (browser tab fallback)
7. `client/src/utils/__tests__/documentTitle.test.ts` — keeps the title tests passing
8. `client/index.html` — `<title>` and meta description
9. `client/vite.config.ts` — PWA manifest `name` / `short_name`
10. `package.json` — workspace package name
11. `package-lock.json` — lockfile name, kept in step with `package.json`
12. `.env.example` — `APP_TITLE=CASTAGENT`

**Fork docs and tooling (2 modified, 2 new)**

12. `LICENSE` — MIT text verbatim + CASTAGENT rebranding notice
13. `README.md` — this fork's README
14. `SYNC.md` — this file (never in upstream, so it never conflicts)
15. `scripts/rebrand-replay.sh` — this fork's sync script

Upstream rarely edits the branding default lines (they sit inside larger functions), so
conflicts are uncommon. When one does happen it is nearly always a one-line resolution: keep
`CASTAGENT` as the fallback.

### What is deliberately not rebranded

A bulk `s/LibreChat/CASTAGENT/g` would touch 100+ files that upstream churns regularly, turning
every future sync into a conflict. Left alone on purpose:

- Code comments, test fixture names, Mongo test database names
- Internal identifiers and wire protocol: `X-LibreChat-Generation-Protocol`, `lc-*` storage keys,
  the `librechat-*` npm workspace package names
- The 31 non-English locale files, and prose inside the English locale strings
- `client/public/assets/logo.svg` and the favicons (binary assets; upstream updates them)

## Branding verification

The sync script checks three markers and fails if any is missing:

| Marker | File |
|---|---|
| `APP_TITLE=CASTAGENT` | `.env.example` |
| `<title>CASTAGENT</title>` | `client/index.html` |
| `name: 'CASTAGENT'` | `client/vite.config.ts` |
| `DEFAULT_APP_TITLE = 'CASTAGENT'` | `client/src/utils/documentTitle.ts` |
| `CASTAGENT REBRANDING NOTICE` | `LICENSE` |

A missing marker means an upstream commit reverted one of the overlay edits. Restore it before
pushing — otherwise the branch reports success while the product name is wrong.

Manual check:

```bash
grep -F 'APP_TITLE=CASTAGENT' .env.example
grep -F '<title>CASTAGENT</title>' client/index.html
grep -F "name: 'CASTAGENT'" client/vite.config.ts
grep -F "DEFAULT_APP_TITLE = 'CASTAGENT'" client/src/utils/documentTitle.ts
grep -F 'CASTAGENT REBRANDING NOTICE' LICENSE
```

## Setting the name per deployment

`APP_TITLE` overrides every compiled-in default, so a deployment can be renamed without any
code change:

```bash
APP_TITLE="Acme Internal AI" docker compose up -d
```

## Tags and releases

Upstream tags are fetched but not mirrored to `origin`. To publish a CASTAGENT release, tag from
`rebrand/CASTAGENT`:

```bash
git checkout rebrand/CASTAGENT
git tag -a castagent-v0.8.8 -m "CASTAGENT v0.8.8 (upstream 0.8.8)"
git push origin castagent-v0.8.8
```

## Porting the rebrand to a new clone

```bash
git clone https://github.com/castaso/CASTAGENT.git
cd CASTAGENT
git remote add upstream https://github.com/LibreChat-AI/LibreChat.git
git fetch upstream
git checkout rebrand/CASTAGENT
npm install
```

## Troubleshooting

**`main` diverged from `upstream/main`**
Someone committed to `main`. It should be a mirror; restore it:

```bash
git checkout main
git reset --hard upstream/main
git push -f origin main
```

**The rebase conflicts in `LICENSE` or `README.md`**
Upstream rewrote those files. Take upstream's version wholesale, then re-append the CASTAGENT
rebranding notice (see `LICENSE` on `main` for the shape) or restore this fork's README.

**The rebase conflicts in `AuthService.js` or another server file**
Upstream changed the surrounding function. Keep upstream's logic and change only the fallback
string: `process.env.APP_TITLE || 'CASTAGENT'`.

**A branding marker is reported missing after a sync**
Upstream reverted one of the overlay lines. Reapply it and amend the overlay commit rather than
adding a fixup commit.

**`npm ci` fails after renaming the package**
`package.json` and `package-lock.json` must carry the same `name` field. Both are `CASTAGENT`;
keep them in step.

## Attribution

- Upstream: https://github.com/LibreChat-AI/LibreChat — MIT, © 2026 LibreChat contributors
- Fork: https://github.com/castaso/CASTAGENT
- See [LICENSE](LICENSE) and [README.md](README.md).