#!/usr/bin/env bash

set -euo pipefail

VIDEO_DEVICE="/dev/video10"
CARD_LABEL="PhoneCam"

printf '[*] Disabling USB autosuspend\n'

for node in /sys/bus/usb/devices/*/power/control; do
  echo on | sudo tee "$node" >/dev/null || true
done

printf '[*] Loading v4l2loopback\n'

if ! lsmod | grep -q v4l2loopback; then
  sudo modprobe v4l2loopback \
    devices=1 \
    video_nr=10 \
    card_label="$CARD_LABEL" \
    exclusive_caps=1
fi

printf '[*] Starting adb server\n'

adb start-server >/dev/null

printf '[*] Keeping device awake\n'

adb shell settings put system screen_off_timeout 2147483647 || true
adb shell svc power stayon usb || true

printf '[*] Starting virtual camera\n'

while true; do
  scrcpy \
    --video-source=camera \
    --camera-id=1 \
    --v4l2-sink="$VIDEO_DEVICE" \
    --no-window \
    --no-audio \
    --camera-size=1280x720 \
    --max-fps=24 \
    --render-driver=software

  printf '[!] Device disconnected, restarting in 3 seconds\n'
  sleep 3
done
