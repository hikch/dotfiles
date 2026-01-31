#!/bin/bash
set -eu

# Deployment test script
# Run in a sandbox to verify symlinks are created correctly

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SANDBOX=$(mktemp -d)
trap "rm -rf $SANDBOX" EXIT

echo "Testing in sandbox: $SANDBOX"
echo "DOTPATH: $HOME_DIR"
echo ""

# Deploy to sandbox
HOME=$SANDBOX make -C "$HOME_DIR" deploy

# ========== Helper functions ==========
assert_symlink() {
    if [ -L "$SANDBOX/$1" ]; then
        echo "  $1 (symlink)"
    else
        echo "  FAIL: $1 - not a symlink"
        exit 1
    fi
}

assert_not_symlink() {
    if [ -d "$SANDBOX/$1" ] && [ ! -L "$SANDBOX/$1" ]; then
        echo "  $1 (real directory)"
    else
        echo "  FAIL: $1 - should be real directory, not symlink"
        exit 1
    fi
}

assert_not_exists() {
    if [ ! -e "$SANDBOX/$1" ]; then
        echo "  $1 (correctly excluded)"
    else
        echo "  FAIL: $1 - should not exist"
        exit 1
    fi
}

# ========== Test 1: Basic symlinks ==========
echo ""
echo "--- Test 1: Basic symlinks ---"
assert_symlink ".vimrc"
assert_symlink ".gitconfig"
assert_symlink ".bashrc"
assert_symlink "bin"

# ========== Test 2: PARTIAL_LINKS ==========
echo ""
echo "--- Test 2: PARTIAL_LINKS ---"
assert_symlink ".config/fish/config.fish"
assert_symlink ".config/git/ignore"
assert_symlink ".local/share/devbox/global/default"

# ========== Test 3: Parent directories are real ==========
echo ""
echo "--- Test 3: Parent directories are real (not symlinks) ---"
assert_not_symlink ".config"
assert_not_symlink ".local"

# ========== Test 4: AI settings (PARTIAL_LINKS) ==========
echo ""
echo "--- Test 4: AI settings ---"
assert_symlink ".claude/settings.json"
assert_symlink ".claude/CLAUDE.md"
assert_symlink ".gemini/settings.json"
assert_not_symlink ".claude"
assert_not_symlink ".gemini"

# ========== Test 5: Excluded files ==========
echo ""
echo "--- Test 5: Excluded files ---"
assert_not_exists ".git"
assert_not_exists ".gitignore"
assert_not_exists "Makefile"

echo ""
echo "=== All tests passed ==="
