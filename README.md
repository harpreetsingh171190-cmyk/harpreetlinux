# HarpreetLinux

A custom Linux system built automatically with GitHub Actions. This first stage builds a minimal Debian-based root filesystem, adds custom files, and packages the result as a compressed image.

## What the build produces

Each run creates two files, available as a workflow artifact:

- `harpreetlinux-rootfs.squashfs`: the compressed root filesystem
- `SHA256SUMS`: checksum for verifying the image

## How it works

1. `distro.conf` sets the name, Debian release, mirror, and package list.
2. `scripts/build_rootfs.sh` runs `debootstrap` to create a minimal system.
3. The files in `overlay/` (hostname and login banner) are copied into the system.
4. The system is packed into a squashfs image with a checksum.
5. The workflow in `.github/workflows/build-rootfs.yml` runs these steps on GitHub's servers.

To build, open the **Actions** tab and run **Build rootfs** with "Run workflow", or push to `main`.

## Changing the distro

Edit `distro.conf` to change the name or packages. Add files to `overlay/` to change their contents in the image. For example, `overlay/etc/motd` is the login banner.

Do not use the names "Debian" or "Ubuntu" in the distro name or branding. Both projects restrict how their trademarks may be used.

## Building the bootable ISO

The **Build live ISO** workflow runs `scripts/build_iso.sh`. It creates a Debian system with a kernel and live-boot support, then packs it into a bootable ISO with a GRUB menu. Boot the ISO in a virtual machine, or write it to a USB drive. The live user and sudo access come from `live-config`.

## Roadmap

- **Stage 1 (this version):** root filesystem and checksum.
- **Stage 2 (added):** bootable live ISO with a kernel and GRUB boot menu.
- **Stage 3:** automatic boot test in a virtual machine.
- **Stage 4:** GitHub Release with the ISO and checksums created from a version tag.

## Limitations

- The root filesystem from stage 1 has no login account. The live ISO creates a `user` account with sudo.
- The ISO has not been tested in a virtual machine yet. Stage 3 will add an automatic boot test.
- The build needs the Debian mirror to be reachable from GitHub's runners, which is normally the case.

## License

Choose a license before publishing. Packages from Debian keep their own licenses.
