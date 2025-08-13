#!/usr/bin/env bash
set -euo pipefail

# Requires: npm, nix-prefetch-url
# Usage: ./update-gemini-cli.sh [version]
# If version is omitted, it fetches the latest from npm.

FLAKE="./flake.nix"

get_latest() {
  npm view @google/gemini-cli version
}

VERSION="${1:-$(get_latest)}"
TARBALL_URL="https://registry.npmjs.org/@google/gemini-cli/-/gemini-cli-${VERSION}.tgz"

echo ">> Prefetching ${TARBALL_URL} ..."
# --unpack to hash the normalized contents (safer for npm tarballs)
SHA=$(nix-prefetch-url --type sha256 --unpack "${TARBALL_URL}")
if [[ -z "${SHA}" ]]; then
  echo "Failed to prefetch tarball"; exit 1
fi
# Convert to SRI form
SRI=$(nix hash to-sri --type sha256 "${SHA}")
echo ">> Version: ${VERSION}"
echo ">> SHA256: ${SHA}"
echo ">> SRI:    ${SRI}"

# Update flake.nix
tmp="$(mktemp)"
awk -v ver="${VERSION}" -v sri="${SRI}" '
  /geminiVersion =/ { sub(/".*"/, """ ver """) }
  /sha256 =/ { sub(/"sha256-.*"/, """ sri """) }
  { print }
' "${FLAKE}" > "${tmp}"
mv "${tmp}" "${FLAKE}"

echo ">> Updated ${FLAKE}"
git diff -- "${FLAKE}" || true