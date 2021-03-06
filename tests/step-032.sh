#!/bin/sh
# Test:
#   Direct template execution: choose to ignore the update

mkdir -p ~/.githooks/release && cp /var/lib/githooks/*.sh ~/.githooks/release || exit 1
mkdir -p /tmp/test32 && cd /tmp/test32 || exit 1
git init || exit 1

git config --global githooks.autoupdate.enabled true || exit 1

OUTPUT=$(
    HOOK_NAME=post-commit HOOK_FOLDER=$(pwd)/.git/hooks ACCEPT_CHANGES=A EXECUTE_UPDATE=N \
        sh ~/.githooks/release/base-template-wrapper.sh 2>&1
)

if ! cd ~/.githooks/release && git rev-parse HEAD; then
    echo "! Release clone was not updated, but it should have!"
    exit 1
fi

LAST_UPDATE=$(git config --global --get githooks.autoupdate.lastrun)
if [ -z "$LAST_UPDATE" ]; then
    echo "! Update check was expected to start"
    exit 1
fi

if ! echo "$OUTPUT" | grep -q "If you would like to disable auto-updates"; then
    echo "! Expected update output not found"
    echo "$OUTPUT"
    exit 1
fi
