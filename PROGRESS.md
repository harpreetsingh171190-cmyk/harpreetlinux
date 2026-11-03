# HarpreetLinux progress log

## Added in this iteration
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
## Tested
- Dock, window buttons and setup menu: working (user test, USB boot).
- Tool groups: 12 total, installed from the setup menu.
