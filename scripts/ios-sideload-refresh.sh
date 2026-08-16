#!/bin/zsh
# Keep a sideloaded iOS app signed. One invocation checks one app.
#
# Usage: ios-sideload-refresh --bundle-id ID --workdir DIR [--device NAME] -- CMD...
#        ios-sideload-refresh --bundle-id ID --status
#   --renew-days N   act when fewer than N days remain (default 3)
#   -v               explain the decision instead of staying quiet
#
# Free provisioning profiles carry TimeToLive=7 and the app stops launching the moment the
# embedded one expires, so anything installed off a personal team needs re-signing weekly.
# This is the scheduling half: it decides *whether* to act. CMD is the app's own installer
# and owns the build, so each repo keeps its own toolchain quirks to itself.
#
# Built to be woken every few hours and do nothing nearly every time. Two guards run ahead of
# anything expensive — the recorded expiry, then a ~2s reachability probe. Silence means the
# app is fine; output means something happened.
set -euo pipefail

BUNDLE_ID=""
WORKDIR=""
DEVICE=""
RENEW_DAYS=3
VERBOSE=0
STATUS_ONLY=0

while (( $# )); do
    case "$1" in
        --bundle-id)  BUNDLE_ID="$2"; shift 2 ;;
        --workdir)    WORKDIR="$2"; shift 2 ;;
        --device)     DEVICE="$2"; shift 2 ;;
        --renew-days) RENEW_DAYS="$2"; shift 2 ;;
        --status)     STATUS_ONLY=1; shift ;;
        -v|--verbose) VERBOSE=1; shift ;;
        --) shift; break ;;
        *) print -r -- "Unknown argument: $1" >&2; exit 2 ;;
    esac
done

[[ -n "$BUNDLE_ID" ]] || { print -r -- "--bundle-id is required" >&2; exit 2 }

STATE_DIR="$HOME/Library/Application Support/ios-sideload-refresh"
STATE="$STATE_DIR/$BUNDLE_ID"
LOCK="${TMPDIR:-/tmp}/ios-sideload-refresh-$BUNDLE_ID.lock"
PROFILE_DIRS=(
    "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
    "$HOME/Library/MobileDevice/Provisioning Profiles"
)

log()    { print -r -- "$(date '+%Y-%m-%d %H:%M:%S') $*" }
say()    { (( VERBOSE )) && log "$@"; return 0 }
notify() { osascript -e "display notification \"$1\" with title \"Sideload refresh\"" >/dev/null 2>&1 || true }

# Expiry of the Xcode-managed profile for this bundle id. Read only just after a successful
# install, when the cache is by definition what went onto the phone.
cached_expiry() {
    local dir f plist appid
    for dir in "${PROFILE_DIRS[@]}"; do
        [[ -d "$dir" ]] || continue
        for f in "$dir"/*.mobileprovision(N); do
            plist=$(security cms -D -i "$f" 2>/dev/null) || continue
            appid=$(print -r -- "$plist" | plutil -extract Entitlements.application-identifier raw -o - - 2>/dev/null) || continue
            [[ "$appid" == *".$BUNDLE_ID" ]] || continue
            print -r -- "$plist" | plutil -extract ExpirationDate raw -o - - 2>/dev/null && return 0
        done
    done
    return 1
}

# Days until the installed signature dies. Fails when nothing has been recorded yet.
days_left() {
    local expires epoch
    [[ -f "$STATE" ]] || return 1
    expires="$(<"$STATE")"
    epoch=$(TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%SZ" "$expires" +%s 2>/dev/null) || return 1
    print -r -- $(( (epoch - $(date +%s)) / 86400 ))
}

UDID_PAT='00[0-9A-Fa-f]{6}-[0-9A-Fa-f]{16}'

# devicectl exits 0 on no match, and Apple documents --json-output as the only supported
# interface for scripts — so matches get read out of the JSON, not the table.
device_udids() {
    local json="${TMPDIR:-/tmp}/ios-sideload-devices-$$.json"
    xcrun devicectl list devices --filter "$1" --json-output "$json" >/dev/null 2>&1 || true
    grep -oE "\"udid\" *: *\"$UDID_PAT\"" "$json" 2>/dev/null | grep -oE "$UDID_PAT" || true
    rm -f "$json"
}

resolve_udid() {
    local filter matches
    filter="hardwareProperties.platform == 'iOS' AND connectionProperties.pairingState == 'paired'"
    # Double-quoted literal so names with apostrophes survive ("Changsheng's iPad").
    [[ -n "$DEVICE" ]] && filter="$filter AND deviceProperties.name == \"${DEVICE//\"/\\\"}\""
    matches=(${(f)"$(device_udids "$filter")"}); matches=(${matches:#})
    (( ${#matches} == 1 )) || return 1
    print -r -- "${matches[1]}"
}

if (( STATUS_ONLY )); then
    if left=$(days_left); then
        print -r -- "$BUNDLE_ID: ${left}d left (expires $(<"$STATE"))"
    else
        print -r -- "$BUNDLE_ID: unknown — nothing recorded yet"
    fi
    exit 0
fi

[[ -n "$WORKDIR" ]] || { print -r -- "--workdir is required" >&2; exit 2 }
(( $# )) || { print -r -- "an install command is required after --" >&2; exit 2 }

# Sweep a lock orphaned by a kill -9, then claim it; mkdir is the atomic primitive.
[[ -d "$LOCK" ]] && [[ -z "$(find "$LOCK" -maxdepth 0 -mmin -30 2>/dev/null)" ]] && rmdir "$LOCK" 2>/dev/null
if ! mkdir "$LOCK" 2>/dev/null; then
    say "Another refresh of $BUNDLE_ID holds the lock — skipping."
    exit 0
fi
trap 'rmdir "$LOCK" 2>/dev/null || true' EXIT

if left=$(days_left) && (( left >= RENEW_DAYS )); then
    say "$BUNDLE_ID good for ${left}d — nothing to do."
    exit 0
fi

if ! UDID=$(resolve_udid); then
    say "No single paired device${DEVICE:+ named $DEVICE} — skipping."
    exit 0
fi
# ~2s, against a build that would otherwise run for minutes before failing.
if ! xcrun devicectl device info details --device "$UDID" >/dev/null 2>&1; then
    say "${DEVICE:-$UDID} unreachable — trying again next wake-up."
    exit 0
fi

log "$BUNDLE_ID is ${left:-?}d from expiry and ${DEVICE:-$UDID} is reachable — refreshing."
if out=$(cd "$WORKDIR" && "$@" 2>&1); then
    if expiry=$(cached_expiry); then
        mkdir -p "$STATE_DIR" && print -r -- "$expiry" >"$STATE"
        log "$BUNDLE_ID installed — signing valid until $expiry."
    else
        # Installed, but the expiry is unreadable. Leave no stamp and re-check next wake-up
        # rather than record a guess that would suppress the next refresh.
        log "$BUNDLE_ID installed, but its profile expiry could not be read."
    fi
else
    log "$BUNDLE_ID refresh failed:"
    print -r -- "$out"
    # Separate the one failure a human must clear from those that fix themselves: minting a
    # profile needs a live Apple ID session, and 2FA cannot be scripted.
    if print -r -- "$out" | grep -qE 'error: No Accounts|no signed-in Apple ID'; then
        notify "Xcode is signed out — sign in to keep $BUNDLE_ID installed."
    else
        notify "Refresh of $BUNDLE_ID failed — see the log."
    fi
    exit 1
fi
