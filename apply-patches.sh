#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="$(mktemp -d /tmp/vmware-fix.XXXXXX)"
SOURCE_DIR="/usr/lib/vmware/modules/source"

echo "==> Working in $WORK_DIR"

# Extract sources
mkdir -p "$WORK_DIR/vmmon" "$WORK_DIR/vmnet"
tar xf "$SOURCE_DIR/vmmon.tar" -C "$WORK_DIR/vmmon"
tar xf "$SOURCE_DIR/vmnet.tar" -C "$WORK_DIR/vmnet"

# Apply patches
for patch in "$SCRIPT_DIR/patches/"*.patch; do
    echo "==> Applying $(basename "$patch")"
    patch -p1 -d "$WORK_DIR" < "$patch"
done

# Clean any leftover build artifacts before repacking
make -C "$WORK_DIR/vmmon/vmmon-only" clean 2>/dev/null || true
make -C "$WORK_DIR/vmnet/vmnet-only" clean 2>/dev/null || true

# Repack
echo "==> Repacking tarballs"
tar cf "$SOURCE_DIR/vmmon.tar" -C "$WORK_DIR/vmmon" vmmon-only/
tar cf "$SOURCE_DIR/vmnet.tar" -C "$WORK_DIR/vmnet" vmnet-only/

rm -rf "$WORK_DIR"

echo "==> Building and installing modules"
vmware-modconfig --console --install-all

echo "==> Done"
