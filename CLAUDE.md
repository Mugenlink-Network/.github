# Mugenlink Network — dotgithub (org `.github`) Repo

Org-wide GitHub defaults for Mugenlink-Network — deployed as the org's `.github`
repository (referenced as `Mugenlink-Network/.github` in `uses:` lines).

## What lives here

- `.github/` — CODEOWNERS, `ISSUE_TEMPLATE/` (bug_report, feature_request, config),
  `pull_request_template.md`, and `workflows/repo-health.yml` (a **reusable** workflow)
- `workflow-templates/` — starter workflow `repo-health.yml` + `.properties.json`
- `scripts/validate-repo.sh` — 10-section repo-health checklist validator
  (fetched raw from `main` by the reusable workflow)
- `renovate.json` — org Renovate config
- `profile/README.md` — org profile page; `CONTRIBUTING.md` / `SECURITY.md` /
  `SUPPORT.md` — org-default community health files
- `.cousage/` — the org's AI co-usage ledger (`ledger.jsonl` + `totals.json`)

## How defaults propagate

- **Community health files** (issue/PR templates, CONTRIBUTING, SECURITY, SUPPORT,
  profile README) apply automatically to member repos that lack their own — GitHub's
  org `.github` mechanism. CODEOWNERS does NOT propagate — it covers this repo only.
- **Workflow templates** appear as suggestions in member repos' Actions "New workflow"
  page — opt-in copy, no sync after copying.
- **Reusable workflow** is referenced live: member repos call
  `uses: Mugenlink-Network/.github/.github/workflows/repo-health.yml@main`.
- Everything else: **manual copy — no sync mechanism**.

## Known defects (verified 2026-07-03)

- **The repo-health gate cannot fail:** the "Run health check" step in
  `.github/workflows/repo-health.yml` sets `continue-on-error: true`, so the job is
  green regardless of validator failures (report is only uploaded as an artifact).
- **The plaintext-secret check in `validate-repo.sh` always passes:** it invokes
  `git grep --include=...` — GNU-grep syntax that `git grep` rejects — so the command
  errors out and the check falls through to its pass branch.

## Cross-repo

Cross-repo contracts: single source at /root/Mugenlink-Network/.claude/rules/contracts.md (workspace root) — do not fork contract facts into this file.
