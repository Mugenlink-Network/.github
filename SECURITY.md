# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| latest (main) | ✅ |
| older tags | ❌ |

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

Email: dev@mugenlink-network.me

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (optional)

We will acknowledge within 48 hours and aim to release a fix within 7 days for critical issues.

## Security Practices

- Secrets managed via [Doppler](https://doppler.com) — never committed to git
- Dependencies scanned via Renovate vulnerability alerts
- Docker images run as non-root users
- All API inputs validated via Pydantic at system boundaries
- JWT tokens: 30 min access / 7 day refresh, httpOnly cookies
- bcrypt cost factor 12 for password hashing
