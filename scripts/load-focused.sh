#!/bin/bash
# Usage: sudo load-focused.sh [--restore] [dir]
# Load-focused omarchy-fan curves: idle behaviour stays as stock (level 1-2 at light use), ramp ~4-5 C earlier above ~55 C.
# Full speed is reached by ~76 C (quiet), ~72 C (balanced), ~66 C (performance). The first original of each profile is kept
# as <profile>.yaml.pre-aggressive and never overwritten, so --restore always returns to stock.
set -e
restore=0; [ "$1" = --restore ] && { restore=1; shift; }
dir=${1:-/usr/share/omarchy-fan/profiles}
for n in quiet balanced performance; do [ -e "$dir/$n.yaml" ] || { echo "missing $dir/$n.yaml" >&2; exit 1; }; done

setlevels() {
  local f=$dir/$1.yaml; shift
  if [ $restore = 1 ]; then
    [ -e "$f.pre-aggressive" ] && { cp -p "$f.pre-aggressive" "$f"; echo "restored $f"; } || echo "no backup for $f, left alone"
    return
  fi
  [ -e "$f.pre-aggressive" ] || cp -p "$f" "$f.pre-aggressive"
  sed -i '/^levels:/,$d' "$f"
  { echo "levels:"; printf '  %s\n' "$@"; } >> "$f"
  echo "updated $f"
}
setlevels quiet \
 '- [1, 0, 56]' '- [2, 52, 60]' '- [3, 57, 64]' '- [4, 61, 67]' '- [5, 64, 70]' '- [6, 67, 73]' '- [7, 70, 76]' '- ["level full-speed", 74, 32767]'
setlevels balanced \
 '- [1, 0, 52]' '- [2, 48, 56]' '- [3, 53, 60]' '- [4, 57, 63]' '- [5, 60, 66]' '- [6, 63, 69]' '- [7, 66, 72]' '- ["level full-speed", 70, 32767]'
setlevels performance \
 '- [1, 0, 47]' '- [2, 43, 51]' '- [3, 48, 54]' '- [4, 51, 57]' '- [5, 54, 60]' '- [6, 57, 63]' '- [7, 60, 66]' '- ["level full-speed", 64, 32767]'
[ $restore = 1 ] || echo "now run: omarchyfan reapply"
