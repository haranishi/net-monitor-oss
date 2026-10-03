#!/bin/bash
# 回線の下り/上り/遅延/Wi-Fi品質を1回測定してローカルCSVに追記する
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
CSV="$DIR/log/measurements.csv"
mkdir -p "$DIR/log"
BYTES=10000000
DOWN="https://speed.cloudflare.com/__down?bytes=$BYTES"
UP="https://speed.cloudflare.com/__up"

[ -f "$CSV" ] || echo "timestamp,dl_v4_mbps,ul_v4_mbps,dl_v6_mbps,ping_v4_ms,ping_v6_ms,ping_router_ms,rssi_dbm,tx_rate_mbps,channel" > "$CSV"

bps2mbps() { awk -v b="${1:-0}" 'BEGIN{printf "%.1f", b*8/1000000}'; }
pingavg() { "$1" -c 5 -i 0.2 "$2" 2>/dev/null | tail -1 | awk -F'/' '{printf "%.0f", $5}'; }

DL4=$(bps2mbps "$(curl -4 -s -o /dev/null --max-time 45 -w '%{speed_download}' "$DOWN" 2>/dev/null)")
DL6=$(bps2mbps "$(curl -6 -s -o /dev/null --max-time 45 -w '%{speed_download}' "$DOWN" 2>/dev/null)")
TMP=$(mktemp); dd if=/dev/zero of="$TMP" bs=1m count=10 2>/dev/null
UL4=$(bps2mbps "$(curl -4 -s -o /dev/null --max-time 45 -w '%{speed_upload}' -X POST --data-binary @"$TMP" "$UP" 2>/dev/null)")
rm -f "$TMP"

P4=$(pingavg ping 1.1.1.1); P6=$(pingavg ping6 2606:4700:4700::1111); PR=""
if [ -n "${ROUTER_HOST:-}" ]; then PR=$(pingavg ping "$ROUTER_HOST"); fi

W=$(system_profiler SPAirPortDataType 2>/dev/null | sed -n '/Current Network Information/,/Other Local/p')
RSSI=$(echo "$W" | awk -F'[ /]+' '/Signal \/ Noise/{print $4}')
RATE=$(echo "$W" | awk -F': *' '/Transmit Rate/{print $2}')
CH=$(echo "$W"   | awk -F': *' '/Channel/{print $2}' | tr -d ' ' | tr ',' ';')

echo "$(date '+%Y-%m-%d %H:%M'),$DL4,$UL4,$DL6,${P4:-},${P6:-},${PR:-},${RSSI:-},${RATE:-},${CH:-}" >> "$CSV"
tail -1 "$CSV"
