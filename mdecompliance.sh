#!/bin/bash
M=/usr/local/bin/mdatp
if [ ! -x "$M" ]; then
  echo '{"MdeInstalled":false,"MdeHealthy":false,"RtpEnabled":false,"DefAgeMinutes":999999,"ActiveThreats":999}'
  exit 0
fi
f(){ "$M" health --field "$1" 2>/dev/null | head -n1 | tr -d '"[:space:]'; }
b(){ [ "$(f "$1")" = "true" ] && echo true || echo false; }
age=$(f definitions_updated_minutes_ago); [[ "$age" =~ ^[0-9]+$ ]] || age=999999
thr=$("$M" threat list 2>/dev/null | grep -ci "threat id"); [[ "$thr" =~ ^[0-9]+$ ]] || thr=999
echo "{\"MdeInstalled\":true,\"MdeHealthy\":$(b healthy),\"RtpEnabled\":$(b real_time_protection_enabled),\"DefAgeMinutes\":$age,\"ActiveThreats\":$thr}"
exit 0