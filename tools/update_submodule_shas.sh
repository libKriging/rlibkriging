#!/usr/bin/env bash
# This script updates the .gitmodules-shas file with the current submodule commit SHAs
# Run this script whenever submodules are updated before creating a new tag/release

set -eo pipefail

echo "Updating .gitmodules-shas with current submodule commits..."

# Get the list of submodules and their commits
git ls-tree HEAD $(git config --file .gitmodules --get-regexp path | awk '{ print $2 }') > .gitmodules-shas.tmp

# Add header and format
{
  echo "# This file records the specific commit SHAs for each submodule"
  echo "# It is automatically generated and should be updated when submodules are updated"
  echo "# Format: <submodule_path> <commit_sha>"
  awk '{print $4, $3}' .gitmodules-shas.tmp
} > .gitmodules-shas

rm -f .gitmodules-shas.tmp

echo "✓ Updated .gitmodules-shas:"
cat .gitmodules-shas

echo ""
echo "⚠ Don't forget to commit this file:"
echo "   git add .gitmodules-shas"
echo "   git commit -m 'Update submodule SHAs'"
