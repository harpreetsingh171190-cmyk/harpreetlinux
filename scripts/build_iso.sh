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

# PROFILE=minimal (command line only) or PROFILE=desktop (XFCE + tools).
PROFILE="${PROFILE:-minimal}"
ALL_PACKAGES="${PACKAGES},${ISO_PACKAGES}"
if [ "$PROFILE" = "desktop" ]; then
    ALL_PACKAGES="${ALL_PACKAGES},${DESKTOP_PACKAGES}"
fi

APT_PACKAGES="$(echo "$ALL_PACKAGES" | tr ',' ' ')"

echo "Building live ISO for ${NAME} (${SUITE}, profile: ${PROFILE})"

sudo rm -rf "$WORK" "$OUT"
mkdir -p "$WORK" "$ISO_DIR/live" "$ISO_DIR/boot/grub" "$OUT"

cleanup() {
    for d in dev/pts dev sys proc; do
        sudo umount -lf "$ROOTFS/$d" 2>/dev/null || true
    done
}
trap cleanup EXIT

# Stage 1: Bootstrap minimal base system.
sudo debootstrap \
    --variant=minbase \
    --components=main,contrib,non-free,non-free-firmware \
    "$SUITE" "$ROOTFS" "$MIRROR"

sudo cp /etc/resolv.conf "$ROOTFS/etc/resolv.conf"

cat <<EOF | sudo tee "$ROOTFS/etc/apt/sources.list" > /dev/null
deb $MIRROR $SUITE main contrib non-free non-free-firmware
EOF

sudo mount -t proc proc "$ROOTFS/proc"
sudo mount -t sysfs sys "$ROOTFS/sys"
sudo mount --bind /dev "$ROOTFS/dev"
sudo mkdir -p "$ROOTFS/dev/pts"
sudo mount --bind /dev/pts "$ROOTFS/dev/pts"

# Block service starts inside chroot during package installation.
sudo tee "$ROOTFS/usr/sbin/policy-rc.d" > /dev/null << 'POLICY'
#!/bin/sh
exit 101
POLICY
sudo chmod +x "$ROOTFS/usr/sbin/policy-rc.d"

# Stage 2: Install kernel, live-boot, and desktop packages via APT.
sudo chroot "$ROOTFS" /bin/sh -c "
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y --no-install-recommends $APT_PACKAGES
    update-initramfs -u -k all
    apt-get clean
    rm -rf /var/lib/apt/lists/*
"

sudo rm -f "$ROOTFS/usr/sbin/policy-rc.d"

# Apply custom overlay files.
sudo cp -a "$ROOT/overlay/." "$ROOTFS/"

# Unmount virtual filesystems BEFORE creating squashfs image.
cleanup

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
    linux /live/vmlinuz boot=live components quiet console=tty0 console=ttyS0,115200
    initrd /live/initrd.img
}

menuentry "${NAME} (live, safe graphics)" {
    linux /live/vmlinuz boot=live components nomodeset
    initrd /live/initrd.img
}
CFG

ISO="$OUT/${NAME_LOWER}-live.iso"
grub-mkrescue -o "$ISO" "$ISO_DIR" -- -volid "${NAME_LOWER^^}"
(cd "$OUT" && sha256sum "$(basename "$ISO")" > SHA256SUMS)

echo "Done: $ISO"
ls -lh "$OUT"
