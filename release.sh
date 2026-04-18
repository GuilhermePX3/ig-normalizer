#!/usr/bin/env bash
# release.sh — Bump version, commit, tag and push to trigger GitHub Actions build
# Usage:
#   ./release.sh 1.0.1
#   ./release.sh 1.1.0 "Adds support for Greek characters"

set -euo pipefail

VERSION="${1:-}"
MESSAGE="${2:-Release v${VERSION}}"

if [[ -z "$VERSION" ]]; then
    echo "Usage: ./release.sh <version> [\"message\"]"
    echo "  e.g: ./release.sh 1.0.1"
    echo "  e.g: ./release.sh 1.1.0 \"Adds Greek character support\""
    exit 1
fi

# Validate semver-ish format
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "ERROR: Version must be in format X.Y.Z (e.g. 1.0.1)"
    exit 1
fi

TAG="v${VERSION}"

echo ""
echo "========================================"
echo "  Releasing ig-normalizer ${TAG}"
echo "========================================"

# --- Update version in pyproject.toml ---
echo ""
echo "[1/4] Updating version in pyproject.toml..."
sed -i "s/^version = \".*\"/version = \"${VERSION}\"/" pyproject.toml

# --- Update version in __init__.py ---
echo "[2/4] Updating version in src/ig_normalizer/__init__.py..."
sed -i "s/__version__ = \".*\"/__version__ = \"${VERSION}\"/" src/ig_normalizer/__init__.py

# --- Update version in cli.py ---
echo "[3/4] Updating version in src/ig_normalizer/cli.py..."
sed -i "s/version=\"ig-normalizer .*/version=\"ig-normalizer ${VERSION}\",/" src/ig_normalizer/cli.py

# --- Update version in .iss ---
echo "[4/4] Updating version in installer/ig-normalizer.iss..."
sed -i "s/#define MyAppVersion.*/#define MyAppVersion   \"${VERSION}\"/" installer/ig-normalizer.iss

# --- Update version in ig-normalizer.spec (OutputBaseFilename comment) ---
# (spec uses the name literally so no version string to update there)

echo ""
echo "Files updated. Committing..."
git add pyproject.toml src/ig_normalizer/__init__.py src/ig_normalizer/cli.py installer/ig-normalizer.iss
git commit -m "chore: bump version to ${VERSION}"

echo "Creating tag ${TAG}..."
git tag -a "${TAG}" -m "${MESSAGE}"

echo "Pushing commit + tag to origin..."
git push origin master
git push origin "${TAG}"

echo ""
echo "========================================"
echo "  Done! GitHub Actions will now build:"
echo "  ig-normalizer-setup-${VERSION}.exe"
echo ""
echo "  Track progress at:"
echo "  https://github.com/GuilhermePX3/ig-normalizer/actions"
echo ""
echo "  Release page (after build ~5min):"
echo "  https://github.com/GuilhermePX3/ig-normalizer/releases/tag/${TAG}"
echo "========================================"
