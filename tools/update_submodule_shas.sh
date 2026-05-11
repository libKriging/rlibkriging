#!/usr/bin/env bash
# This script updates the tools/gitmodules-shas file with the current submodule commit SHAs
# Run this script whenever submodules are updated before creating a new tag/release

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHAS_FILE="$SCRIPT_DIR/gitmodules-shas"

echo "Updating tools/gitmodules-shas with current submodule commits..."

# Use staged index if available (during pre-commit), otherwise fall back to HEAD
# git ls-files --stage shows the staged state; for submodules mode=160000
{
  echo "# This file records the specific commit SHAs for each submodule"
  echo "# It is automatically generated and should be updated when submodules are updated"
  echo "# Format: <submodule_path> <commit_sha>"
  git ls-files --stage | awk '$1 == "160000" { print $4, $2 }'
} > "$SHAS_FILE"

echo "✓ Updated tools/gitmodules-shas:"
cat "$SHAS_FILE"

echo ""
echo "⚠ Don't forget to commit this file:"
echo "   git add tools/gitmodules-shas"
echo "   git commit -m 'Update submodule SHAs'"
