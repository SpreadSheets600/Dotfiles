#!/usr/bin/env bash

set -e

VIDEO_DEVICE="/dev/video10"
CARD_LABEL="PhoneCam"

echo "[*] Disabling USB Autosuspend..."

for i in /sys/bus/usb/devices/*/power/control; do
    echo on | sudo tee "$i" >/dev/null || true
done

echo "[*] Loading v4l2loopback..."

if ! lsmod | grep -q v4l2loopback; then
    sudo modprobe v4l2loopback \
        devices=1 \
        video_nr=10 \
        card_label="$CARD_LABEL" \
        exclusive_caps=1
fi

echo "[*] Starting ADB Server..."
adb start-server >/dev/null

echo "[*] Keeping Device Awake..."

adb shell settings put system screen_off_timeout 2147483647 || true
adb shell svc power stayon usb || true

echo "[*] Starting Virtual Camera..."

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

    echo "[!] Device Disconnected. Restarting In 3 Seconds..."
    sleep 3
done
