#!/usr/bin/env bash
# Boot the ISO headless in QEMU and check that it reaches a login prompt or live session.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../distro.conf
source "$ROOT/distro.conf"

ISO="$ROOT/out/${NAME_LOWER}-live.iso"
LOG="$ROOT/out/boot-test.log"
TIMEOUT="${BOOT_TIMEOUT:-420}"

[ -f "$ISO" ] || { echo "ERROR: $ISO not found" >&2; exit 1; }

ACCEL="tcg"
[ -w /dev/kvm ] && ACCEL="kvm"
echo "Booting $ISO with accel=$ACCEL (timeout ${TIMEOUT}s)"

timeout "$TIMEOUT" qemu-system-x86_64 \
    -accel "$ACCEL" -m 2048 -smp 2 \
    -cdrom "$ISO" -boot d \
    -display none -serial file:"$LOG" -no-reboot &
QPID=$!

for _ in $(seq 1 "$TIMEOUT"); do
    if grep -qE 'login:|live-config:' "$LOG" 2>/dev/null; then
        echo "PASS: reached login prompt"
        kill "$QPID" 2>/dev/null || true
        exit 0
    fi
    kill -0 "$QPID" 2>/dev/null || break
    sleep 1
done

kill "$QPID" 2>/dev/null || true
echo "FAIL: no login prompt. Last log lines:" >&2
tail -40 "$LOG" >&2 || true
exit 1
