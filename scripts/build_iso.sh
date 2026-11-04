#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/distro.conf"

PROFILE="${PROFILE:-minimal}"
FLAVOR="${FLAVOR:-xfce}"
EDITION="${EDITION:-none}"
[[ "$EDITION" == none || "$EDITION" == security ]] || { echo "EDITION must be none or security" >&2; exit 2; }
case "$FLAVOR" in xfce|lxqt|mate|gnome|kde) ;; *) echo "FLAVOR must be xfce, lxqt, mate, gnome or kde" >&2; exit 2 ;; esac
[[ "$PROFILE" == minimal || "$PROFILE" == desktop ]] || { echo 'PROFILE must be minimal or desktop' >&2; exit 2; }

WORK="$ROOT/build-iso"
ROOTFS="$WORK/rootfs"
ISO_DIR="$WORK/iso"
OUT="$ROOT/out"
CACHE_DIR="$ROOT/cache"
CACHE_TAR="$CACHE_DIR/rootfs-${PROFILE}-${FLAVOR}-${EDITION}.tar.zst"

mkdir -p "$CACHE_DIR"

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
mkdir -p "$WORK" "$ISO_DIR/live" "$ISO_DIR/boot/grub" "$OUT"

# Builds the base system (bootstrap, kernel, live-boot, packages).
# This is the slow part, so its result is saved to CACHE_TAR for later runs.
build_base() {
  echo "Building base system from scratch (this is the slow part)"
  sudo debootstrap --arch=amd64 --variant=minbase --components=main,non-free-firmware \
    --keyring=/usr/share/keyrings/debian-archive-keyring.gpg \
    "$SUITE" "$ROOTFS" "$MIRROR"

  sudo mkdir -p "$ROOTFS/etc/apt/sources.list.d"
  printf 'deb %s %s main non-free-firmware\n' "$MIRROR" "$SUITE" | sudo tee "$ROOTFS/etc/apt/sources.list" >/dev/null
  sudo cp -L /etc/resolv.conf "$ROOTFS/etc/resolv.conf"

  sudo mount -t proc proc "$ROOTFS/proc"
  sudo mount -t sysfs sysfs "$ROOTFS/sys"
  sudo mount --rbind /dev "$ROOTFS/dev"
  sudo mkdir -p "$ROOTFS/dev/pts"

  # Stop services from starting inside the chroot during package configuration.
  printf '#!/bin/sh\nexit 101\n' | sudo tee "$ROOTFS/usr/sbin/policy-rc.d" >/dev/null
  sudo chmod 755 "$ROOTFS/usr/sbin/policy-rc.d"

  sudo chroot "$ROOTFS" /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get update

  case "$FLAVOR" in
    xfce) DE_LIST="$DE_XFCE" ;;
    lxqt) DE_LIST="$DE_LXQT" ;;
    mate) DE_LIST="$DE_MATE" ;;
    gnome) DE_LIST="$DE_GNOME" ;;
    kde) DE_LIST="$DE_KDE" ;;
  esac
  case "$FLAVOR" in
    xfce) GUI_LIST="$GUI_XFCE" ;;
    lxqt) GUI_LIST="$GUI_LXQT" ;;
    mate) GUI_LIST="$GUI_MATE" ;;
    gnome) GUI_LIST="$GUI_GNOME" ;;
    kde) GUI_LIST="$GUI_KDE" ;;
  esac
  PACKAGES_TO_INSTALL="${PACKAGES},${ISO_PACKAGES},${COMMON_GUI},${DE_LIST},${TOOLS_PACKAGES},${GUI_LIST}"
  if [[ "$PROFILE" == desktop ]]; then PACKAGES_TO_INSTALL+=",${DESKTOP_PACKAGES}"; fi
  IFS=',' read -r -a pkg_array <<< "$PACKAGES_TO_INSTALL"
  pkg_array+=(initramfs-tools dbus systemd-sysv)

  sudo chroot "$ROOTFS" /usr/bin/env DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends "${pkg_array[@]}"
  if [[ "$EDITION" == security ]]; then
    echo "Installing Security Edition packages (missing ones are skipped)"
    IFS=',' read -r -a sec_array <<< "$SECURITY_EDITION"
    sec_ok=(); sec_skip=()
    for p in "${sec_array[@]}"; do
      if sudo chroot "$ROOTFS" apt-cache show "$p" >/dev/null 2>&1; then sec_ok+=("$p"); else sec_skip+=("$p"); fi
    done
    if ! sudo chroot "$ROOTFS" /usr/bin/env DEBIAN_FRONTEND=noninteractive \
         apt-get install -y --no-install-recommends "${sec_ok[@]}"; then
      echo "Bulk install failed; installing security packages one by one"
      for p in "${sec_ok[@]}"; do
        sudo chroot "$ROOTFS" /usr/bin/env DEBIAN_FRONTEND=noninteractive \
          apt-get install -y --no-install-recommends "$p" || sec_skip+=("$p")
      done
    fi
    printf '%s\n' "${sec_skip[@]}" | sudo tee "$ROOTFS/usr/share/harpreetlinux-security-skipped.txt" >/dev/null
    echo "Skipped (not in Debian or failed): ${sec_skip[*]}"
  fi
  sudo chroot "$ROOTFS" update-initramfs -u -k all
  sudo chroot "$ROOTFS" dpkg-query -W live-boot-initramfs-tools
  # Fail the build if a required Wi-Fi or network package is missing.
  sudo chroot "$ROOTFS" dpkg-query -W network-manager wpasupplicant iputils-ping firmware-realtek
  sudo chroot "$ROOTFS" dpkg-query -W lightdm sudo udisks2 network-manager wpasupplicant
  sudo chroot "$ROOTFS" dpkg-query -W udisks2 gvfs papirus-icon-theme arc-theme
  sudo chroot "$ROOTFS" dpkg-query -W calamares plank zenity plymouth timeshift cryptsetup cron ufw unattended-upgrades libnotify-bin pciutils usbutils
  sudo chroot "$ROOTFS" dpkg-query -W timeshift tlp zsh fzf ripgrep bat fd-find jq tealdeer ffmpeg
  sudo chroot "$ROOTFS" dpkg-query -W gnome-software gnome-software-plugin-flatpak packagekit
  # Fail the build if any of the extra tools from distro.conf is missing.
  IFS=',' read -r -a tool_array <<< "$TOOLS_PACKAGES"
  sudo chroot "$ROOTFS" dpkg-query -W "${tool_array[@]}"
  IFS=',' read -r -a gui_array <<< "$GUI_LIST"
  sudo chroot "$ROOTFS" dpkg-query -W "${gui_array[@]}"
  sudo rm -f "$ROOTFS/usr/sbin/policy-rc.d"
  sudo chroot "$ROOTFS" /bin/sh -c 'apt-get clean; rm -rf /var/lib/apt/lists/*'

  cleanup
}

if [[ -f "$CACHE_TAR" ]]; then
  echo "Restoring base system from cache: $CACHE_TAR"
  sudo mkdir -p "$ROOTFS"
  sudo tar --zstd --xattrs --xattrs-include='*' -xpf "$CACHE_TAR" -C "$ROOTFS"
else
  echo "No cache found. Building base system."
  build_base
  # Save the finished base for next time. Mounts are already removed here.
  sudo tar --zstd --xattrs --xattrs-include='*' --exclude='./proc/*' --exclude='./sys/*' --exclude='./dev/*' \
    -cpf "$CACHE_TAR" -C "$ROOTFS" .
  echo "Saved base system cache to $CACHE_TAR"
fi

# Settings that change often are applied on every run, after the cached base.
if [[ -d "$ROOT/overlay" ]]; then
  # /etc/os-release is a symlink to Debian's file; replace it with ours.
  [[ -f "$ROOT/overlay/etc/os-release" ]] && sudo rm -f "$ROOTFS/etc/os-release"
  sudo cp -a "$ROOT/overlay/." "$ROOTFS/"
fi
sudo chmod 755 "$ROOTFS/usr/local/bin/harpreetlinux-setup"
sudo chmod 755 "$ROOTFS/usr/local/bin/harpreetlinux-firstboot"
sudo chmod 755 "$ROOTFS/usr/local/bin/harpreetlinux-welcome"
sudo chmod 755 "$ROOTFS/usr/local/bin/harpreetlinux-language"
for t in askpass backup backup-enable snapshot-apt firewall updates updates-config updates-check drivers drivers-install drivers-check cleanup sysinfo cockpit toolbox secaudit; do
  sudo chmod 755 "$ROOTFS/usr/local/bin/harpreetlinux-$t"
done

# Disk encryption choice in the installer (partition.conf comes from overlay/etc/calamares/modules).
if [[ "${ENABLE_DISK_ENCRYPTION:-yes}" != yes && -f "$ROOTFS/etc/calamares/modules/partition.conf" ]]; then
  sudo sed -i 's/^enableLuksAutomatedPartitioning:.*/enableLuksAutomatedPartitioning: false/' \
    "$ROOTFS/etc/calamares/modules/partition.conf"
fi

# Locales: generate English and Punjabi (list is in overlay/etc/locale.gen).
if [[ -x "$ROOTFS/usr/sbin/locale-gen" ]]; then
  sudo chroot "$ROOTFS" locale-gen
  sudo chroot "$ROOTFS" update-locale LANG=en_US.UTF-8
fi

# Firewall: ufw is switched on by overlay/etc/ufw/ufw.conf; make sure its service starts at boot.
sudo chroot "$ROOTFS" systemctl enable ufw.service || echo "NOTE: could not enable ufw.service" >&2

# Fedora-style defaults: out-of-memory guard (zram swap is set up by overlay/etc/systemd/zram-generator.conf).
sudo chroot "$ROOTFS" systemctl enable earlyoom.service || echo "NOTE: could not enable earlyoom.service" >&2

# Calamares branding: copy the Debian branding folder once, then rename it to HarpreetLinux.
# Any HarpreetLinux branding already supplied in overlay/ is kept as it is.
CAL_BRAND="$ROOTFS/etc/calamares/branding"
if [[ -d "$CAL_BRAND/debian" && ! -d "$CAL_BRAND/harpreetlinux" ]]; then
  sudo cp -a "$CAL_BRAND/debian" "$CAL_BRAND/harpreetlinux"
fi
if [[ -f "$CAL_BRAND/harpreetlinux/branding.desc" ]]; then
  sudo sed -i -e 's/Debian/HarpreetLinux/g' -e 's/debian/harpreetlinux/g' "$CAL_BRAND/harpreetlinux/branding.desc"
fi
# Use the HarpreetLinux logo in the installer (only changes keys that exist).
if [[ -f "$CAL_BRAND/harpreetlinux/branding.desc" && -f "$ROOTFS/usr/share/pixmaps/harpreetlinux-logo.png" ]]; then
  sudo cp "$ROOTFS/usr/share/pixmaps/harpreetlinux-logo.png" "$CAL_BRAND/harpreetlinux/harpreetlinux-logo.png"
  sudo sed -i -E 's/^([[:space:]]*(productLogo|productIcon):[[:space:]]*).*/\1"harpreetlinux-logo.png"/' \
    "$CAL_BRAND/harpreetlinux/branding.desc"
fi
if [[ -f "$ROOTFS/etc/calamares/settings.conf" ]]; then
  sudo sed -i -E 's/^([[:space:]]*branding:[[:space:]]*).*/\1harpreetlinux/' "$ROOTFS/etc/calamares/settings.conf"
  grep -n "branding:" "$ROOTFS/etc/calamares/settings.conf" || true
fi
# Encrypted installs: add the key-file step (so the password is asked once, not twice),
# only if this Calamares has the module and the sequence has an "initramfs" step.
CAL_SET="$ROOTFS/etc/calamares/settings.conf"
if [[ "${ENABLE_DISK_ENCRYPTION:-yes}" == yes && -f "$CAL_SET" ]] \
   && sudo find "$ROOTFS/usr/lib" -type d -name luksbootkeyfile 2>/dev/null | grep -q . \
   && ! grep -q 'luksbootkeyfile' "$CAL_SET"; then
  sudo sed -i -E '0,/^([[:space:]]*)-[[:space:]]*initramfs[[:space:]]*$/s//\1- luksbootkeyfile\n\1- initramfs/' "$CAL_SET"
  grep -n -B1 -A1 'luksbootkeyfile' "$CAL_SET" || echo "NOTE: luksbootkeyfile not added (no 'initramfs' step found)"
fi
case "$FLAVOR" in
  xfce) SESSION=xfce ;;
  lxqt) SESSION=lxqt ;;
  mate) SESSION=mate ;;
  gnome) SESSION=gnome ;;
  kde) SESSION=plasmax11 ;;
esac
sudo mkdir -p "$ROOTFS/etc/lightdm/lightdm.conf.d"
printf "[Seat:*]\nautologin-user=user\nautologin-user-timeout=0\nuser-session=%s\n" "$SESSION" | sudo tee "$ROOTFS/etc/lightdm/lightdm.conf.d/50-autologin.conf" >/dev/null

if ! sudo chroot "$ROOTFS" id user >/dev/null 2>&1; then
  sudo chroot "$ROOTFS" useradd -m -s /bin/bash -G sudo user
fi
printf 'user:live\n' | sudo chroot "$ROOTFS" chpasswd

# Boot splash: set our Plymouth theme and rebuild the initramfs (needs /proc, /sys, /dev).
SPLASH=""
if [[ "${BOOT_SPLASH:-yes}" == yes && -x "$ROOTFS/usr/sbin/plymouth-set-default-theme" ]]; then
  sudo mount -t proc proc "$ROOTFS/proc"
  sudo mount -t sysfs sysfs "$ROOTFS/sys"
  sudo mount --rbind /dev "$ROOTFS/dev"
  if sudo chroot "$ROOTFS" plymouth-set-default-theme harpreetlinux \
     && sudo chroot "$ROOTFS" update-initramfs -u -k all; then
    SPLASH=" splash"
  else
    echo "WARNING: boot splash setup failed; building without it" >&2
  fi
  cleanup
fi

KERNEL="$(find "$ROOTFS/boot" -maxdepth 1 -name 'vmlinuz-*' -printf '%f\n' | sort -V | tail -n 1)"
INITRD="$(find "$ROOTFS/boot" -maxdepth 1 -name 'initrd.img-*' -printf '%f\n' | sort -V | tail -n 1)"
[[ -n "$KERNEL" && -n "$INITRD" ]] || { echo 'Kernel or initrd missing' >&2; exit 1; }

sudo cp "$ROOTFS/boot/$KERNEL" "$ISO_DIR/live/vmlinuz"
sudo cp "$ROOTFS/boot/$INITRD" "$ISO_DIR/live/initrd.img"

cleanup

# Never pack mounted /proc, /sys, /dev or /run into the squashfs.
sudo mksquashfs "$ROOTFS" "$ISO_DIR/live/filesystem.squashfs" -comp zstd -Xcompression-level 15 -noappend \
  -wildcards -e 'dev/*' 'proc/*' 'sys/*' 'run/*'

# GRUB theme: font, background and menu style from branding/grub.
GRUB_THEME_DIR="$ISO_DIR/boot/grub/themes/harpreetlinux"
mkdir -p "$GRUB_THEME_DIR" "$ISO_DIR/boot/grub/fonts"
cp "$ROOT"/branding/grub/* "$GRUB_THEME_DIR/"
for f in /usr/share/grub/unicode.pf2 /usr/share/grub2/unicode.pf2; do
  [[ -f "$f" ]] && { cp "$f" "$ISO_DIR/boot/grub/fonts/unicode.pf2"; break; }
done

cat > "$ISO_DIR/boot/grub/grub.cfg" <<CFG
set timeout=5
set default=0
terminal_input console
terminal_output console
if loadfont /boot/grub/fonts/unicode.pf2 ; then
  insmod all_video
  insmod gfxterm
  insmod png
  set gfxmode=auto
  terminal_output gfxterm
  set theme=/boot/grub/themes/harpreetlinux/theme.txt
fi
menuentry "${NAME} (live)" --class harpreetlinux {
    linux /live/vmlinuz boot=live components quiet${SPLASH} console=tty0 console=ttyS0,115200n8
    initrd /live/initrd.img
}
menuentry "${NAME} (live, Punjabi)" --class harpreetlinux {
    linux /live/vmlinuz boot=live components quiet${SPLASH} locales=pa_IN.UTF-8 keyboard-layouts=us,in keyboard-variants=,guru keyboard-options=grp:alt_shift_toggle console=tty0 console=ttyS0,115200n8
    initrd /live/initrd.img
}
menuentry "${NAME} (live, safe graphics)" --class harpreetlinux {
    linux /live/vmlinuz boot=live components nomodeset console=tty0 console=ttyS0,115200n8
    initrd /live/initrd.img
}
CFG

# The name must match what scripts/test_iso.sh looks for.
ISO="$OUT/${NAME_LOWER}-live.iso"
grub-mkrescue -o "$ISO" "$ISO_DIR" -volid "${NAME_LOWER^^}"
(cd "$OUT" && sha256sum "$(basename "$ISO")" > SHA256SUMS)

ls -lh "$OUT"
echo "SUCCESS: $ISO"
