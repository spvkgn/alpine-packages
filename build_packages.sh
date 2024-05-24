#!/bin/bash
set -euxo

export PACKAGER="Pavel <spvkgn@users.noreply.github.com>"
export PACKAGER_PRIVKEY="$HOME/$GITHUB_REPOSITORY_OWNER.rsa"
export REPODEST="$GITHUB_WORKSPACE/packages"
export USE_CCACHE=1
export CCACHE_DIR="$GITHUB_WORKSPACE/.ccache"

git config --global --add safe.directory "$GITHUB_WORKSPACE"

echo "$RSA_PRIVATE_KEY" > "$HOME/$GITHUB_REPOSITORY_OWNER.rsa"
echo "$RSA_PUBLIC_KEY" > "$HOME/$GITHUB_REPOSITORY_OWNER.rsa.pub"
cp "$HOME/$GITHUB_REPOSITORY_OWNER.rsa.pub" /etc/apk/keys

mkdir -p "$REPODEST"
# shellcheck disable=SC2016
for dir in $GITHUB_WORKSPACE; do
  find "$dir" -type f -name APKBUILD -exec /bin/bash -c 'cd $(dirname {}); abuild -F checksum; abuild -F -r -D alpine' \;
done
cp "$HOME/$GITHUB_REPOSITORY_OWNER.rsa.pub" "$REPODEST"
tar cvf apk-$BRANCH-$ARCH.tar --transform "s|^\./|alpine/$BRANCH/|" --show-transformed-names -C "$REPODEST"/*/ .

ccache --max-size=50M --show-stats
