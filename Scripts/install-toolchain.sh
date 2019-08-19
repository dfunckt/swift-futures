#!/usr/bin/env sh

set -e

TOOLCHAIN_URL="$1"

if test -z "$TOOLCHAIN_URL"; then
  echo "ERROR: no toolchain URL specified"
  exit 1
fi

curl -Ss https://swift.org/keys/all-keys.asc | gpg --import -
curl -L "${TOOLCHAIN_URL}" -o toolchain.tar.gz
curl -L "${TOOLCHAIN_URL}.sig" -o toolchain.tar.gz.sig

gpg --verify toolchain.tar.gz.sig

tar -xz --strip-components=1 -f toolchain.tar.gz

rm toolchain.tar.gz toolchain.tar.gz.sig
./usr/bin/swift --version
