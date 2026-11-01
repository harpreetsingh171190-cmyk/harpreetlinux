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

## Roadmap

- **Stage 1 (this version):** root filesystem and checksum.
- **Stage 2:** bootable ISO with a kernel and GRUB boot menu.
- **Stage 3:** automatic boot test in a virtual machine.
- **Stage 4:** GitHub Release with the ISO and checksums created from a version tag.

## Limitations

- The image has no password set for root, and no user accounts. Stage 2 will add a login user.
- This stage does not produce a bootable disk. It only builds the root filesystem.
- The build needs the Debian mirror to be reachable from GitHub's runners, which is normally the case.

## License

Choose a license before publishing. Packages from Debian keep their own licenses.
