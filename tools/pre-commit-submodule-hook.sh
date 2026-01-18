#!/usr/bin/env bash
# Pre-commit hook to ensure .gitmodules-shas is updated when submodules change
# To install this hook: cp tools/pre-commit-submodule-hook.sh .git/hooks/pre-commit

set -e

# Check if any submodule changes are being committed
if git diff --cached --name-only | grep -q "^src/libK\|^src/slapack"; then
  echo "Submodule changes detected, updating .gitmodules-shas..."
  
  # Update the .gitmodules-shas file
  ./tools/update_submodule_shas.sh
  
  # Stage the updated file
  git add .gitmodules-shas
  
  echo "✓ .gitmodules-shas updated and staged"
fi
