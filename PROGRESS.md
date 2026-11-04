# HarpreetLinux progress log

## Iteration 10: privacy, kernel hardening, bigger Security Edition
- "HarpreetLinux Anon" (like Anonsurf): runs its own Tor instance and sends all traffic of the computer through it (nftables transparent proxy, Tor DNS). Kill switch: UDP, IPv6 and anything else that cannot go through Tor is blocked; local network stays reachable. Turn on/off, new identity, and a check against check.torproject.org. Nothing is saved across reboots. Installs tor and nftables on first use. It does not guarantee anonymity (the window says so).
- privacy group now also has I2P (i2pd), age, gocryptfs, GnuPG, cryptsetup, mat2, Seahorse, nftables.
- Kernel hardening WITHOUT a custom kernel: overlay/etc/sysctl.d/99-harpreetlinux-hardening.conf, modprobe.d blacklist of rarely used protocols and old file systems, and boot options (slab_nomerge, init_on_alloc, page_alloc.shuffle, randomize_kstack_offset, vsyscall=none) for installed systems through /etc/default/grub.d. "HarpreetLinux Kernel Hardening" window shows what is active and can relax ptrace/perf limits until reboot for debugging.
- A custom-compiled kernel was NOT built (it needs a kernel build and tests on real hardware). The stock Debian kernel already supports monitor mode and injection on most Wi-Fi drivers; "HarpreetLinux Wi-Fi Adapter Test" checks your adapter (monitor mode, then aireplay-ng injection test, adapter put back to normal after).
- Security Edition (EDITION=security) already existed; its package list now also has i2pd, Lynis, rkhunter, fail2ban, masscan, mitmproxy, sslscan, wapiti, crunch, steghide and others. Missing packages are skipped as before (see /usr/share/harpreetlinux-security-skipped.txt).
- VERSION_LABEL is now 0.6. Not tested in a real boot: Anon rules (nftables), Wi-Fi test, grub drop-in.

## Iteration 9: cybersecurity toolkit
- Already there before: security-ethical, wireless, forensics, reverse-engineering, privacy groups.
- New groups: security-defense (Lynis, rkhunter, chkrootkit, ClamAV, fail2ban, AIDE, auditd, Suricata), security-recon (masscan, arp-scan, tshark, mitmproxy, sslscan, ...), security-web-extra (wapiti, dirb, wfuzz, wpscan, Burp Suite), security-passwords (crunch, cewl, medusa, ncrack, hashid, cupp), osint-stego (theHarvester, recon-ng, SpiderFoot, steghide, stegseek).
- New "HarpreetLinux Security Check" window: runs a Lynis audit of this computer (read-only), shows the hardening score, warnings and suggestions.
- Attack-type tools are only in the optional setup menu, never in the ISO, and each list says to use them only with permission. Packages Debian does not have (for example some of wpscan, burpsuite, recon-ng) are skipped by the setup menu.
- VERSION_LABEL is now 0.5. Not tested in a real boot.

## Iteration 8: Fedora Workstation style features
- Compressed RAM swap (zram, half of RAM up to 4 GB, as in Fedora) and earlyoom (stops a runaway program before the system freezes) are on by default. New packages: systemd-zram-generator, earlyoom (distro.conf FEDORA_TOOLS).
- "HarpreetLinux Toolbox" window (like Fedora Toolbx): create or enter a developer container (Fedora, Debian, Ubuntu, Arch) with distrobox and podman. Offers to install them if missing.
- "HarpreetLinux Cockpit" (like Fedora's Cockpit): opens the web admin page for system, storage, network and containers at localhost:9090. Offers to install it if missing.
- New tool groups: toolbox-containers and cockpit.
- Already like Fedora: Flathub added at first login, GNOME Software, firmware updates (fwupd), PipeWire, automatic security updates.
- Not copied from Fedora (not available or too large a change for Debian): SELinux (Debian uses AppArmor), rpm-ostree/Silverblue, Btrfs by default, Wayland GNOME as the default flavour.
- VERSION_LABEL is now 0.4. Not tested in a real boot: zram, earlyoom, distrobox container creation.

## Iteration 7: cleanup, system info, two new tool groups
- New "HarpreetLinux Cleanup" window: clears the apt cache, unused packages, system logs older than 14 days, the trash and the thumbnail cache, then shows how much space was freed.
- New "HarpreetLinux System Info" window: version, kernel, processor, graphics, memory, disk, battery, temperature and uptime.
- New tool groups: web-dev (PHP, Ruby, SQLite, httpie, nginx, Chromium) and productivity (KeePassXC, Zim, CherryTree, Flameshot, CopyQ, Syncthing, rclone). Packages Debian does not provide are skipped by the setup menu.
- Both windows and the new group names are in English and Punjabi (i18n.sh, pa-groups.txt, menu entries).
- VERSION_LABEL is now 0.3; the build script makes the two new tools executable.
- Not tested in a real boot: the cleanup run with sudo, battery and temperature readings on real hardware.

## Iteration 6: driver detection (NVIDIA, Wi-Fi)
- apt sources now also have contrib and non-free (the NVIDIA driver lives in non-free).
- "HarpreetLinux Drivers" window finds an NVIDIA GPU (installs the driver nvidia-detect recommends, plus kernel headers) and Wi-Fi hardware with no working interface (installs the missing firmware package; Broadcom also gets an optional proprietary driver).
- A notification appears at login (once per hardware set) when drivers are available. Nothing is installed without the user's OK.
- Wi-Fi firmware was already in the image through firmware-linux, so Wi-Fi works offline on most laptops.
- Secure Boot is checked; the user is warned before the NVIDIA driver is installed.
- Not tested on real hardware: NVIDIA install, dkms build, Broadcom driver.

## Iteration 5: firewall and security updates
- Fixed: apt sources had only the main suite, so security updates never arrived. Now trixie, trixie-updates and trixie-security.
- Firewall (ufw) is on at every boot: incoming blocked, outgoing allowed. "HarpreetLinux Firewall" window: on/off, allow a port or service, remove a rule, show rules.
- Automatic security updates (unattended-upgrades, security origin only, no automatic reboot). "HarpreetLinux Updates" window lists and installs updates and switches the automatic part on/off.
- Update notification: after login and every 6 hours (not in the live session).
- Not tested in a real boot: ufw at boot, the notification button, unattended-upgrades run.

## Iteration 4: backups and disk encryption
- Timeshift + cron are installed. "HarpreetLinux Backup" (menu, or a button in the Welcome window) turns on weekly and monthly snapshots, optionally also one before software installs (at most daily), makes a snapshot now, or opens Timeshift to restore or choose an external drive.
- Installer: "Encrypt system" (LUKS1) offered on the partition page; the key-file step is added so the password is asked once. Set ENABLE_DISK_ENCRYPTION="no" in distro.conf to turn it off.
- Tools that need administrator rights now use `sudo -A` with a zenity password box (no polkit agent is installed in the image).
- Not tested in a real install: encrypted install, first boot from an encrypted disk, and a restore.

## Iteration 3: Punjabi localization
- Locales en_US and pa_IN are generated in the image; extra boot menu entry "live, Punjabi".
- Keyboard: English + Punjabi (InScript) in XFCE, Alt+Shift switches.
- Setup and Welcome windows, and menu names, are shown in Punjabi when the language is Punjabi (texts in /usr/share/harpreetlinux/i18n.sh and i18n/pa-groups.txt).
- New "Change language" tool (harpreetlinux-language) and new tool group "punjabi" (fonts, phonetic typing, browser/mail/office language packs).

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
