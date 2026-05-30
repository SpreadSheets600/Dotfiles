#!/usr/bin/env bash
DESCRIPTION="Balanced defaults + MSI EC tuning."
apply_mode() {
  set_power_profile balanced
  set_msi_shift_prefer comfort eco turbo
  set_msi_fan_prefer auto silent advanced
  set_msi_cooler_boost off
  set_msi_super_battery off
}
