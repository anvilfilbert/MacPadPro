#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fail() {
  echo "Public repository verification failed: $1" >&2
  exit 1
}

tracked_files="$(git ls-files)"
if grep -Eq '^Tests/' <<< "$tracked_files"; then
  fail "tracked test files must stay out of the public repository"
fi

personal_pattern="f""bauer|F""rank"
path_pattern="/""Users/"
secret_pattern="sk-""proj|sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{20,}|AIza[A-Za-z0-9_-]{20,}|-----BEGIN [A-Z ]*PRIVATE KEY-----"

if rg -n --hidden --glob '!/.git/**' --glob '!build/**' --glob '!dist/**' --glob '!.build/**' --glob '!*.xcuserstate' --glob '!*.DS_Store' --glob '!scripts/verify-public-repo.sh' "$personal_pattern|$path_pattern|$secret_pattern" .; then
  fail "personal information, local paths, or secret-like values were found"
fi

echo "Public repository verification passed"
