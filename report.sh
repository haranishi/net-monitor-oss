#!/bin/bash
# 測定CSVを時間帯別に集計する。混雑時間帯依存か常時遅いかを判定するのが目的。
CSV="$(cd "$(dirname "$0")" && pwd)/log/measurements.csv"
[ -f "$CSV" ] || { echo "測定データなし"; exit 1; }
echo "件数: $(( $(wc -l < "$CSV") - 1 ))  期間: $(sed -n 2p "$CSV" | cut -d, -f1) 〜 $(tail -1 "$CSV" | cut -d, -f1)"
echo
printf "%-7s %5s %9s %9s %9s %8s %7s\n" "時間帯" "回数" "下りv4" "上りv4" "下りv6" "遅延v4" "RSSI"
awk -F, 'NR>1 && $1!="" {
  h=substr($1,12,2)+0; b=int(h/3)*3;
  n[b]++; dl[b]+=$2; ul[b]+=$3; d6[b]+=$4; p4[b]+=$5; r[b]+=$8
} END {
  for(b=0;b<24;b+=3) if(n[b])
    printf "%02d-%02d時 %5d %8.1f %8.1f %8.1f %7.0f %7.0f\n", b, b+3, n[b], dl[b]/n[b], ul[b]/n[b], d6[b]/n[b], p4[b]/n[b], r[b]/n[b]
}' "$CSV"
echo
echo "-- 下りの最良/最悪 --"
awk -F, 'NR>1 && $2!=""' "$CSV" | sort -t, -k2 -g | (head -1; tail -1) | awk -F, '{printf "  %s  下り%sMbps 上り%sMbps\n",$1,$2,$3}'
