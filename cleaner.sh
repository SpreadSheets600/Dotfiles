#!/usr/bin/env bash

set -e

echo "Starting Deep Cleanup"

echo "Removing Python And Node Environments"
find /root -type d \( -name ".venv" -o -name "venv" -o -name "env" -o -name "node_modules" \) -prune -exec rm -rf {} + 2>/dev/null || true

echo "Removing Python Cache Directories"
find /root -type d \( -name "__pycache__" -o -name ".pytest_cache" -o -name ".mypy_cache" -o -name ".ruff_cache" \) -prune -exec rm -rf {} + 2>/dev/null || true

echo "Clearing Pip Cache"
pip cache purge 2>/dev/null || true

echo "Clearing Npm Cache"
npm cache clean --force 2>/dev/null || true

echo "Clearing General Cache"
rm -rf /root/.cache/* 2>/dev/null || true

echo "Cleaning Apt"
apt clean
apt autoremove --purge -y

echo "Cleaning Logs"
journalctl --vacuum-time=7d 2>/dev/null || true
rm -rf /var/log/*.gz /var/log/*.[0-9] 2>/dev/null || true

echo "Emptying Trash"
rm -rf /root/.local/share/Trash/* 2>/dev/null || true

echo "Cleanup Complete"
du -sh /root /var 2>/dev/null
