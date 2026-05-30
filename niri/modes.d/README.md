# niri-mode custom modes

Each mode is a shell file:

`~/.config/niri/modes.d/<mode-name>.sh`

Required interface:

```bash
DESCRIPTION="Shown in list output"
apply_mode() {
  # Your commands here
}
```

Helpers available inside `apply_mode()`:

- `set_power_profile performance|balanced|power-saver`
- `run_cmd "<shell command>"`
- `set_msi_shift_prefer <modes...>`
- `set_msi_fan_prefer <modes...>`
- `set_msi_cooler_boost on|off`
- `set_msi_super_battery on|off`
- `set_msi_ec_value <node> <value>`

MSI EC writes usually require elevated permission. `niri-mode` tries, in order:

1. direct write if writable
2. `sudo -n` (passwordless sudo)
3. `pkexec` (Polkit prompt, only when `NIRI_MODE_ALLOW_PKEXEC=1`)

Example custom mode:

```bash
#!/usr/bin/env bash
DESCRIPTION="Quiet + cool setup"
apply_mode() {
  set_power_profile power-saver
  set_msi_shift_prefer eco comfort
  set_msi_fan_prefer silent auto
  run_cmd "brightnessctl set 50%"
}
```

Apply your mode:

`niri-mode apply quiet`
