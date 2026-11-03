# HarpreetLinux

A custom Debian-based Linux distro built automatically with GitHub Actions.

## Quick start: get the ISO

1. Open the repo on GitHub, then the **Actions** tab.
2. Choose **Build live ISO**, click **Run workflow**.
3. Pick a profile: `desktop` (XFCE + security tools) or `minimal` (command line only).
4. Wait about 30-60 minutes. The job builds the ISO, then boots it in QEMU to check it reaches a login prompt.
5. Open the finished run, scroll to **Artifacts**, download `live-iso` (contains the `.iso`, `SHA256SUMS`, and `boot-test.log`).
6. Test in VirtualBox/VMware, or write to USB with Rufus / balenaEtcher / `dd`.

Live login: user `user`, password `live` (from `live-config`).

## Files

- `distro.conf`: name, Debian release (`trixie`), mirror, package lists
- `scripts/build_iso.sh`: builds the live ISO (`PROFILE=minimal|desktop`)
- `scripts/test_iso.sh`: boots the ISO in QEMU and checks for a login prompt
- `scripts/build_rootfs.sh`: builds only a squashfs root filesystem
- `overlay/`: files copied into the image (hostname, login banner)
- `.github/workflows/`: the two workflows (both run by hand)

## Branding

- Logo and wallpaper: `overlay/usr/share/pixmaps/harpreetlinux-logo.png`, `overlay/usr/share/backgrounds/harpreetlinux/wallpaper.png`
- GRUB theme: `branding/grub/` (copied into the ISO by `scripts/build_iso.sh`)
- Boot splash: `overlay/usr/share/plymouth/themes/harpreetlinux/` (turn off with `BOOT_SPLASH="no"` in `distro.conf`)
- Login screen: `overlay/etc/lightdm/lightdm-gtk-greeter.conf`; system name: `overlay/etc/os-release`

## Tool groups

After install, run **HarpreetLinux Setup** from the menu. Groups are plain lists in `overlay/usr/share/harpreetlinux/groups/*.list` (first line is the description, then one package per line). Add a new file there to add a new group.

## Customizing

- Add packages in `distro.conf` (`DESKTOP_PACKAGES`, or a group such as `NET_TOOLS` and `RECOVERY_TOOLS`, which feed `TOOLS_PACKAGES`).
- Add or change files by placing them under `overlay/` (for example `overlay/etc/motd`).
- Do not use the names "Debian" or "Ubuntu" in the distro name or branding.

## Roadmap

- Stage 1: root filesystem and checksum (done)
- Stage 2: bootable live ISO with GRUB (done)
- Stage 3: desktop profile, networking, automatic QEMU boot test (added, not yet run on GitHub)
- Stage 4: GitHub Release with ISO and checksums from a version tag
- Later: installer (Calamares), custom branding and wallpapers, own APT repo

## Limitations

- No installer yet: this is a live ISO only.
- Not yet verified on real hardware. Secure Boot is not supported (GRUB is unsigned).
- Security tools are for learning and authorized testing only.

## License

MIT, see `LICENSE`. Packages from Debian keep their own licenses.
