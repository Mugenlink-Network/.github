#!/usr/bin/env bash
# =============================================================================
# Mugenlink Network — Repo Health Validator
# Usage: bash validate-repo.sh [/path/to/repo]
#        (defaults to current directory)
#
# Validates all 10 sections of the Mugenlink repo health checklist.
# Exit code: 0 = all pass, 1 = any failures found.
# =============================================================================

set -uo pipefail

REPO="${1:-$(pwd)}"
REPO_NAME="$(basename "$REPO")"

# ---------------------------------------------------------------------------
# Colours
# ---------------------------------------------------------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

pass()  { echo -e "  ${GREEN}✅ $1${RESET}"; PASS=$((PASS+1)); }
fail()  { echo -e "  ${RED}❌ $1${RESET}"; FAIL=$((FAIL+1)); FAILURES+=("$1"); }
warn()  { echo -e "  ${YELLOW}⚠️  $1${RESET}"; WARN=$((WARN+1)); }
section(){ echo -e "\n${CYAN}${BOLD}── $1 ──────────────────────────────────${RESET}"; }

PASS=0; FAIL=0; WARN=0
FAILURES=()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
has_file()    { [ -f "$REPO/$1" ]; }
has_dir()     { [ -d "$REPO/$1" ]; }
file_contains(){ grep -q "$2" "$REPO/$1" 2>/dev/null; }
any_workflow_contains() { grep -rl "$1" "$REPO/.github/workflows/" 2>/dev/null | grep -q .; }

# Detect repo type
IS_PYTHON=false; IS_NODE=false; IS_SDK=false
IS_INFRA=false; IS_GITOPS=false
has_file "pyproject.toml" && IS_PYTHON=true
has_file "package.json"   && IS_NODE=true
[[ "$REPO_NAME" == "sdk" ]] && IS_SDK=true
[[ "$REPO_NAME" == "infra" ]] && IS_INFRA=true
[[ "$REPO_NAME" == "gitops" ]] && IS_GITOPS=true

echo -e "\n${BOLD}Mugenlink Repo Health Check — ${CYAN}${REPO_NAME}${RESET}"
echo -e "Path: $REPO"
echo -e "Type: $(${IS_PYTHON} && echo 'Python ') $(${IS_NODE} && echo 'Node ') $(${IS_SDK} && echo '[SDK] ') $(${IS_INFRA} && echo '[Infra] ') $(${IS_GITOPS} && echo '[GitOps] ')"

# =============================================================================
# A. IDENTITY & DISCOVERY
# =============================================================================
section "A. Identity & Discovery"

has_file "README.md"   && pass "README.md"        || fail "README.md missing"
has_file "LICENSE"     && pass "LICENSE"           || fail "LICENSE file missing"
has_file "CHANGELOG.md" \
  || has_file "HISTORY.md" \
  || find "$REPO/docs" -name "CHANGELOG.md" -maxdepth 3 -quit 2>/dev/null | grep -q . \
  && pass "CHANGELOG exists" || warn "CHANGELOG.md missing (add at root or docs/)"
has_file ".gitignore"  && pass ".gitignore"        || fail ".gitignore missing"

if $IS_PYTHON; then
  has_file ".python-version" && pass ".python-version pins Python version" \
    || warn ".python-version missing — uv picks system Python"
fi

# =============================================================================
# B. SECURITY
# =============================================================================
section "B. Security"

has_file "SECURITY.md" && pass "SECURITY.md" \
  || warn "SECURITY.md missing (org-level fallback covers this)"

has_file ".secrets.baseline" && pass "detect-secrets baseline committed" \
  || warn ".secrets.baseline missing — run: detect-secrets scan > .secrets.baseline"

if has_file ".gitignore"; then
  file_contains ".gitignore" "\.env"  && pass ".gitignore blocks .env"  || fail ".gitignore must block .env"
  file_contains ".gitignore" "\.pem\|\.key\|credentials" \
    && pass ".gitignore blocks key files" || warn ".gitignore should block *.pem *.key credentials.json"
fi

# Check for obvious secret patterns in tracked files (fast scan — not full history)
if git -C "$REPO" grep -rn \
    --include="*.py" --include="*.ts" --include="*.yml" --include="*.yaml" \
    -iE "(password|secret|token|api_key)\s*=\s*['\"][^'\"]{8,}" \
    -- ':!*.secrets.baseline' ':!*test*' ':!*spec*' \
    2>/dev/null | grep -qv "secretRef\|secretName\|valueFrom\|secretKeyRef\|os\.getenv\|os\.environ\|settings\.\|config\."; then
  fail "Possible plaintext secrets found — run: git grep -rn 'password\\|token\\|secret'"
else
  pass "No obvious plaintext secrets in tracked files"
fi

# =============================================================================
# C. CONTRIBUTION CONTRACT
# =============================================================================
section "C. Contribution Contract"

( has_file ".github/CODEOWNERS" || has_file "CODEOWNERS" ) \
  && pass "CODEOWNERS"  || fail "CODEOWNERS missing"

( has_file ".github/pull_request_template.md" \
  || has_file ".github/PULL_REQUEST_TEMPLATE.md" ) \
  && pass "PR template" || warn "PR template missing (org-level default covers this)"

has_dir ".github/ISSUE_TEMPLATE" \
  && pass "Issue templates" || warn "Issue templates missing (org-level default covers this)"

has_file ".pre-commit-config.yaml" \
  && pass ".pre-commit-config.yaml" || fail ".pre-commit-config.yaml missing"

# =============================================================================
# D. CODE QUALITY GATES
# =============================================================================
section "D. Code Quality Gates"

if $IS_PYTHON; then
  file_contains "pyproject.toml" "\[tool\.ruff\]" \
    && pass "ruff configured"  || fail "ruff not configured in pyproject.toml"
  file_contains "pyproject.toml" "\[tool\.mypy\]" \
    && pass "mypy configured"  || fail "mypy not configured in pyproject.toml"
  file_contains "pyproject.toml" "\[tool\.pytest" \
    && pass "pytest configured" || fail "pytest not configured in pyproject.toml"
  file_contains "pyproject.toml" "fail_under" \
    && pass "coverage threshold set" || fail "coverage fail_under not set in pyproject.toml"

  # Check threshold value is meaningful
  threshold=$(grep "fail_under" "$REPO/pyproject.toml" 2>/dev/null | grep -oE "[0-9]+" | head -1)
  if [[ -n "$threshold" ]]; then
    if (( threshold < 60 )); then
      warn "coverage fail_under=$threshold is low (target ≥70 for services, ≥80 for libs)"
    else
      pass "coverage threshold acceptable ($threshold%)"
    fi
  fi

  file_contains "pyproject.toml" "\[tool\.bandit\]\|\[tool\.bandit " \
    && pass "bandit configured" || warn "bandit not configured (security linting)"
fi

if $IS_NODE; then
  file_contains "package.json" '"lint"'      && pass "lint script"      || fail "lint script missing in package.json"
  file_contains "package.json" '"type-check"' && pass "type-check script" || warn "type-check script missing"
  file_contains "package.json" '"test"'      && pass "test script"      || fail "test script missing in package.json"
  has_file "tsconfig.json" && file_contains "tsconfig.json" '"strict".*true\|"strict": true' \
    && pass "TypeScript strict mode" || fail "TypeScript strict mode not enabled"
fi

# =============================================================================
# E. CI / CD PIPELINE
# =============================================================================
section "E. CI/CD Pipeline"

has_dir ".github/workflows" && pass ".github/workflows/ exists" \
  || fail ".github/workflows/ missing — no CI"

any_workflow_contains "ruff\|lint\|pytest\|npm run test\|npm run lint" \
  && pass "CI quality job (lint/test)" || fail "No lint/test workflow found"

if ! $IS_INFRA && ! $IS_GITOPS && ! $IS_SDK; then
  any_workflow_contains "docker/build-push-action\|docker build\|ghcr\.io" \
    && pass "Docker build workflow" || fail "No Docker build/push workflow"
  any_workflow_contains "ghcr\.io/mugenlink-network" \
    && pass "Image pushes to GHCR" || warn "Verify image tagged as ghcr.io/mugenlink-network/<repo>"
fi

if $IS_SDK; then
  any_workflow_contains "uv publish\|harbor.*publish\|publish" \
    && pass "publish.yml for Harbor" || fail "No Harbor publish workflow found"
fi

if $IS_INFRA; then
  any_workflow_contains "helm lint\|helm template" \
    && pass "Helm lint workflow" || fail "No Helm lint workflow"
  any_workflow_contains "terraform validate\|terraform fmt" \
    && pass "Terraform validate workflow" || fail "No Terraform validate workflow"
fi

if $IS_GITOPS; then
  any_workflow_contains "yamllint\|argocd\|ApplicationSet" \
    && pass "GitOps validation workflow" || fail "No GitOps validation workflow"
fi

# =============================================================================
# F. DEPENDENCY MANAGEMENT
# =============================================================================
section "F. Dependency Management"

if $IS_PYTHON; then
  has_file "uv.lock" && pass "uv.lock committed" || fail "uv.lock missing"
  # Check for wildcard pins
  if grep -E '^\s*([\w-]+)\s*=\s*"[*]"' "$REPO/pyproject.toml" 2>/dev/null | grep -qv "^#"; then
    warn "Wildcard version pins found in pyproject.toml — use >=X.Y,<X+1"
  else
    pass "No wildcard version pins"
  fi
fi

if $IS_NODE; then
  has_file "package-lock.json" && pass "package-lock.json committed" \
    || fail "package-lock.json missing"
fi

# =============================================================================
# G. SCALABILITY & PERFORMANCE MARKERS
# =============================================================================
section "G. Scalability & Performance"

if $IS_PYTHON && ! $IS_SDK; then
  # Check connection pool config
  grep -r "pool_size\|max_overflow" "$REPO" --include="*.py" -l 2>/dev/null | grep -q . \
    && pass "DB connection pool bounds configured" \
    || warn "pool_size/max_overflow not found — verify asyncpg pool is bounded"

  # Check for bare CAST on blockchain data
  if grep -r "CAST(" "$REPO" --include="*.py" --include="*.sql" -l 2>/dev/null | grep -q .; then
    warn "CAST() found — verify all Snowflake external data uses TRY_CAST instead"
  else
    pass "No bare CAST() detected"
  fi
fi

if $IS_NODE; then
  grep -r "staleTime" "$REPO" --include="*.ts" --include="*.tsx" -l 2>/dev/null | grep -q . \
    && pass "TanStack Query staleTime configured" \
    || warn "staleTime not set — blockchain data queries will refetch on every focus"
fi

# =============================================================================
# H. MAINTAINABILITY
# =============================================================================
section "H. Maintainability"

if $IS_SDK; then
  # Check all lib versions are consistent
  versions=$(find "$REPO/libs" -name "pyproject.toml" -exec grep '^version' {} \; \
    | sed 's/version = //' | tr -d '"' | sort -u | wc -l)
  if [[ "$versions" -gt 1 ]]; then
    warn "Lib versions are inconsistent — run: grep '^version' libs/*/pyproject.toml"
  else
    pass "All lib versions consistent"
  fi

  # Check for zero-test libs
  for lib in "$REPO/libs"/*/; do
    libname=$(basename "$lib")
    [[ "$libname" == "_archived" ]] && continue
    count=$(find "$lib" -name "test_*.py" 2>/dev/null | wc -l)
    if [[ "$count" -eq "0" ]]; then
      fail "$libname has 0 test files"
    fi
  done
fi

# Check for TODO without issue number
todo_count=$(grep -rn "TODO\|FIXME\|HACK" "$REPO" \
  --include="*.py" --include="*.ts" --include="*.tsx" \
  2>/dev/null | grep -v "TODO(#\|TODO: #" | grep -v "test\|spec\|_archived" | wc -l)
if [[ "$todo_count" -gt 0 ]]; then
  warn "$todo_count TODO/FIXME without linked issue (format: TODO(#123): ...)"
else
  pass "No unlinked TODOs"
fi

# =============================================================================
# I. OBSERVABILITY
# =============================================================================
section "I. Observability"

if ! $IS_GITOPS && ! $IS_SDK; then
  grep -r "mugenlink_logging\|from mugenlink_logging\|getLogger" \
    "$REPO" --include="*.py" -l 2>/dev/null | grep -q . \
    && pass "Structured logging in use" \
    || warn "No mugenlink_logging usage found — verify structured logs"

  grep -r "prometheus_client\|Counter(\|Histogram(\|Gauge(" \
    "$REPO" --include="*.py" -l 2>/dev/null | grep -q . \
    && pass "Prometheus metrics instrumented" \
    || warn "No Prometheus metrics found — add counters for key operations"

  grep -r "/api/health\|/health\|healthcheck\|HEALTHCHECK" \
    "$REPO" --include="*.py" --include="Dockerfile*" --include="*.ts" -l 2>/dev/null \
    | grep -q . \
    && pass "Health check endpoint exists" \
    || warn "No health check found"
fi

# =============================================================================
# J. DEVELOPER EXPERIENCE
# =============================================================================
section "J. Developer Experience (Claude Code)"

has_file "CLAUDE.md"                    && pass "CLAUDE.md"         || fail "CLAUDE.md missing"
has_dir ".claude"                       && pass ".claude/ directory" || fail ".claude/ missing"
has_file ".claude/memory/MEMORY.md"     && pass "Memory seeded"     || warn ".claude/memory/MEMORY.md missing"
has_dir ".claude/rules"                 && pass ".claude/rules/"    || warn ".claude/rules/ missing"
has_dir ".claude/hooks"                 && pass ".claude/hooks/"    || warn ".claude/hooks/ missing"
has_file ".claudeignore"                && pass ".claudeignore"     || warn ".claudeignore missing"

# =============================================================================
# FINAL SCORE
# =============================================================================
TOTAL=$((PASS + FAIL + WARN))
SCORE=0
[[ $((PASS + FAIL)) -gt 0 ]] && SCORE=$(( PASS * 100 / (PASS + FAIL) ))

echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  Results for: ${CYAN}${REPO_NAME}${RESET}"
echo -e "  ${GREEN}✅ Pass: ${PASS}${RESET}   ${RED}❌ Fail: ${FAIL}${RESET}   ${YELLOW}⚠️  Warn: ${WARN}${RESET}"
echo -e "  ${BOLD}Score (pass / pass+fail): ${SCORE}%${RESET}"

if [[ ${#FAILURES[@]} -gt 0 ]]; then
  echo -e "\n${RED}${BOLD}  Required fixes:${RESET}"
  for f in "${FAILURES[@]}"; do
    echo -e "  ${RED}  → $f${RESET}"
  done
fi

echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"

[[ $FAIL -eq 0 ]] && exit 0 || exit 1
