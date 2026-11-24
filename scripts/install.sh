#!/bin/bash
# Usage: sudo install.sh
set -e
here=$(cd "$(dirname "$0")" && pwd)
install -Dm755 "$here/omarchy-fan-local-profiles"      /usr/local/sbin/omarchy-fan-local-profiles
install -Dm644 "$here/omarchy-fan-local-profiles.hook" /etc/pacman.d/hooks/omarchy-fan-local-profiles.hook
install -Dm644 "$here/zz-local.conf"                   /etc/systemd/system/thinkfan.service.d/zz-local.conf
install -Dm644 "$here/coretemp.conf"                   /etc/modules-load.d/coretemp.conf
/usr/local/sbin/omarchy-fan-local-profiles
systemctl daemon-reload
systemctl is-enabled thinkfan thinkfan-sleep thinkfan-wakeup >/dev/null || systemctl enable thinkfan
echo "installed. thinkfan is untouched and keeps running; the drop-in applies on its next (re)start."
