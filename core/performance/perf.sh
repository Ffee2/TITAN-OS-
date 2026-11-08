#!/usr/bin/env bash
# Path: core/performance/perf.sh  (sourced; needs core/lib/common.sh)
# Every reader returns real data or the word "unavailable". Android restricts
# several /proc and /sys files, so callers must handle "unavailable".

perf_cpu_usage() {  # integer percent measured over ~1 second
  local a b
  a=$(head -n1 /proc/stat 2>/dev/null) && [ -n "$a" ] || { echo unavailable; return; }
  sleep 1
  b=$(head -n1 /proc/stat 2>/dev/null) || { echo unavailable; return; }
  awk -v a="$a" -v b="$b" 'BEGIN{
    split(a,x," "); split(b,y," "); ta=0; tb=0
    for(i=2;i<=9;i++){ta+=x[i]; tb+=y[i]}
    dt=tb-ta; if(dt<=0){print "unavailable"; exit}
    printf "%d\n", (1-((y[5]+y[6])-(x[5]+x[6]))/dt)*100 }'
}

perf_load() {  # "1m 5m 15m"
  local l
  if l=$(cat /proc/loadavg 2>/dev/null) && [ -n "$l" ]; then
    echo "$l" | awk '{print $1, $2, $3}'
  elif l=$(uptime 2>/dev/null) && [ -n "$l" ]; then
    echo "$l" | sed -n 's/.*load average[s]*: *//p' | tr -d ',' | awk '{print $1, $2, $3}'
  else echo unavailable; fi
}

perf_uptime() {
  local s
  if s=$(cut -d. -f1 /proc/uptime 2>/dev/null) && [[ "$s" =~ ^[0-9]+$ ]]; then
    awk -v s="$s" 'BEGIN{d=int(s/86400); h=int(s%86400/3600); m=int(s%3600/60);
      if(d>0) printf "%dd ", d; printf "%dh %dm\n", h, m}'
  elif s=$(uptime -p 2>/dev/null) && [ -n "$s" ]; then echo "${s#up }"
  else echo unavailable; fi
}

perf_cpu_freqs() {  # lines: cpuN MHz (nothing when the kernel hides cpufreq)
  local f n v
  for f in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq; do
    [ -e "$f" ] || continue
    v=$(cat "$f" 2>/dev/null) || continue
    [[ "$v" =~ ^[0-9]+$ ]] || continue
    n=${f#/sys/devices/system/cpu/}; n=${n%%/*}
    echo "$n $((v / 1000))"
  done
}

perf_governor() {
  cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo unavailable
}

perf_mem() {  # prints: total_kb available_kb swap_total_kb swap_free_kb
  awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} /^SwapTotal:/{st=$2} /^SwapFree:/{sf=$2}
       END{ if(t==""){print "unavailable"; exit} printf "%d %d %d %d\n", t, a, st+0, sf+0 }' \
    /proc/meminfo 2>/dev/null || echo unavailable
}

perf_thermal() {  # lines: zone_name temp_celsius
  local z t n
  for z in /sys/class/thermal/thermal_zone*; do
    [ -d "$z" ] || continue
    t=$(cat "$z/temp" 2>/dev/null) || continue
    [[ "$t" =~ ^-?[0-9]+$ ]] || continue
    n=$(cat "$z/type" 2>/dev/null) || n="${z##*/}"
    awk -v n="${n// /_}" -v t="$t" 'BEGIN{ if (t>200 || t<-200) t/=1000; printf "%s %.1f\n", n, t }'
  done
}

perf_gpu() {  # real detection only; Android reports driver names, not models
  local out="" egl vk
  if have_cmd lspci; then
    out=$(lspci 2>/dev/null | grep -Ei 'vga|3d controller|display controller' | sed 's/^[^ ]* //')
  fi
  if [ -z "$out" ] && have_cmd getprop; then
    egl=$(getprop ro.hardware.egl 2>/dev/null); vk=$(getprop ro.hardware.vulkan 2>/dev/null)
    [ -n "$egl$vk" ] && out="Android graphics driver: egl=${egl:-n/a} vulkan=${vk:-n/a}"
  fi
  echo "${out:-not detectable}"
}

perf_processes() {  # usage: perf_processes [N]  (top N by CPU)
  local n="${1:-10}"
  if ps -eo pid,pcpu,pmem,comm --sort=-pcpu >/dev/null 2>&1; then
    ps -eo pid,pcpu,pmem,comm --sort=-pcpu 2>/dev/null | head -n "$((n + 1))"
  elif ps aux >/dev/null 2>&1; then
    ps aux 2>/dev/null | head -n "$((n + 1))"
  elif ps -A >/dev/null 2>&1; then
    ps -A 2>/dev/null | head -n "$((n + 1))"
  else
    ps 2>/dev/null | head -n "$((n + 1))" || echo unavailable
  fi
}
