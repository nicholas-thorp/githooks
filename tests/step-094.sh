#!/bin/sh
# Test:
#   Cli tool: run an installation

mkdir -p /tmp/test094/a /tmp/test094/b /tmp/test094/c &&
    cd /tmp/test094/a && git init &&
    cd /tmp/test094/b && git init ||
    exit 1

if ! sh /var/lib/githooks/cli.sh install; then
    echo "! Failed to run the installation"
    exit 1
fi

if ! grep 'rycus86/githooks' .git/hooks/pre-commit; then
    echo "! Installation was unsuccessful"
    exit 1
fi

if grep 'rycus86/githooks' /tmp/test094/a/.git/hooks/pre-commit; then
    echo "! Unexpected non-single installation"
    exit 1
fi

git config --global githooks.previousSearchDir /tmp

if ! git hooks install --global; then
    echo "! Failed to run the global installation"
    exit 1
fi

if ! grep 'rycus86/githooks' /tmp/test094/a/.git/hooks/pre-commit; then
    echo "! Global installation was unsuccessful"
    exit 1
fi

if (cd /tmp/test094/c && git hooks install); then
    echo "! Install expected to fail outside a repository"
    exit 1
fi

# Revert to trigger an update
if ! (cd ~/.githooks/release && git status && git reset --hard HEAD^); then
    echo "! Could not reset master to trigger update."
    exit 1
fi

# Set deprecated single install flag
git config --local githooks.single.install "Y"
CURRENT="$(cd ~/.githooks/release && git rev-parse HEAD)"
OUT=$(git hooks install 2>&1)
# shellcheck disable=SC2181
if [ $? -eq 0 ] || ! echo "$OUT" | grep -iq "DEPRECATION WARNING: Single install"; then
    echo "! Expected installation to fail because of single install flag: $OUT"
    exit 1
fi
AFTER="$(cd ~/.githooks/release && git rev-parse HEAD)"
if [ "$CURRENT" != "$AFTER" ]; then
    echo "! Release clone was updated, but it should not have!"
    exit 1
fi

# Unset deprecated single install and install again.
git config --unset githooks.single.install
CURRENT="$(cd ~/.githooks/release && git rev-parse HEAD)"
if ! git hooks install; then
    echo "! Expected installation to succeed"
    exit 1
fi
AFTER="$(cd ~/.githooks/release && git rev-parse HEAD)"

if [ "$CURRENT" = "$AFTER" ]; then
    echo "! Release clone was not updated, but it should have!"
    exit 1
fi

# Reset to trigger a global update
if ! (cd ~/.githooks/release && git status && git reset --hard HEAD^); then
    echo "! Could not reset master to trigger update."
    exit 1
fi

CURRENT="$(cd ~/.githooks/release && git rev-parse HEAD)"
if ! git hooks install --global; then
    echo "! Expected global installation to succeed"
    exit 1
fi
AFTER="$(cd ~/.githooks/release && git rev-parse HEAD)"
if [ "$CURRENT" = "$AFTER" ]; then
    echo "! Release clone was not updated, but it should have!"
    exit 1
fi
