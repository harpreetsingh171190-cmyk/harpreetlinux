# Make system tools (ip, iw, ping, wpa_supplicant) available to normal users.
case ":$PATH:" in
  *:/usr/sbin:*) ;;
  *) PATH="$PATH:/usr/local/sbin:/usr/sbin:/sbin" ;;
esac
export PATH
