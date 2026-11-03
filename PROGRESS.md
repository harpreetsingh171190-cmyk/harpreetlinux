# HarpreetLinux progress log

## Build status
- Iteration: Mac-style look + Calamares + post-install setup (flavour: xfce)
- Build: successful (GitHub Actions, Build live ISO)

## Added in this iteration
- Calamares installer (install to disk, dual boot).
- Plank dock (Mac-style) starting with the session.
- Mac-style window buttons (close, minimise, maximise on the left) in XFCE.
- "HarpreetLinux Setup" menu that installs tool groups from the internet.
- Tool groups: development, security-ethical, forensics, wireless, reverse-engineering, privacy.

## Still to test on real hardware
- Dock and window buttons appear after login.
- Setup menu installs a group; check for SKIPPED packages.
- Calamares installs to disk and the installed system boots.
- Wi-Fi connects (NetworkManager applet in the tray).

## Known limits
- No .NET SDK, Xcode or macOS tools (not available on Linux or not in Debian).
- Packages missing from Debian are skipped and listed at the end of setup.
- The installer may still show Debian branding (calamares-settings-debian).

## Next (feedback driven)
- Fix anything found in the test above.
- Rebrand the installer (HarpreetLinux name and logo).
- Add more tool groups as requested.
