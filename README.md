# .github — Mugenlink Network org-wide defaults

Org-level community health files (PR templates, issue templates, org profile)
and **reusable workflows** shared across all Mugenlink Network repositories.

---

## Reusable workflows

Each workflow lives in `.github/workflows/` and is called with
`uses: Mugenlink-Network/.github/.github/workflows/<file>@main`.

---

### `codeql.yml` — CodeQL SAST analysis

Runs GitHub's CodeQL static-analysis engine against one or more language
targets and uploads SARIF results to GitHub code scanning.

**Inputs**

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `languages` | yes | — | JSON array, e.g. `'["python"]'` or `'["javascript-typescript"]'` |
| `queries` | no | `security-and-quality` | CodeQL query suite |

**Caller permissions required**

```yaml
permissions:
  actions: read
  contents: read
  security-events: write   # required to upload SARIF to code scanning
```

**Copy-paste caller snippet**

```yaml
jobs:
  codeql:
    uses: Mugenlink-Network/.github/.github/workflows/codeql.yml@main
    permissions:
      actions: read
      contents: read
      security-events: write
    with:
      languages: '["python"]'   # or '["javascript-typescript"]', '["go"]', etc.
```

---

### `secret-scan.yml` — detect-secrets audit

Audits all tracked files against the repo's committed `.secrets.baseline`
(or scans outright if no baseline exists). Fails the build on any unreviewed
secret.

**Inputs**

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `detect-secrets-version` | no | `1.5.0` | Pinned `detect-secrets` PyPI version |

**Caller permissions required**

```yaml
permissions:
  contents: read
```

**Copy-paste caller snippet**

```yaml
jobs:
  secret-scan:
    uses: Mugenlink-Network/.github/.github/workflows/secret-scan.yml@main
    permissions:
      contents: read
```

---

### `scorecard.yml` — OpenSSF Scorecard

Runs the OpenSSF Scorecard against the repository and uploads results as SARIF
to GitHub code scanning. Schedule weekly on `main`; optionally publish results
to the OpenSSF API for public repos.

**Inputs**

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `publish_results` | no | `false` | Set `true` only for public repos that want an OpenSSF badge |

**Caller permissions required**

```yaml
permissions:
  contents: read
  security-events: write   # SARIF upload
  id-token: write          # OpenSSF publishing (required even when publish_results: false)
```

**Copy-paste caller snippet**

```yaml
on:
  schedule:
    - cron: "0 6 * * 1"   # weekly, Monday 06:00 UTC
  push:
    branches: [main]

jobs:
  scorecard:
    uses: Mugenlink-Network/.github/.github/workflows/scorecard.yml@main
    permissions:
      contents: read
      security-events: write
      id-token: write
```

---

### `repo-health.yml` — Repo health gate

Runs the Mugenlink repo-health validator (`scripts/validate-repo.sh`) against
the calling repository, uploads a plain-text report as a workflow artifact, and
**fails the job** if the validator exits non-zero. Suitable as a required status
check on branch-protection rules.

**Inputs:** none.

**Caller permissions required**

```yaml
permissions:
  contents: read
```

**Copy-paste caller snippet**

```yaml
jobs:
  health:
    uses: Mugenlink-Network/.github/.github/workflows/repo-health.yml@main
    permissions:
      contents: read
```

The artifact `health-report` (plain text, 30-day retention) is uploaded on
every run — including failures — so you can review what failed without re-running
the job.

---

## Self-CI

This repo runs `actionlint` over all reusable workflows and `shellcheck` over
`scripts/*.sh` on every push and pull request (`.github/workflows/ci.yml`).
All changes to this repo must pass CI before merging to `main`.
