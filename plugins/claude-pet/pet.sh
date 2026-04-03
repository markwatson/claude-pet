#!/usr/bin/env bash
# Virtual pet that lives in the Claude Code status line
# Mood reflects how often you use Claude Code — active usage keeps him happy.

STATE="$HOME/.claude/pet.state"
LOCKFILE="$HOME/.claude/pet.lock"
now=$(date +%s)
today=$(date +%Y-%m-%d)
hour=$(date +%H)

# Portable file locking: flock (Linux) with mkdir fallback (macOS/portable)
# Usage: acquire_lock / release_lock
if command -v flock >/dev/null 2>&1; then
    acquire_lock() {
        exec 9>"$LOCKFILE"
        flock -w 5 9
    }
    release_lock() {
        flock -u 9
        exec 9>&-
    }
else
    # mkdir is atomic on all POSIX systems — perfect as a spinlock
    acquire_lock() {
        local attempts=0
        while ! mkdir "$LOCKFILE.d" 2>/dev/null; do
            attempts=$(( attempts + 1 ))
            if [ "$attempts" -ge 50 ]; then
                # Stale lock safety: remove if older than 10s
                if [ -d "$LOCKFILE.d" ]; then
                    local lock_age
                    lock_age=$(( $(date +%s) - $(stat -f %m "$LOCKFILE.d" 2>/dev/null || stat -c %Y "$LOCKFILE.d" 2>/dev/null || echo 0) ))
                    if [ "$lock_age" -gt 10 ]; then
                        rmdir "$LOCKFILE.d" 2>/dev/null
                        attempts=0
                        continue
                    fi
                fi
                return 1
            fi
            sleep 0.1
        done
    }
    release_lock() {
        rmdir "$LOCKFILE.d" 2>/dev/null
    }
fi

# --- Lock, read state, update, write, unlock ---
acquire_lock || { echo "pet: could not acquire lock" >&2; exit 1; }

# Defaults
name=Buddy
born=$now
total_sessions=1
last_fed=$now
streak=1
last_session_date=$today
decay_hours=72

# Load state if it exists
if [ -f "$STATE" ]; then
    while IFS='=' read -r key val; do
        case "$key" in
            name) name=$val ;;
            born) born=$val ;;
            total_sessions) total_sessions=$val ;;
            last_fed) last_fed=$val ;;
            streak) streak=$val ;;
            last_session_date) last_session_date=$val ;;
            decay_hours) decay_hours=$val ;;
        esac
    done < "$STATE"
fi

# Hours since last fed
seconds_away=$(( now - last_fed ))
hours_away=$(( seconds_away / 3600 ))

# Update streak and sessions on new day
if [ "$today" != "$last_session_date" ]; then
    total_sessions=$(( total_sessions + 1 ))
    # Get yesterday's date (try BSD then GNU)
    yesterday=$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d "yesterday" +%Y-%m-%d 2>/dev/null)
    if [ "$last_session_date" = "$yesterday" ]; then
        streak=$(( streak + 1 ))
    else
        streak=1
    fi
    last_session_date=$today
fi

# Update last_fed
last_fed=$now

# Save state
cat > "$STATE" <<EOF
name=$name
born=$born
total_sessions=$total_sessions
last_fed=$last_fed
streak=$streak
last_session_date=$last_session_date
decay_hours=$decay_hours
EOF

release_lock

# Mood thresholds (integer hours, fractions of decay_hours)
t_happy=$(( decay_hours * 17 / 100 ))
t_content=$(( decay_hours * 33 / 100 ))
t_bored=$(( decay_hours * 50 / 100 ))
t_sad=$(( decay_hours * 75 / 100 ))

# Determine mood
hour10=$((10#$hour))
if [ "$hour10" -ge 23 ] || [ "$hour10" -le 4 ]; then
    mood=sleepy
elif [ "$total_sessions" -gt 0 ] && [ "$streak" -ge 5 ] && [ "$hours_away" -lt 1 ]; then
    mood=ecstatic
elif [ "$hours_away" -lt "$t_happy" ]; then
    mood=happy
elif [ "$hours_away" -lt "$t_content" ]; then
    mood=content
elif [ "$hours_away" -lt "$t_bored" ]; then
    mood=bored
elif [ "$hours_away" -lt "$t_sad" ]; then
    mood=sad
else
    mood=desperate
fi

# Color
case "$mood" in
    ecstatic)  color="0;35" ;;
    happy)     color="0;32" ;;
    content)   color="0;36" ;;
    sleepy)    color="0;34" ;;
    bored)     color="0;33" ;;
    sad)       color="0;31" ;;
    desperate) color="1;31" ;;
esac

printf "\033[${color}m🐕 %s [%s]\033[00m" "$name" "$mood"
