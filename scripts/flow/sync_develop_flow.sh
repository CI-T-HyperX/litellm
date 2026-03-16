#!/usr/bin/env bash
set -euo pipefail

BRANCH="develop-flow"

echo "==> Fetching origin..."
git fetch origin

echo ""
echo "==> Switching to branch: $BRANCH..."
git checkout "$BRANCH"

echo ""
echo "==> Checking for uncommitted changes (new/modified files)..."
UNCOMMITTED=$(git status --porcelain)
if [ -n "$UNCOMMITTED" ]; then
    echo "WARNING: The following uncommitted changes will be lost after reset:"
    git status --short
    echo ""
    read -r -p "Continue with hard reset? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
else
    echo "No uncommitted changes found."
fi

echo ""
echo "==> Resetting to origin/$BRANCH..."
git reset --hard "origin/$BRANCH"

echo ""
echo "==> Verifying sync with remote..."
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse "origin/$BRANCH")

if [ "$LOCAL" = "$REMOTE" ]; then
    echo "OK: Local branch is in sync with origin/$BRANCH"
    echo "    Commit: $LOCAL"
else
    echo "MISMATCH: Local and remote are out of sync!"
    echo "    Local:  $LOCAL"
    echo "    Remote: $REMOTE"
    exit 1
fi
