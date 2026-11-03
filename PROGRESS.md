# HarpreetLinux progress log

## Iteration 2: branding and new tool groups
- Logo (H on indigo, saffron crossbar), wallpaper, GRUB theme and background, Plymouth boot splash.
- os-release, /etc/issue, motd and LightDM greeter now say HarpreetLinux.
- Calamares installer uses the HarpreetLinux logo.
- Welcome window at first login (re-open from the menu: "HarpreetLinux Welcome").
- Fixed: the GTK theme "HarpreetLinux" lived in the groups folder, so it never loaded. It is now in /usr/share/themes.
- New tool groups: gaming, multimedia, graphics-design, office, education-science, data-science, electronics-iot, cad-3d-printing, writing-latex.
- Set BOOT_SPLASH="no" in distro.conf to build without the boot splash.

## Added in the first iteration
- Calamares installer (install to disk, dual boot).
- Plank dock (Mac-style) starting with the session.
- Mac-style window buttons (close, minimise, maximise on the left) in XFCE.
- Post-install menu "HarpreetLinux Setup" that installs tool groups from the internet:
  development, security-ethical, forensics, wireless, reverse-engineering, privacy.

## Known limits
- No .NET SDK, Xcode or macOS tools (not available on Linux or not in Debian).
- A few packages may be skipped if Debian does not provide them; the menu reports them.
- Not yet tested in a real boot.

## Next iterations (feedback driven)
- Add groups and fixes as the builds are tested.
