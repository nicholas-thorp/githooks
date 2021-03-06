#!/bin/sh
# Test:
#   Trigger hooks on a bare repo with a push from a local repo.

git config --global githooks.testingTreatFileProtocolAsRemote "true"

if ! sh /var/lib/githooks/install.sh; then
    echo "! Failed to execute the install script"
    exit 1
fi

mkdir -p /tmp/test110/hooks &&
    mkdir -p /tmp/test110/server &&
    mkdir -p /tmp/test110/local || exit 1

# Hooks
cd /tmp/test110/hooks && git init || exit 1
git hooks config set disable || exit 1

# Server
cd /tmp/test110/server && git init --bare || exit 1
# Repo
git clone /tmp/test110/server /tmp/test110/local || exit 1

echo "Setup hooks"
cd /tmp/test110/hooks || exit 1
mkdir -p ".githooks/update"
HOOK=".githooks/update/testhook"
echo "#!/bin/sh" >"$HOOK"
echo "echo 'Update hook run'" >>"$HOOK"
echo "exit 1" >>"$HOOK"
chmod u+x "$HOOK"
git add "$HOOK" || exit 1
git commit -a -m "Hooks" || exit 1

echo "Setup shared hook in server repo"
cd /tmp/test110/server || exit 1
git hooks shared add file:///tmp/test110/hooks || exit 1
echo "Setup shared hook in server repo: set trusted"
git hooks config accept trusted || exit 1
echo "Setup shared hook in server repo: update shared"
git hooks shared update || exit 1

echo "Test hook from push"
cd /tmp/test110/local || exit 1
echo "Test" >Test
git add Test || exit 1
git commit -a -m "First" || exit 1
echo "Push hook to fail"
OUTPUT=$(git push 2>&1)

# shellcheck disable=SC2181
if [ $? -eq 0 ] || ! echo "$OUTPUT" | grep -q "Update hook run"; then
    echo "!! Push should have failed and update hook should have run. Output:"
    echo "$OUTPUT"
    exit 1
fi

echo "Modify hook to succeed"
cd /tmp/test110/hooks || exit 1
sed -i 's/exit 1/exit 0/g' "$HOOK"
git commit -a -m "Make hook succeed"

echo "Update hooks"
cd /tmp/test110/server || exit 1
git hooks shared update || exit 1

echo "Push hook to succeed"
cd /tmp/test110/local || exit 1
OUTPUT=$(git push 2>&1)

# shellcheck disable=SC2181
if [ $? -ne 0 ] || ! echo "$OUTPUT" | grep -q "Update hook run"; then
    echo "!! Push should have succeeded and update hook should have run. Output:"
    echo "$OUTPUT"
    exit 1
fi

exit 0
