# HarpreetLinux build fixes

- ISO bootstrap installs a minimal Debian Trixie base first; kernel and service packages are installed later inside a protected chroot.
- Debian archive keyring is explicitly installed in both GitHub workflows.
- Recursive /dev bind mounts are unmounted before squashfs creation.
- ISO boot test only passes on a login prompt, not a `live-config:` progress message.
- ISO artifact upload is limited to successful build-and-test runs; diagnostics upload on failure.
- Original configuration, overlay and project structure are retained.

## Validation
Static Bash syntax and YAML parsing are checked. A full Debian bootstrap, GRUB ISO build, and QEMU boot have not been executed in this environment.

## Running
GitHub Actions > Build live ISO > Run workflow > minimal (then desktop).
On failure, download `build-diagnostics` from the workflow run.
