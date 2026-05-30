#!/usr/bin/env bash
DESCRIPTION="Maximum performance + MSI EC tuning."
apply_mode() {
  set_power_profile performance
  set_msi_shift_prefer turbo comfort eco
  set_msi_fan_prefer auto advanced silent
  set_msi_cooler_boost on
  set_msi_super_battery off
}
