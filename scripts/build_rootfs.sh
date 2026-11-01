#!/usr/bin/env bash
# Build a minimal root filesystem from the Debian mirror in distro.conf,
# apply the overlay/ files, and pack the result into a squashfs image.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../distro.conf
source "$ROOT/distro.conf"

WORK="$ROOT/build"
ROOTFS="$WORK/rootfs"
OUT="$ROOT/out"

echo "Building ${NAME} from ${SUITE} via ${MIRROR}"

sudo rm -rf "$WORK" "$OUT"
mkdir -p "$WORK" "$OUT"

sudo debootstrap \
    --variant=minbase \
    --include="$PACKAGES" \
    "$SUITE" "$ROOTFS" "$MIRROR"

# Copy our own files (hostname, banners) over the base system.
sudo cp -a "$ROOT/overlay/." "$ROOTFS/"

# Remove the package cache so the image stays small.
sudo chroot "$ROOTFS" /bin/sh -c 'apt-get clean && rm -rf /var/lib/apt/lists/*'

IMAGE="$OUT/${NAME_LOWER}-rootfs.squashfs"
sudo mksquashfs "$ROOTFS" "$IMAGE" -comp xz -noappend

(cd "$OUT" && sha256sum "$(basename "$IMAGE")" > SHA256SUMS)

echo "Done: $IMAGE"
ls -lh "$OUT"
