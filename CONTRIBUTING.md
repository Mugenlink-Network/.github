# Contributing to Mugenlink Network

## Development Setup

### Python repos (api, pipeline, sdk)
```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install deps
uv sync --all-packages

# Run tests
uv run pytest

# Lint + format
uv run ruff check .
uv run ruff format .
```

### Console (Next.js)
```bash
npm ci
npm run dev
npm run test
npm run type-check
```

### Infra (Terraform + Helm)
```bash
# Validate Helm charts
helm lint kubernetes/helm/

# Validate Terraform
terraform -chdir=terraform/environments validate
```

## Commit Convention

```
type(scope): description

Types: feat | fix | refactor | docs | test | chore | perf
Scopes: etl | api | dashboard | infra | dbt | auth | sdk
```

Examples:
```
feat(api): add wallet balance endpoint
fix(etl): handle 402 response without download key
chore(sdk): bump mugenlink-logging to 4.1.0
```

## Pull Request Process

1. Branch from `main`: `feat/<description>` or `fix/<description>`
2. All CI checks must pass
3. 1 approving review required
4. Squash-merge only (no merge commits)
5. Update CHANGELOG.md for user-visible changes

## Secrets

Never commit secrets. Use Doppler:
```bash
doppler run -p <project> -c <config> -- <command>
```

See `docs/guides/doppler-architecture.md` for the full secrets model.
