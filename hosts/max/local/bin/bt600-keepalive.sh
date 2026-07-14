#!/usr/bin/env bash
# Playback-gated keep-alive for the Plantronics BT600.
#
# The BT600 dongle downgrades its wireless link to the headset (quieter, lower
# quality) when it thinks the stream is idle. Holding a silent capture on the
# sink monitor keeps the link at full quality, but running it 24/7 drains the
# headset battery and defeats its auto-sleep. So we only hold the link open
# while real audio is actually playing to the BT600, plus a short grace period
# so brief gaps between tracks do not cause a quality dip.
set -u

MONITOR="alsa_output.usb-Plantronics_Plantronics_BT600_ca9c4e372614bd4a9ad1f12905ded968-00.iec958-stereo.monitor"
DEVICE_MATCH="BT600"   # matches the BT600 sink name in `pactl list short sinks`
POLL=2                 # seconds between checks
GRACE=45               # keep the link warm this long after playback stops

KA_PID=""

start_ka() {
  if [ -n "$KA_PID" ] && kill -0 "$KA_PID" 2>/dev/null; then return; fi
  pw-record --target "$MONITOR" /dev/null >/dev/null 2>&1 &
  KA_PID=$!
  echo "keep-alive ON (playback on BT600)"
}

stop_ka() {
  [ -n "$KA_PID" ] || return
  kill "$KA_PID" 2>/dev/null
  KA_PID=""
  echo "keep-alive OFF (BT600 idle, letting headset sleep)"
}

cleanup() { stop_ka; exit 0; }
trap cleanup TERM INT EXIT

# Is there an uncorked playback stream routed to the BT600 sink right now?
is_playing() {
  local sink_ids
  sink_ids=$(pactl list short sinks 2>/dev/null | grep -i "$DEVICE_MATCH" | cut -f1)
  [ -z "$sink_ids" ] && return 1
  pactl list sink-inputs 2>/dev/null | awk -v ids="$sink_ids" '
    BEGIN { n = split(ids, a, "\n"); for (i = 1; i <= n; i++) want[a[i]] = 1; playing = 0 }
    /^Sink Input #/          { sink = ""; corked = "" }
    /^[[:space:]]*Sink:/      { sink = $2 }
    /^[[:space:]]*Corked:/    { corked = $2; if ((sink in want) && corked == "no") playing = 1 }
    END { exit playing ? 0 : 1 }
  '
}

idle_start=-1
while true; do
  if is_playing; then
    idle_start=-1
    start_ka
  else
    [ "$idle_start" -lt 0 ] && idle_start=$SECONDS
    if [ $((SECONDS - idle_start)) -ge "$GRACE" ]; then
      stop_ka
    fi
  fi
  sleep "$POLL"
done
