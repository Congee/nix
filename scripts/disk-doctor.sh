#!/usr/bin/env bash
# Space reclaimer shaped like `nh clean all --ask`: size table first, then a
# prompt per site. Wired up in homes/darwin.nix, which supplies the real shebang
# — the line above is only here so editors and shellcheck know the language.

# No -e on purpose: one unreadable path must not abort the rest of the sweep.
set -uo pipefail
# Empty globs expand to nothing, and a cache's dotfiles are cache too.
shopt -s nullglob dotglob

# launchd agents get a minimal PATH, and docker lives outside it.
PATH="/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.nix-profile/bin:$HOME/.orbstack/bin:/opt/homebrew/bin:${PATH:-}"

stale_days=${DISK_DOCTOR_STALE_DAYS:-7}
build_stale_days=${DISK_DOCTOR_BUILD_STALE_DAYS:-60}

usage() {
  cat <<'EOF'
disk-doctor [--report|--ask|--auto]
  --report  size table, deletes nothing (default)
  --ask     prompt before every site, auto and ask tiers alike
  --auto    sweep the self-regenerating tier without prompting
EOF
}

mode=report
case "${1:-}" in
  ''|--report) ;;
  --ask)       mode=ask ;;
  --auto)      mode=auto ;;
  -h|--help)   usage; exit 0 ;;
  *)           printf 'unknown flag: %s\n\n' "$1" >&2; usage >&2; exit 2 ;;
esac
if [ "$#" -gt 1 ]; then
  echo "expected at most one flag" >&2
  exit 2
fi

# getconf, not literals: these paths are uid-derived.
tmp_dir=$(getconf DARWIN_USER_TEMP_DIR)
cache_dir=$(getconf DARWIN_USER_CACHE_DIR)
user_dir=$(getconf DARWIN_USER_DIR)
clone_dir="$(dirname "$user_dir")/X"

# Everything sweepable lives under one of these. A target resolving anywhere else
# means the table is malformed, which is not a thing to rm -rf over.
sweep_roots=("$HOME" "$tmp_dir" "$cache_dir" "$user_dir")

# TCC denies the unlink outright, and a read-only bundle dir (Sparkle ships one at
# 0555) denies it for every file inside. Either way rm emits a line per file and
# buries the run. Report whether the path survived and let the caller tally.
remove() {
  local path=$1 root
  for root in "${sweep_roots[@]}"; do
    case "$path" in
      "${root%/}"/?*) rm -rf -- "$path" 2>/dev/null; [ ! -e "$path" ]; return ;;
    esac
  done
  printf 'refusing to remove %s\n' "$path" >&2
  return 1
}

have() { command -v "$1" >/dev/null 2>&1; }

# Held out of the cache and temp sweeps.
held() {
  case "$1" in
    # Chat apps re-download their whole history, and Steam rebuilds every shader.
    com.tencent.*|*WeChat*|*QQ*|ru.keepcoder.*|net.whatsapp.*|抖音|Steam) return 0 ;;
    # brew cleanup prunes this precisely, and keeps the api cache it re-fetches.
    Homebrew) return 0 ;;
    # TCC refuses the unlink, so these bytes were never reclaimable to begin with.
    com.apple.*|CloudKit|FamilyCircle|familycircled) return 0 ;;
  esac
  return 1
}

without_held() {
  local child
  while IFS= read -r -d '' child; do
    held "${child##*/}" || printf '%s\0' "$child"
  done
}

# Xcode mints a ~5.5G symbol set per device OS build and never drops the superseded
# one. mtime cannot tell abandoned from in-use-but-unwritten, but a pairing can.
paired_names=""
paired_probed=""
load_paired() {
  [ -n "$paired_probed" ] && return 0
  paired_probed=yes
  have jq || return 0
  local json=${DISK_DOCTOR_DEVICES_JSON:-} tmp=""
  if [ -z "$json" ]; then
    have xcrun || return 0
    tmp=$(mktemp) || return 0
    # A real file, not a pipe: devicectl saves the JSON atomically, which fails on a
    # pipe while still exiting 0.
    if ! xcrun devicectl list devices --json-output "$tmp" >/dev/null 2>&1; then
      rm -f "$tmp"
      return 0
    fi
    json=$tmp
  fi
  # Folder names are "<productType> <osVersionNumber> (<osBuildUpdate>)".
  paired_names=$(jq -r '.result.devices[]
    | select(.connectionProperties.pairingState == "paired")
    | .hardwareProperties.productType + " " + .deviceProperties.osVersionNumber
      + " (" + .deviceProperties.osBuildUpdate + ")"' "$json" 2>/dev/null)
  [ -n "$tmp" ] && rm -f "$tmp"
  return 0
}

# KiB in, "9.4M" / "44G" out. A decimal only where it carries information.
human() {
  awk -v kib="$1" 'BEGIN {
    split("K M G T P", unit, " ")
    sign = kib < 0 ? "-" : ""
    size = kib < 0 ? -kib : kib
    i = 1
    while (size >= 1024 && i < 5) { size /= 1024; i++ }
    printf "%s%.*f%s", sign, (size < 10 && i > 1) ? 1 : 0, size, unit[i]
  }'
}

# Not ${path/#$HOME/~}: the replacement is tilde-expanded, so that quietly
# substitutes $HOME back in and never abbreviates anything.
abbrev() {
  case "$1" in
    "$HOME"/*) printf '~%s' "${1#"$HOME"}" ;;
    *)         printf '%s' "$1" ;;
  esac
}

sum_kb() { awk '{ total += $1 } END { printf "%d\n", total }'; }
du_kb()  { xargs -0r du -sk 2>/dev/null | sum_kb; }

# du over the nix store means walking millions of inodes for minutes. Where the
# target is its own volume, as /nix is on a stock darwin install, df knows already.
volume_used_kb() {
  local target=$1
  [ -d "$target" ] || { echo 0; return; }
  if [ "$(df -k "$target" | awk 'NR == 2 { print $1 }')" \
     = "$(df -k "$target/.." | awk 'NR == 2 { print $1 }')" ]; then
    du -sk -- "$target" 2>/dev/null | sum_kb  # not a mount point, no shortcut
  else
    df -k "$target" | awk 'NR == 2 { print $3 }'
  fi
}

# Both sizing and sweeping consume this one list, so they cannot disagree about
# what a site holds.
paths_of() {
  local kind=$1 target=$2 child
  case "$kind" in
    tree)
      [ -e "$target" ] && printf '%s\0' "$target"
      ;;
    contents)
      for child in "$target"/*; do printf '%s\0' "$child"; done
      ;;
    globs)  # unquoted on purpose: the target *is* a glob
      for child in $target; do printf '%s\0' "$child"; done
      ;;
    hold)
      for child in "$target"/*; do printf '%s\0' "$child"; done | without_held
      ;;
    older)  # the /var/folders sites are mostly Apple daemons that TCC protects
      find "$target" -mindepth 1 -maxdepth 1 -mtime +"$stale_days" -print0 2>/dev/null \
        | without_held
      ;;
    builds)  # -prune ahead of -mtime so find never descends into a dir it keeps
      find "$target" -maxdepth 4 -type d \( -name node_modules -o -name target \) \
        -prune -mtime +"$build_stale_days" -print0 2>/dev/null
      ;;
    devices)
      load_paired
      # No pairing data reads the same as no devices, and pruning everything then is
      # wrong. An empty keep set means emit nothing, not emit all.
      [ -n "$paired_names" ] || return 0
      for child in "$target"/*; do
        printf '%s\n' "$paired_names" | grep -qxF -- "${child##*/}" \
          || printf '%s\0' "$child"
      done
      ;;
  esac
}

docker_running() { docker info >/dev/null 2>&1; }

# `docker system df` reports SI sizes ("1.5GB"); this table is in KiB.
docker_reclaimable_kb() {
  if ! docker_running; then echo 0; return; fi
  docker system df --format '{{.Reclaimable}}' 2>/dev/null | awk '
    { size = $1 + 0; unit = $1; sub(/^[0-9.]+/, "", unit)
      if      (unit ~ /^TB/) size *= 1e12
      else if (unit ~ /^GB/) size *= 1e9
      else if (unit ~ /^MB/) size *= 1e6
      else if (unit ~ /^kB/) size *= 1e3
      total += size }
    END { printf "%d\n", total / 1024 }'
}

# Homebrew's own sizes are 1024-based despite the KB/MB/GB labels, and stop at GB.
brew_reclaimable_kb() {
  if ! have brew; then echo 0; return; fi
  brew cleanup --dry-run --prune=all 2>/dev/null | awk '
    /would free approximately/ {
      for (i = 1; i <= NF; i++) if ($i ~ /^[0-9.]+(B|KB|MB|GB)$/) {
        size = $i + 0; unit = $i; sub(/^[0-9.]+/, "", unit)
        if      (unit == "GB") size *= 1048576
        else if (unit == "MB") size *= 1024
        else if (unit == "B")  size /= 1024
        total += size
      }
    }
    END { printf "%d\n", total }'
}

size_kb() {
  case "$1" in
    docker) docker_reclaimable_kb ;;
    brew)   brew_reclaimable_kb ;;
    volume) volume_used_kb "$2" ;;
    *)      paths_of "$1" "$2" | du_kb ;;
  esac
}

sweep() {
  local kind=$1 target=$2 path total=0 kept=0
  case "$kind" in
    docker)
      docker_running || { echo "       docker daemon not running, skipped"; return; }
      docker system prune -af --volumes >/dev/null
      return ;;
    brew)
      have brew || { echo "       brew not installed, skipped"; return; }
      brew cleanup --prune=all >/dev/null
      return ;;
  esac
  while IFS= read -r -d '' path; do
    total=$(( total + 1 ))
    remove "$path" || kept=$(( kept + 1 ))
  done < <(paths_of "$kind" "$target")
  if [ "$kept" -gt 0 ]; then
    printf '       %d of %d left in place, the system would not unlink them\n' "$kept" "$total"
  fi
}

# tier|kind|label|target — adding an offender is one line.
#   tier  auto = regenerates itself, ask = your data, note = reported only
#   kind  tree contents globs hold older builds devices docker brew volume
# Labels stay ASCII: printf pads by byte, so a multi-byte one skews the column.
sites=(
  "auto|contents|nix fetch/eval cache|$HOME/.cache/nix"
  "auto|contents|yarn cache|$HOME/.cache/yarn"
  "auto|contents|bun cache|$HOME/.cache/bun"
  "auto|contents|typescript server cache|$HOME/.cache/typescript"
  "auto|contents|pnpm cache|$HOME/.cache/pnpm"
  "auto|contents|zig cache|$HOME/.cache/zig"
  "auto|contents|codex runtimes|$HOME/.cache/codex-runtimes"
  "auto|contents|nixpkgs-review worktrees|$HOME/.cache/nixpkgs-review"
  "auto|contents|lua-language-server cache|$HOME/.cache/lua-language-server"
  "auto|hold|app caches (chat apps held)|$HOME/Library/Caches"
  "auto|older|temp scratch >${stale_days}d|$tmp_dir"
  "auto|older|per-user cache >${stale_days}d|$cache_dir"
  "auto|older|per-user dir >${stale_days}d|$user_dir"
  "auto|globs|abandoned openskills temp dirs|$HOME/.openskills-temp-*"
  "auto|tree|pkg-cache (dead since 2025)|$HOME/.pkg-cache"
  "auto|devices|iOS DeviceSupport, unpaired only|$HOME/Library/Developer/Xcode/iOS DeviceSupport"
  "auto|docker|docker images + build cache + volumes|-"
  "auto|brew|homebrew downloads + superseded versions|-"
  "ask|tree|huggingface model cache|$HOME/.cache/huggingface"
  "ask|tree|ollama models|$HOME/.ollama"
  "ask|tree|LM Studio models|$HOME/.lmstudio"
  "ask|tree|i4Tools IPA downloads|$HOME/Downloads/i4ToolsDownloads/App"
  "ask|tree|WeChat chat media|$HOME/Library/Containers/com.tencent.xinWeChat/Data/Documents/xwechat_files"
  "ask|tree|Telegram media cache|$HOME/Library/Group Containers/6N38VWS5BX.ru.keepcoder.Telegram/appstore"
  "ask|builds|node_modules+target >${build_stale_days}d in ~/dev|$HOME/dev"
  "note|volume|nix store and var (nh clean all --ask)|/nix"
  "note|tree|leaked build sandboxes (root-owned, monthly daemon)|/nix/var/nix/builds"
  "note|tree|simulator dyld cache (needs sudo)|/Library/Developer/CoreSimulator/Caches"
  "note|tree|OrbStack image (shrinks lazily after a prune)|$HOME/Library/Group Containers/HUAQ24HBR6.dev.orbstack/data/data.img.raw"
  "note|tree|code-sign clones (root-owned, may be block-shared)|$clone_dir"
)

# Whichever volume $HOME lives on, whatever this machine calls it.
free_kb() { df -k "$HOME" | awk 'NR == 2 { print $4 }'; }
volume=$(df -k "$HOME" | awk 'NR == 2 { print $NF }')

rows=()
label_width=0
for site in "${sites[@]}"; do
  IFS='|' read -r tier kind label target <<<"$site"
  size=$(size_kb "$kind" "$target")
  rows+=("${size:-0}|$tier|$kind|$label|$target")
  (( ${#label} > label_width )) && label_width=${#label}
done
mapfile -t sorted < <(printf '%s\n' "${rows[@]}" | sort -t'|' -k1,1rn)

declare -A totals=([auto]=0 [ask]=0 [note]=0)
declare -A tier_help=(
  [auto]='self-regenerating, swept by --auto'
  [ask]='yours, --ask prompts per site'
  [note]='reported only, needs its own tool'
)

before=$(free_kb)
printf '\ndisk-doctor - %s free on %s\n\n' "$(human "$before")" "$volume"
for row in "${sorted[@]}"; do
  IFS='|' read -r size tier kind label target <<<"$row"
  totals[$tier]=$(( totals[$tier] + size ))
  (( size > 0 )) || continue
  printf '  %-4s %7s  %-*s %s\n' \
    "$tier" "$(human "$size")" "$label_width" "$label" "$(abbrev "$target")"
done

printf '\n'
for tier in auto ask note; do
  printf '  %-4s %7s  %s\n' "$tier" "$(human "${totals[$tier]}")" "${tier_help[$tier]}"
done
printf '\n'

if [ "$mode" = report ]; then exit 0; fi

for row in "${sorted[@]}"; do
  IFS='|' read -r size tier kind label target <<<"$row"
  [ "$tier" = note ] && continue
  (( size > 0 )) || continue
  [ "$mode" = auto ] && [ "$tier" != auto ] && continue
  if [ "$mode" = ask ]; then
    printf '  remove %s (%s)? [y/N] ' "$label" "$(human "$size")"
    answer=
    read -r answer || { echo; break; }  # ^D, or no stdin at all, ends the run
    case "$answer" in [yY]|[yY][eE][sS]) ;; *) continue ;; esac
  else
    printf '  sweeping %s (%s)\n' "$label" "$(human "$size")"
  fi
  sweep "$kind" "$target"
done

after=$(free_kb)
printf '\n  reclaimed %s, %s free\n\n' "$(human $(( after - before )))" "$(human "$after")"
