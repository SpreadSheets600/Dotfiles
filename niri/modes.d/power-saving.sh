#!/usr/bin/env bash
DESCRIPTION="Lower power usage + MSI EC tuning."
apply_mode() {
  set_power_profile power-saver
  set_msi_shift_prefer eco comfort turbo
  set_msi_fan_prefer silent auto advanced
  set_msi_cooler_boost off
  set_msi_super_battery on
}
