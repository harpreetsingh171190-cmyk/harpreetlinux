#!/usr/bin/env bash
# Build a bootable live ISO: Debian rootfs + kernel + live-boot + GRUB.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../distro.conf
source "$ROOT/distro.conf"

WORK="$ROOT/build-iso"
ROOTFS="$WORK/rootfs"
ISO_DIR="$WORK/iso"
OUT="$ROOT/out"

echo "Building live ISO for ${NAME} (${SUITE})"

sudo rm -rf "$WORK" "$OUT"
mkdir -p "$WORK" "$ISO_DIR/live" "$ISO_DIR/boot/grub" "$OUT"

sudo debootstrap \
    --variant=minbase \
    --include="${PACKAGES},${ISO_PACKAGES}" \
    "$SUITE" "$ROOTFS" "$MIRROR"

sudo cp -a "$ROOT/overlay/." "$ROOTFS/"

# The kernel's post-install scripts need /proc, /sys and /dev inside the chroot.
cleanup() {
    for d in dev sys proc; do
        sudo umount -l "$ROOTFS/$d" 2>/dev/null || true
    done
}
trap cleanup EXIT
sudo mount -t proc proc "$ROOTFS/proc"
sudo mount -t sysfs sys "$ROOTFS/sys"
sudo mount --bind /dev "$ROOTFS/dev"

sudo chroot "$ROOTFS" /bin/sh -c 'apt-get clean && rm -rf /var/lib/apt/lists/*'
cleanup
trap - EXIT

# Find the newest kernel and its initramfs.
KERNEL="$(sudo ls "$ROOTFS/boot" | grep '^vmlinuz-' | sort -V | tail -1)"
INITRD="$(sudo ls "$ROOTFS/boot" | grep '^initrd.img-' | sort -V | tail -1)"
if [ -z "$KERNEL" ] || [ -z "$INITRD" ]; then
    echo "ERROR: kernel or initramfs not found in $ROOTFS/boot" >&2
    exit 1
fi
sudo cp "$ROOTFS/boot/$KERNEL" "$ISO_DIR/live/vmlinuz"
sudo cp "$ROOTFS/boot/$INITRD" "$ISO_DIR/live/initrd.img"

# Pack the root filesystem as the live system.
sudo mksquashfs "$ROOTFS" "$ISO_DIR/live/filesystem.squashfs" -comp xz -noappend

cat > "$ISO_DIR/boot/grub/grub.cfg" << CFG
set timeout=5
set default=0

menuentry "${NAME} (live)" {
    linux /live/vmlinuz boot=live quiet
    initrd /live/initrd.img
}

menuentry "${NAME} (live, safe graphics)" {
    linux /live/vmlinuz boot=live nomodeset
    initrd /live/initrd.img
}
CFG

ISO="$OUT/${NAME_LOWER}-live.iso"
grub-mkrescue -o "$ISO" "$ISO_DIR" -volid "${NAME_LOWER^^}"
(cd "$OUT" && sha256sum "$(basename "$ISO")" > SHA256SUMS)

echo "Done: $ISO"
ls -lh "$OUT"
