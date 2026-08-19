#!/usr/bin/env bash
# Keep a sideloaded iOS app signed. One invocation checks one app.
#
# Usage: ios-sideload-refresh --bundle-id ID --workdir DIR [--device NAME] [--launch true|false]
#                             -- CMD...
# CMD is run with the resolved UDID appended, so a CMD ending in a flag receives it as that
# flag's value.
#        ios-sideload-refresh --bundle-id ID --status
#   --renew-days N   act when fewer than N days remain (default 3)
#   -v               explain the decision instead of staying quiet
#
# Free provisioning profiles carry TimeToLive=7 and the app stops launching the moment the
# embedded one expires, so anything installed off a personal team needs re-signing weekly.
# This is the scheduling half: it decides *whether* to act. CMD is the app's own installer
# and owns the build, so each repo keeps its own toolchain quirks to itself.
#
# Built to be woken every few minutes and do nothing nearly every time. Two guards run ahead of
# anything expensive — the recorded expiry, then a ~0.4s lock-state probe. Silence means the
# app is fine; output means something happened.
#
# The lock state matters twice, differently: installing needs the phone to have been unlocked at
# some point since boot, while *launching* needs it unlocked right now. So an install can land on
# a locked phone and the launch it owes is deferred to a wake-up that finds the screen open.
set -euo pipefail
shopt -s nullglob

BUNDLE_ID=""
WORKDIR=""
DEVICE=""
LAUNCH=0
RENEW_DAYS=3
VERBOSE=0
STATUS_ONLY=0

# Value-taking flags come through here, so a trailing bare flag names itself instead of dying
# in bash's shift with "shift count out of range".
need_val() { (( $# >= 2 )) || { printf '%s needs a value\n' "$1" >&2; exit 2; }; }

while (( $# )); do
    case "$1" in
        --bundle-id)  need_val "$@"; BUNDLE_ID="$2"; shift 2 ;;
        --workdir)    need_val "$@"; WORKDIR="$2"; shift 2 ;;
        --device)     need_val "$@"; DEVICE="$2"; shift 2 ;;
        --launch)
            need_val "$@"
            case "$2" in
                true)  LAUNCH=1 ;;
                false) LAUNCH=0 ;;
                *) printf -- '--launch takes true or false\n' >&2; exit 2 ;;
            esac
            shift 2 ;;
        --renew-days)
            need_val "$@"
            # Unvalidated, a non-number reads as an unset variable — i.e. 0 — and silently
            # turns the expiry guard into "always fresh".
            [[ "$2" =~ ^[0-9]+$ ]] || { printf -- '--renew-days takes a number\n' >&2; exit 2; }
            RENEW_DAYS="$2"; shift 2 ;;
        --status)     STATUS_ONLY=1; shift ;;
        -v|--verbose) VERBOSE=1; shift ;;
        --) shift; break ;;
        *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2 ;;
    esac
done

[[ -n "$BUNDLE_ID" ]] || { printf -- '--bundle-id is required\n' >&2; exit 2; }

STATE_DIR="$HOME/Library/Application Support/ios-sideload-refresh"
STATE="$STATE_DIR/$BUNDLE_ID"
# An install owes a launch. Recorded as its own file so the debt survives until it is settled.
PENDING="$STATE_DIR/$BUNDLE_ID.launch-pending"
NOTIFIED="$STATE_DIR/$BUNDLE_ID.last-notified"
LOCK="${TMPDIR:-/tmp}/ios-sideload-refresh-$BUNDLE_ID.lock"
PROFILE_DIRS=(
    "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
    "$HOME/Library/MobileDevice/Provisioning Profiles"
)

log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }
say() { if (( VERBOSE )); then log "$@"; fi; }

# One alarm per NOTIFY_EVERY, because the failure that needs a human is exactly the one that
# persists: unthrottled, a signed-out Xcode would chime on every wake-up for days.
NOTIFY_EVERY=21600
notify() {
    local now last=0
    now=$(date +%s)
    if [[ -f "$NOTIFIED" ]]; then
        last=$(<"$NOTIFIED")
        [[ "$last" =~ ^[0-9]+$ ]] || last=0
    fi
    if (( now - last < NOTIFY_EVERY )); then
        return 0
    fi
    mkdir -p "$STATE_DIR"
    printf '%s\n' "$now" >"$NOTIFIED"
    osascript -e "display notification \"$1\" with title \"Sideload refresh\"" >/dev/null 2>&1 || true
}

# Expiry of the Xcode-managed profile for this bundle id. Read only just after a successful
# install, when the cache is by definition what went onto the phone.
# Xcode can leave several profiles for one bundle id, so the first match is not necessarily the
# one the app embeds. All free profiles run 7 days from minting, which makes the newest also the
# last to expire — take the maximum, and never stamp an expiry earlier than what is installed.
cached_expiry() {
    local dir f plist appid exp
    local -a found=()
    for dir in "${PROFILE_DIRS[@]}"; do
        [[ -d "$dir" ]] || continue
        for f in "$dir"/*.mobileprovision; do
            plist=$(security cms -D -i "$f" 2>/dev/null) || continue
            appid=$(printf '%s' "$plist" | plutil -extract Entitlements.application-identifier raw -o - - 2>/dev/null) || continue
            [[ "$appid" == *".$BUNDLE_ID" ]] || continue
            exp=$(printf '%s' "$plist" | plutil -extract ExpirationDate raw -o - - 2>/dev/null) || continue
            found+=("$exp")
        done
    done
    (( ${#found[@]} )) || return 1
    # Fixed-width ISO 8601, so lexicographic order is chronological. tail, not head, because it
    # drains the pipe: `sort | head -1` can leave sort killed by SIGPIPE, which pipefail reports
    # as a failed pipeline.
    printf '%s\n' "${found[@]}" | sort | tail -n 1
}

# Days until the installed signature dies. Fails when nothing has been recorded yet.
days_left() {
    local expires epoch now
    [[ -f "$STATE" ]] || return 1
    expires=$(<"$STATE")
    epoch=$(TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%SZ" "$expires" +%s 2>/dev/null) || return 1
    now=$(date +%s)
    printf '%s\n' "$(( (epoch - now) / 86400 ))"
}

# Prints "locked" or "unlocked"; fails when the device is unreachable or has not been unlocked
# since boot. That last case matters: installing needs the pairing tunnel, and iOS withholds it
# until the passcode has been entered once — while a plain reachability probe still answers, so
# only this tells a rebooted phone apart from a usable one.
lock_state() {
    local json unlocked passcode
    json=$(mktemp "${TMPDIR:-/tmp}/ios-sideload-lock.XXXXXX")
    if ! xcrun devicectl device info lockState --device "$1" --json-output "$json" >/dev/null 2>&1; then
        rm -f "$json"
        return 1
    fi
    unlocked=$(plutil -extract result.unlockedSinceBoot raw -o - "$json" 2>/dev/null) || true
    passcode=$(plutil -extract result.passcodeRequired raw -o - "$json" 2>/dev/null) || true
    rm -f "$json"
    [[ "$unlocked" == "true" ]] || return 1
    if [[ "$passcode" == "true" ]]; then printf 'locked\n'; else printf 'unlocked\n'; fi
}

# --no-activate: the app only has to *run* for CoreBluetooth to re-register its restoration
# identifier, so a refresh has no business shoving it in front of whatever the phone is doing.
# devicectl's exit code is unreliable here — it has returned 0 on a refused launch — but with -q
# a real launch is byte-silent, so output is the signal.
try_launch() {
    local out
    out=$(xcrun devicectl device process launch -q --no-activate --device "$1" "$BUNDLE_ID" 2>&1) || true
    [[ -z "$out" ]]
}

UDID_PAT='00[0-9A-Fa-f]{6}-[0-9A-Fa-f]{16}'

# devicectl exits 0 on no match, and Apple documents --json-output as the only supported
# interface for scripts — so matches get read out of the JSON, not the table.
device_udids() {
    local json
    json=$(mktemp "${TMPDIR:-/tmp}/ios-sideload-devices.XXXXXX")
    xcrun devicectl list devices --filter "$1" --json-output "$json" >/dev/null 2>&1 || true
    grep -oE "\"udid\" *: *\"$UDID_PAT\"" "$json" 2>/dev/null | grep -oE "$UDID_PAT" || true
    rm -f "$json"
}

resolve_udid() {
    local filter
    local -a matches=()
    filter="hardwareProperties.platform == 'iOS' AND connectionProperties.pairingState == 'paired'"
    # Double-quoted literal so names with apostrophes survive ("Changsheng's iPad").
    if [[ -n "$DEVICE" ]]; then
        filter="$filter AND deviceProperties.name == \"${DEVICE//\"/\\\"}\""
    fi
    mapfile -t matches < <(device_udids "$filter")
    (( ${#matches[@]} == 1 )) || return 1
    printf '%s\n' "${matches[0]}"
}

if (( STATUS_ONLY )); then
    if left=$(days_left); then
        printf '%s: %sd left (expires %s)\n' "$BUNDLE_ID" "$left" "$(<"$STATE")"
    else
        printf '%s: unknown — nothing recorded yet\n' "$BUNDLE_ID"
    fi
    if (( LAUNCH )) && [[ -f "$PENDING" ]]; then
        printf '%s: installed but not launched yet — waiting for an unlocked device\n' "$BUNDLE_ID"
    fi
    exit 0
fi

[[ -n "$WORKDIR" ]] || { printf -- '--workdir is required\n' >&2; exit 2; }
(( $# )) || { printf 'an install command is required after --\n' >&2; exit 2; }

# Sweep a lock orphaned by a kill -9, then claim it; mkdir is the atomic primitive.
# The trailing `|| true` is load-bearing under errexit: a concurrent agent can sweep the same
# orphaned lock between the age check and the rmdir, and losing that race must not be fatal.
[[ -d "$LOCK" ]] && [[ -z "$(find "$LOCK" -maxdepth 0 -mmin -30 2>/dev/null)" ]] && rmdir "$LOCK" 2>/dev/null || true
if ! mkdir "$LOCK" 2>/dev/null; then
    say "Another refresh of $BUNDLE_ID holds the lock — skipping."
    exit 0
fi
trap 'rmdir "$LOCK" 2>/dev/null || true' EXIT
# launchd SIGTERMs jobs at logout and on reload. Without these the shell dies without running the
# EXIT trap, and the orphan blocks every refresh until the 30-minute sweep above clears it.
trap 'exit 143' TERM
trap 'exit 130' INT

# Nothing owed and nothing expiring: leave without touching the device at all. This is the
# overwhelmingly common case, and keeping it free is what lets the agent run every few minutes.
OWES_LAUNCH=0
if (( LAUNCH )) && [[ -f "$PENDING" ]]; then
    OWES_LAUNCH=1
fi
if (( ! OWES_LAUNCH )) && left=$(days_left) && (( left >= RENEW_DAYS )); then
    say "$BUNDLE_ID good for ${left}d — nothing to do."
    exit 0
fi

if ! UDID=$(resolve_udid); then
    say "No single paired device${DEVICE:+ named $DEVICE} — skipping."
    exit 0
fi
# ~0.4s, against a build that would otherwise run for minutes before failing.
if ! SCREEN=$(lock_state "$UDID"); then
    say "${DEVICE:-$UDID} unreachable or not unlocked since boot — trying again next wake-up."
    exit 0
fi

# A good signature leaves only one possible job: settling a launch owed by an earlier install —
# the fast path returns when nothing is owed. Nothing launches while the screen is locked, not
# even into the background, so the debt waits for a wake-up that finds the screen open.
if left=$(days_left) && (( left >= RENEW_DAYS )); then
    if [[ "$SCREEN" == locked ]]; then
        say "$BUNDLE_ID owes a launch, ${DEVICE:-$UDID} is locked — trying again next wake-up."
    elif try_launch "$UDID"; then
        rm -f "$PENDING"
        log "$BUNDLE_ID launched — it runs in the background again."
    else
        # Best-effort: the lock probe is a snapshot, so the screen can close again before the
        # launch lands. Losing that race is ordinary, not a failure worth logging every wake-up.
        say "$BUNDLE_ID launch was refused — trying again next wake-up."
    fi
    exit 0
fi

log "$BUNDLE_ID is ${left:-?}d from expiry and ${DEVICE:-$UDID} is reachable — refreshing."
# Hand down the UDID already resolved above, so the installer needs no device argument of its own
# and does not repeat the lookup.
cmd=("$@" "$UDID")
if out=$(cd "$WORKDIR" && "${cmd[@]}" 2>&1); then
    mkdir -p "$STATE_DIR"
    # A success clears the throttle, so the next genuine failure alarms at once.
    rm -f "$NOTIFIED"
    # Reinstalling wipes the preserved CoreBluetooth state, so iOS will not relaunch the app on
    # its own until it has run once. Record the debt unconditionally and settle it here, so a
    # phone that locks mid-install still gets caught on a later wake-up.
    if (( LAUNCH )); then
        : > "$PENDING"
        if [[ "$SCREEN" != locked ]] && try_launch "$UDID"; then
            rm -f "$PENDING"
        else
            log "$BUNDLE_ID installed — launch owed, retried on later wake-ups."
        fi
    fi
    if expiry=$(cached_expiry); then
        printf '%s\n' "$expiry" >"$STATE"
        log "$BUNDLE_ID installed — signing valid until $expiry."
    else
        # Installed, but the expiry is unreadable. Leave no stamp and re-check next wake-up
        # rather than record a guess that would suppress the next refresh.
        log "$BUNDLE_ID installed, but its profile expiry could not be read."
    fi
else
    # The lock probe only describes the instant it ran. A build takes minutes, and the phone can
    # be picked up and carried off Wi-Fi inside that window, so the device conditions we screened
    # for can all come back at install time. Those are retries, not faults: no log, no alarm.
    case "$out" in
        *"unable to locate a device"*|*"not been unlocked recently"*|*"still locked"*|*"not reachable"*)
            # Logged, not whispered: the "refreshing" line above is already in the log, and an
            # opening with no outcome reads as success. Quiet applies to the alarm, not the record.
            log "$BUNDLE_ID refresh abandoned — ${DEVICE:-$UDID} left mid-install; retrying next wake-up."
            exit 0 ;;
    esac
    log "$BUNDLE_ID refresh failed:"
    printf '%s\n' "$out"
    # Separate the one failure a human must clear from those that fix themselves: minting a
    # profile needs a live Apple ID session, and 2FA cannot be scripted.
    case "$out" in
        *"error: No Accounts"*|*"no signed-in Apple ID"*)
            notify "Xcode is signed out — sign in to keep $BUNDLE_ID installed." ;;
        *)  notify "Refresh of $BUNDLE_ID failed — see the log." ;;
    esac
    exit 1
fi
