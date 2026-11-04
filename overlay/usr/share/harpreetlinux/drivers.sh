# Hardware detection for HarpreetLinux drivers (POSIX sh). Needs i18n.sh to be sourced first.
# hl_drivers_detect prints one line per driver offer:   key|hardware|display|tokens|TRUE/FALSE
# "tokens" are what the root helper understands: package names plus "nvidia" and "headers".

hl_pkg_installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'; }

hl_nvidia_installed() {
  dpkg-query -W -f='${Package} ${Status}\n' 'nvidia-*driver' 2>/dev/null | grep -q 'install ok installed'
}

hl_wifi_present() {
  for d in /sys/class/net/*/wireless; do [ -e "$d" ] && return 0; done
  return 1
}

hl_secure_boot_on() {
  for f in /sys/firmware/efi/efivars/SecureBoot-*; do
    [ -r "$f" ] || continue
    [ "$(od -An -t u1 -j4 -N1 "$f" 2>/dev/null | tr -d ' ')" = 1 ] && return 0
  done
  return 1
}

hl_drivers_detect() {
  _pci=$(lspci -nn 2>/dev/null)
  _usb=$(lsusb 2>/dev/null)

  # NVIDIA graphics (display controllers with vendor 10de)
  _nv=$(printf '%s\n' "$_pci" | grep -E '\[(0300|0302|0380)\]' | grep -i '\[10de:' | head -n1)
  if [ -n "$_nv" ] && ! hl_nvidia_installed; then
    _desc=$(printf '%s' "$_nv" | sed -E 's/^[^]]*\]: //; s/ \[[0-9a-f]{4}:[0-9a-f]{4}\].*//')
    printf 'nvidia|%s: %s|nvidia-driver, linux-headers|nvidia|TRUE\n' "$HL_DRV_NV" "$_desc"
  fi

  # Wi-Fi: only when a Wi-Fi device exists but no wireless interface came up
  if ! hl_wifi_present; then
    {
      printf '%s\n' "$_pci" | grep -E '\[0280\]' | while IFS= read -r _l; do
        _v=$(printf '%s' "$_l" | sed -nE 's/.*\[([0-9a-f]{4}):[0-9a-f]{4}\].*/\1/p')
        _d=$(printf '%s' "$_l" | sed -E 's/^[^]]*\]: //; s/ \[[0-9a-f]{4}:[0-9a-f]{4}\].*//')
        printf '%s|%s\n' "$_v" "$_d"
      done
      printf '%s\n' "$_usb" | grep -i -E 'wireless|wlan|802\.11|wi-?fi' | while IFS= read -r _l; do
        _v=$(printf '%s' "$_l" | sed -nE 's/.*ID ([0-9a-f]{4}):[0-9a-f]{4}.*/\1/p')
        _d=$(printf '%s' "$_l" | sed -E 's/.*ID [0-9a-f]{4}:[0-9a-f]{4} //')
        printf '%s|%s\n' "$_v" "$_d"
      done
    } | sort -u | while IFS='|' read -r _v _d; do
      case "$_v" in
        8086)           _p="firmware-iwlwifi" ;;
        10ec|0bda)      _p="firmware-realtek" ;;
        168c|0cf3|17cb) _p="firmware-atheros" ;;
        14e4)           _p="firmware-brcm80211" ;;
        14c3|0e8d)      _p="firmware-misc-nonfree firmware-mediatek" ;;
        1814|148f)      _p="firmware-misc-nonfree" ;;
        *) continue ;;
      esac
      _missing=""
      for _x in $_p; do hl_pkg_installed "$_x" || _missing="$_missing $_x"; done
      _missing=${_missing# }
      [ -n "$_missing" ] && printf 'wifi-%s|%s: %s|%s|%s|TRUE\n' "$_v" "$HL_DRV_WIFI" "$_d" "$_missing" "$_missing"
      if [ "$_v" = 14e4 ] && ! hl_pkg_installed broadcom-sta-dkms; then
        printf 'bcmwl|%s: %s|broadcom-sta-dkms, linux-headers|headers broadcom-sta-dkms|FALSE\n' "$HL_DRV_BCM" "$_d"
      fi
    done
  fi
}
