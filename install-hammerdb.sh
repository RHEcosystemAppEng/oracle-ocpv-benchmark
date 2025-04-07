#!/bin/bash
set -euo pipefail

VERSION=${1:-4.12}
cd "$(dirname "$0")"

# Install dependencies (only if on RHEL 8)
if grep -q "Red Hat Enterprise Linux release 8" /etc/redhat-release; then
  echo "Detected RHEL 8 - installing dependencies"
  sudo dnf install -y \
    tcl \
    tcl-devel \
    libaio \
    unzip \
    curl
fi

if [[ -d "HammerDB-$VERSION" ]]; then
  echo "HammerDB-$VERSION already exists. Skipping."
  exit 0
fi

if [[ "$VERSION" == "master" ]]; then
  ./install-hammerdb.sh 4.12
  git clone --depth 1 --branch master https://github.com/TPC-Council/HammerDB HammerDB-master
  cp -R HammerDB-4.12/{lib,include,bin,hammerdbcli} HammerDB-master
  echo "HammerDB-master ready."
  exit 0
fi

if [[ "$VERSION" != "4.12" ]]; then
  echo "Unsupported version: $VERSION"
  echo "Supported versions: 4.12, master"
  exit 1
fi

# Use RHEL-optimized HammerDB archive
FILENAME="hammerdb-4.12-rhel8.tar.gz"
SHA1="dda34897da40255e04bbfec3016f22fb"
URL="https://github.com/TPC-Council/HammerDB/releases/download/v4.12/$FILENAME"

if [[ ! -f "$FILENAME" ]]; then
  echo "Downloading HammerDB $VERSION..."
  curl -L -o "$FILENAME.tmp" "$URL"
  mv "$FILENAME.tmp" "$FILENAME"
else
  echo "$FILENAME already downloaded. Skipping."
fi

#ACTUAL_SHA1=$(sha1sum "$FILENAME" | awk '{print $1}')
#if [[ "$ACTUAL_SHA1" != "$SHA1" ]]; then
#  echo "Checksum mismatch:"
#  echo "  Expected: $SHA1"
#  echo "  Actual:   $ACTUAL_SHA1"
#  exit 1
#fi

echo "Extracting $FILENAME..."
tar -xvzf $FILENAME

if [[ ! -d "HammerDB-$VERSION" ]]; then
  echo "Extraction failed or unexpected folder structure."
  exit 1
fi



echo "HammerDB-$VERSION installed."
