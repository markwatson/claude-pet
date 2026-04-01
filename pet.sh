#!/usr/bin/env bash
# Virtual pet that lives in the Claude Code status line
# Mood reflects how often you use Claude Code — active usage keeps him happy.

STATE="$HOME/.claude/pet.state"
now=$(date +%s)
today=$(date +%Y-%m-%d)
hour=$(date +%H)

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
