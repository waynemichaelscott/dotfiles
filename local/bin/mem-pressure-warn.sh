#!/usr/bin/env bash
# Desktop toast when the machine starts thrashing on memory.
#
# Why this exists: this box runs a heavy dev load (Docker, several Elixir/Node
# services, Chrome, multiple editors, Claude sessions). When a build spikes RAM
# the machine has frozen and the kernel OOM-killer has nuked a whole app
# (VSCode) with no warning. systemd-oomd can act, but it never *warns*. This
# watcher gives a heads-up toast while pressure is still *building*, so there is
# time to close something heavy before anything is killed.
#
# Signal is PSI memory stall (`/proc/pressure/memory`), i.e. the % of time a
# task was actually stalled waiting on memory -- the real thrash metric. Raw
# RAM % is useless here: 30 GB "used" on a 62 GB box is normal and quiet.
set -u

POLL=5         # seconds between checks
WARN=20        # notify (normal)   when `some avg10` stall % >= this
CRIT=40        # notify (critical) when `some avg10` stall % >= this
COOLDOWN=60    # min seconds between toasts (avoids spamming mako)

last_warn=-100000
last_crit=-100000

# `some avgN` = % of the last N seconds at least one task stalled on memory.
read_psi() {
  awk '/^some/ { for (i=2;i<=NF;i++) if ($i ~ /^avg10=/) { sub(/avg10=/,"",$i); print $i; exit } }' \
    /proc/pressure/memory
}

# Short swap summary for the toast body (leading indicator on this box).
swap_line() {
  free -h | awk '/^Swap:/ { printf "swap %s / %s used", $3, $2 }'
}

# float >= threshold, via awk (bash can't compare floats)
ge() { awk -v p="$1" -v t="$2" 'BEGIN { exit !(p + 0 >= t) }'; }

toast() {  # urgency  title  body
  notify-send -u "$1" -a mem-pressure -i dialog-warning "$2" "$3"
}

echo "mem-pressure-warn: polling every ${POLL}s (warn=${WARN}%, crit=${CRIT}%)"

while true; do
  p="$(read_psi 2>/dev/null)"; p="${p:-0}"
  now=$SECONDS

  if ge "$p" "$CRIT"; then
    if (( now - last_crit >= COOLDOWN )); then
      toast critical "🔴 Memory critical — ${p}% stall" "$(swap_line). Close the VM / tabs NOW."
      echo "CRIT ${p}% ($(swap_line))"
      last_crit=$now; last_warn=$now
    fi
  elif ge "$p" "$WARN"; then
    if (( now - last_warn >= COOLDOWN )); then
      toast normal "🟠 Memory pressure — ${p}% stall" "$(swap_line). Consider closing something heavy."
      echo "WARN ${p}% ($(swap_line))"
      last_warn=$now
    fi
  fi

  sleep "$POLL"
done
