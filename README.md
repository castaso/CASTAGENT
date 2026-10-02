<p align="center">
  <h1 align="center">CASTAGENT</h1>
  <p align="center"><strong>A rebranded fork of LibreChat</strong></p>
</p>

<p align="center">
  <a href="https://github.com/LibreChat-AI/LibreChat">
    <img
      src="https://img.shields.io/badge/upstream-LibreChat-blueviolet.svg?style=flat-square&logo=github&logoColor=white"
      alt="Upstream: LibreChat"
    />
  </a>
  <img
    src="https://img.shields.io/badge/license-MIT-green.svg?style=flat-square"
    alt="License: MIT"
  />
  <img
    src="https://img.shields.io/badge/rebrand-minimal%20overlay-009688.svg?style=flat-square"
    alt="Rebrand: minimal overlay"
  />
</p>

---

## What CASTAGENT is

**CASTAGENT** is a rebranded fork of [LibreChat](https://github.com/LibreChat-AI/LibreChat),
maintained by [castaso](https://github.com/castaso). It is LibreChat — every feature, agent,
MCP integration, provider, and deployment path — with the visible product name changed to
**CASTAGENT**.

Nothing about LibreChat's capability was removed, restricted, or reimplemented. The fork exists
to run CASTAGENT as your own product without forking the development of the application itself.

### Upstream

| | |
|---|---|
| **Project** | [LibreChat-AI/LibreChat](https://github.com/LibreChat-AI/LibreChat) |
| **Docs** | [librechat.ai/docs](https://www.librechat.ai/docs) |
| **License** | MIT — see [LICENSE](LICENSE) |
| **Version tracked** | see `git log main -1` |

Upstream is the source of truth for everything technical. If you want the latest LibreChat,
[use LibreChat](https://github.com/LibreChat-AI/LibreChat) directly — this fork adds branding
and nothing else.

## The branch model

CASTAGENT keeps two branches so that pulling in upstream work stays trivial:

| Branch | Contents |
|---|---|
| `main` | A byte-identical mirror of `upstream/main`. **Never edited.** |
| `rebrand/CASTAGENT` | `main` + the CASTAGENT branding overlay + fork docs/tooling. **This is the branch to run.** |

Flow is always forward: `upstream/main` → `main` → `rebrand/CASTAGENT`.

To deploy CASTAGENT, check out `rebrand/CASTAGENT`.

See **[SYNC.md](SYNC.md)** for the full sync runbook and
**`scripts/rebrand-replay.sh`** for the one-command version.

## What the rebrand changes

The overlay is deliberately minimal — 16 files, all listed here:

**Product name (runtime defaults)**
- `APP_TITLE` defaults → `CASTAGENT` in `api/server/routes/config.js`,
  `api/server/services/AuthService.js`, `api/server/controllers/TwoFactorController.js`,
  `config/invite-user.js`, `packages/api/src/shared-links/config.ts`,
  `client/src/utils/documentTitle.ts`, and `.env.example`
- `client/index.html` — document title and meta description
- `client/vite.config.ts` — PWA manifest `name` / `short_name` (installed-app name)
- `package.json` / `package-lock.json` — workspace package name

**Fork documentation and tooling**
- `LICENSE` — MIT text verbatim, plus a CASTAGENT rebranding notice
- `README.md` — this file
- `SYNC.md` — upstream sync runbook
- `scripts/rebrand-replay.sh` — automated sync with branding verification

### Setting the app name at runtime

`APP_TITLE` wins over every compiled-in default, so you can rebrand a deployment without
touching code:

```bash
APP_TITLE="Acme Internal AI" docker compose up -d
```

The name shows in the browser tab, the login and share pages, transactional and invite emails,
2FA account labels, shared-link pages, and the installed PWA.

### Known scope gaps

These still read "LibreChat" and are **not** part of the minimal overlay:

- Prose in English locale files (e.g. "Built into LibreChat"), and all 31 non-English locales
- The About dialog's version line
- `client/public/assets/logo.svg` and the favicons
- Internal identifiers: `X-LibreChat-Generation-Protocol`, the `librechat-*` npm package names,
  the `LibreChat-e2e` test database

These are left alone deliberately: none are the product name, and editing them would create
permanent merge conflicts against upstream. Say the word if you want any of them branded.

## Quick start

The setup is LibreChat's, unchanged.

### Docker (recommended)

```bash
git clone https://github.com/castaso/CASTAGENT.git
cd CASTAGENT
git checkout rebrand/CASTAGENT

cp .env.example .env
# edit .env: at minimum set a JWT_SECRET, JWT_REFRESH_SECRET, and your provider keys
docker compose up -d
```

CASTAGENT is then on <http://localhost:3080>.

### Local development

Requires Node 22+, npm 10+, and a MongoDB instance.

```bash
git clone https://github.com/castaso/CASTAGENT.git
cd CASTAGENT
git checkout rebrand/CASTAGENT

cp .env.example .env      # edit as above
npm install
npm run backend:start     # API on :3080
npm run frontend:dev      # Vite on :3090
```

Full upstream installation instructions, configuration reference, and troubleshooting live in
the [LibreChat documentation](https://www.librechat.ai/docs).

## License

MIT, unchanged from upstream. The LibreChat copyright and permission notice are retained in
[full and verbatim](LICENSE); the appended CASTAGENT notice describes only the rebranding
delta. CASTAGENT is not endorsed by or affiliated with the LibreChat project.

## Keeping current with upstream

```bash
./scripts/rebrand-replay.sh          # fetch upstream, fast-forward main, rebase the overlay
./scripts/rebrand-replay.sh --push   # same, and push both branches
```

The script verifies the branding markers afterwards and refuses to report success if upstream
reverted any of them. Details and troubleshooting: **[SYNC.md](SYNC.md)**.

## Special thanks

To the LibreChat maintainers and contributors, without whom this fork would not exist. See
upstream's [contributors](https://github.com/LibreChat-AI/LibreChat/graphs/contributors) and
[special thanks](https://github.com/LibreChat-AI/LibreChat#-special-thanks).

---

<p align="center">
  <sub>
    CASTAGENT is a community fork of LibreChat. Not affiliated with or endorsed by the
    LibreChat project. LibreChat is licensed under MIT, © 2026 LibreChat contributors.
  </sub>
</p>