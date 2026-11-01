#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/distro.conf"
PROFILE="${PROFILE:-minimal}"
[[ "$PROFILE" == minimal || "$PROFILE" == desktop ]] || { echo 'PROFILE must be minimal or desktop' >&2; exit 2; }
WORK="$ROOT/build-iso"; ROOTFS="$WORK/rootfs"; ISO_DIR="$WORK/iso"; OUT="$ROOT/out"
mkdir -p "$WORK" "$OUT"
cleanup() {
  set +e
  for p in dev sys proc; do
    if mountpoint -q "$ROOTFS/$p"; then sudo umount -R "$ROOTFS/$p"; fi
  done
}
on_error() {
  rc=$?
  echo "ERROR: ISO build failed (exit $rc) at line $1" >&2
  if [[ -f "$ROOTFS/debootstrap/debootstrap.log" ]]; then sudo tail -n 100 "$ROOTFS/debootstrap/debootstrap.log" >&2; fi
  if [[ -f "$ROOTFS/var/log/apt/term.log" ]]; then sudo tail -n 100 "$ROOTFS/var/log/apt/term.log" >&2; fi
  exit "$rc"
}
trap 'on_error "$LINENO"' ERR
trap cleanup EXIT
sudo rm -rf "$WORK" "$OUT"
mkdir -p "$ISO_DIR/live" "$ISO_DIR/boot/grub" "$OUT"
echo "Building $NAME ($SUITE, $PROFILE)"
# Bootstrap ONLY the minimal Debian base; do not configure kernel or services here.
sudo debootstrap --arch=amd64 --variant=minbase --components=main,non-free-firmware \
  --keyring=/usr/share/keyrings/debian-archive-keyring.gpg \
  "$SUITE" "$ROOTFS" "$MIRROR"
# Explicit sources for installing extra packages inside the new filesystem.
sudo mkdir -p "$ROOTFS/etc/apt/sources.list.d"
printf 'deb %s %s main non-free-firmware\n' "$MIRROR" "$SUITE" | sudo tee "$ROOTFS/etc/apt/sources.list" >/dev/null
sudo cp -L /etc/resolv.conf "$ROOTFS/etc/resolv.conf"
sudo mount -t proc proc "$ROOTFS/proc"
sudo mount -t sysfs sysfs "$ROOTFS/sys"
sudo mount --rbind /dev "$ROOTFS/dev"
sudo mkdir -p "$ROOTFS/dev/pts"
# /dev/pts is already included in the recursive /dev bind mount
# Prevent attempts to start services inside chroot.
printf '#!/bin/sh\nexit 101\n' | sudo tee "$ROOTFS/usr/sbin/policy-rc.d" >/dev/null
sudo chmod 755 "$ROOTFS/usr/sbin/policy-rc.d"
sudo chroot "$ROOTFS" /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get update
# distro.conf contains comma-separated package names.
PACKAGES_TO_INSTALL="${PACKAGES},${ISO_PACKAGES}"
if [[ "$PROFILE" == desktop ]]; then PACKAGES_TO_INSTALL+=",${DESKTOP_PACKAGES}"; fi
IFS=',' read -r -a pkg_array <<< "$PACKAGES_TO_INSTALL"
# Ensure login prompt and initramfs implementation are installed.
pkg_array+=(initramfs-tools dbus systemd-sysv)
sudo chroot "$ROOTFS" /usr/bin/env DEBIAN_FRONTEND=noninteractive \
  apt-get install -y --no-install-recommends "${pkg_array[@]}"
sudo chroot "$ROOTFS" update-initramfs -u -k all
# Confirm live-boot hooks are present in the generated initramfs.
sudo chroot "$ROOTFS" dpkg-query -W live-boot-initramfs-tools
sudo rm -f "$ROOTFS/usr/sbin/policy-rc.d"
# Apply user's existing hostname, motd, LightDM configuration etc.
if [[ -d "$ROOT/overlay" ]]; then sudo cp -a "$ROOT/overlay/." "$ROOTFS/"; fi
# Ensure a predictable login even if live-config does not create its default user.
if ! sudo chroot "$ROOTFS" id user >/dev/null 2>&1; then
  sudo chroot "$ROOTFS" useradd -m -s /bin/bash -G sudo user
fi
printf 'user:live\n' | sudo chroot "$ROOTFS" chpasswd
sudo chroot "$ROOTFS" /bin/sh -c 'apt-get clean; rm -rf /var/lib/apt/lists/*'
# Remove host resolver, if copied (live networking should manage DNS).
# Preserve a valid resolver for the live environment; NetworkManager can update it.
# Never pack live mounted /proc /sys /dev into SquashFS.
cleanup
KERNEL="$(find "$ROOTFS/boot" -maxdepth 1 -name 'vmlinuz-*' -printf '%f\n' | sort -V | tail -n 1)"
INITRD="$(find "$ROOTFS/boot" -maxdepth 1 -name 'initrd.img-*' -printf '%f\n' | sort -V | tail -n 1)"
[[ -n "$KERNEL" && -n "$INITRD" ]] || { echo 'Kernel or initrd missing' >&2; exit 1; }
sudo cp "$ROOTFS/boot/$KERNEL" "$ISO_DIR/live/vmlinuz"
sudo cp "$ROOTFS/boot/$INITRD" "$ISO_DIR/live/initrd.img"
sudo mksquashfs "$ROOTFS" "$ISO_DIR/live/filesystem.squashfs" -comp xz -noappend -wildcards -e 'dev/*' 'proc/*' 'sys/*' 'run/*'
cat > "$ISO_DIR/boot/grub/grub.cfg" <<CFG
set timeout=5
set default=0
terminal_input console
terminal_output console
menuentry "${NAME} (live)" {
    linux /live/vmlinuz boot=live components quiet console=tty0 console=ttyS0,115200n8
    initrd /live/initrd.img
}
menuentry "${NAME} (live, safe graphics)" {
    linux /live/vmlinuz boot=live components nomodeset console=tty0 console=ttyS0,115200n8
    initrd /live/initrd.img
}
CFG
ISO="$OUT/${NAME_LOWER}-live.iso"
grub-mkrescue -o "$ISO" "$ISO_DIR" -volid "${NAME_LOWER^^}"
(cd "$OUT" && sha256sum "$(basename "$ISO")" > SHA256SUMS)
ls -lh "$OUT"
echo "SUCCESS: $ISO"
