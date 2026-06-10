# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| latest (main) | ✅ |
| older tags | ❌ |

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

Preferred: open a private report via **GitHub Security → Report a vulnerability**
(Private Vulnerability Reporting) on the affected repository.

Alternatively, email: dev@mugenlink.io

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (optional)

We will acknowledge within 48 hours and aim to release a fix within 7 days for critical issues.

## Org-wide Security Practices

These apply across all Mugenlink Network repositories:

- Secrets managed via [Doppler](https://doppler.com) — never committed to git
- Dependencies scanned via Renovate vulnerability alerts
- Container images run as non-root users
- detect-secrets pre-commit / CI baseline guards against committed secrets

Repository-specific controls (e.g. API auth/session settings, password hashing
parameters, input-validation frameworks) are documented in each repo's own
`README.md` / `CLAUDE.md` and are intentionally **not** asserted here as
org-wide facts, since they differ between application, infrastructure, and
library repositories.
