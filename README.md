# thinkfan on a ThinkPad X220 Tablet with Omarchy

Fixes the **thinkfan crash loop** on Omarchy with newer kernels, and makes the fan follow the CPU temperature
(coretemp) with load-focused curves. Tested on a ThinkPad X220 Tablet (i7-2620M) running Omarchy, kernel 7.2.x.
It may help other ThinkPads whose kernel has `/proc/acpi/ibm/fan` but no `/proc/acpi/ibm/thermal`.

## Symptom
`thinkfan.service` fails on every start and dumps core:

    thinkfan: ERROR: Unhandled std::bad_optional_access: bad optional access.
    thinkfan: errno = No such file or directory.
    systemd-coredump: Process (thinkfan) dumped core.   (SIGABRT, repeated)

## Cause
The omarchy-fan profiles (`/usr/share/omarchy-fan/profiles/{quiet,balanced,performance}.yaml`) read the sensor
`/proc/acpi/ibm/thermal`. That file does not exist on this kernel (fan control at `/proc/acpi/ibm/fan` does), and
thinkfan aborts on a missing sensor file instead of reporting it.

## What this repo does
1. Switches the profile sensor to coretemp by name (hottest of Package, Core 0, Core 1).
2. Installs load-focused curves: stock idle behaviour, ramp 4-5 C earlier above ~55 C
   (full speed by ~76 / 72 / 66 C for quiet / balanced / performance; CPU high is 86 C).
3. A pacman hook re-applies 1 and 2 after every `omarchy-fan-helper` upgrade.
4. A systemd drop-in restarts thinkfan on failure (10 s, max 5 starts per 5 min) and orders it after module loading.
5. Loads `coretemp` at boot.

## Install
Requires the Omarchy ThinkPad fan plugin (`omarchyfan`), `thinkfan`, and `omarchy-fan-helper` already installed.

    git clone <this repo> && cd <repo>/scripts
    sudo ./install.sh
    omarchyfan balanced
    reboot

Check: `omarchyfan doctor`, `systemctl is-active thinkfan`, and `/proc/acpi/ibm/fan` should show a numeric
`level:` rather than `auto`.

## Undo
    sudo rm /usr/local/sbin/omarchy-fan-local-profiles /etc/pacman.d/hooks/omarchy-fan-local-profiles.hook \
            /etc/systemd/system/thinkfan.service.d/zz-local.conf /etc/modules-load.d/coretemp.conf
    sudo systemctl daemon-reload
    sudo ./scripts/load-focused.sh --restore    # stock curves; stock profiles alone still crash thinkfan here

Do not use `omarchyfan <profile>` on stock profiles on an affected kernel: it reinstalls the broken sensor.

## Test under load
    watch -n 1 'omarchyfan stats | tr "\t" " " | grep -E "profile|temp|rpm|level"'
    for i in 1 2 3 4; do timeout 180 yes > /dev/null & done; wait

Expect the fan level to climb with temperature, a plateau well below 86 C, and a gradual step down afterwards.

## Standalone (without the plugin)
`config/thinkfan-standalone.yaml` is a plain thinkfan config with the same coretemp sensor:
`sudo thinkfan -n -vv -c config/thinkfan-standalone.yaml`.

## Limits
- Root cause is upstream (profile sensor assumption + thinkfan abort); no upstream report filed yet.
- The curves are tuned by reasoning and a few readings, not by long benchmarking. Adjust to taste.
- Package updates overwrite the profile files; the hook is untested against a real package upgrade.
