#!/bin/bash
<<task
Description:
A simple Bash script implementing a Pomodoro timer with work and break sessions.
Displays a countdown in the terminal and sends desktop notifications when each
session ends, the user quits, or the full cycle completes. Press 'q' during a
session to stop the timer early.
Usage:
./pomodoro.sh [--seconds] <work_time> <rest_time>
Example: ./pomodoro.sh 25 5 (25-minute work, 5-minute break)
         ./pomodoro.sh --seconds 10 300 (10-second work, 300-second break)
task

if [ "$1" = "--total" ]; then
    LOG_FILE="/home/lilkhizzi/Desktop/Project/study_log.txt"
    TODAY=$(date '+%Y-%m-%d')
    TOTAL_MIN=0

    if [ -f "$LOG_FILE" ]; then
        while read -r line; do
            # Only process lines that start with today's date
            if [[ "$line" == "$TODAY"* ]]; then
                # Extract second field (study time in minutes or seconds)
                value=$(echo "$line" | cut -d' ' -f2)
                TOTAL_MIN=$((TOTAL_MIN + value))
            fi
        done < "$LOG_FILE"

        if [ -z "$TOTAL_MIN" ]; then
            TOTAL_MIN=0
        fi

        HOURS=$((TOTAL_MIN / 60))
        MIN=$((TOTAL_MIN % 60))
        echo "Today's study: $HOURS hours, $MIN minutes"
    else
        echo "No study logged today"
    fi
    exit 0
fi

# Check for --seconds flag
unit="minutes"
if [ "$1" = "--seconds" ]; then
    unit="seconds"
    shift
fi

# Get user input for work and rest times
work_time=${1:-25}
rest_time=${2:-5}

# Convert to seconds if in minutes
if [ "$unit" = "minutes" ]; then
    work_sec=$((work_time * 60))
    rest_sec=$((rest_time * 60))
else
    work_sec=$work_time
    rest_sec=$rest_time
fi

LOG_FILE="$HOME/pomodoro_study_log.txt"

countdown() {
    local total_seconds=$1
    local session_type=$2
    while [ $total_seconds -gt 0 ]; do
        mins=$((total_seconds / 60))
        secs=$((total_seconds % 60))
        printf "\r%s Time Remaining: %02d:%02d" "$session_type" $mins $secs

        read -t 1 -n 1 key
        if [[ $key == "q" ]]; then
            echo -e "\n❌ Timer stopped by user."
            notify-send "Pomodoro" "Timer stopped by user." --urgency=normal
            if [ "$session_type" = "Work" ] && [ $total_seconds -lt $1 ]; then
                echo "$(date '+%Y-%m-%d %H:%M:%S'): Studied for $(( ($1 - $total_seconds) )) seconds in work session" >> "$LOG_FILE"
            fi
            return 1
        fi
        sleep 1
        total_seconds=$((total_seconds - 1))
    done
    echo -e "\n⏰ $session_type Time's up!"
    notify-send "Pomodoro" "$session_type Time's up!" --urgency=normal
    if [ "$session_type" = "Work" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S'): Completed $(( $1 ))-second work session" >> "$LOG_FILE"
    fi
}

# Start Pomodoro
echo "======================= 🍅 Pomodoro Timer 🍅 ======================="
echo "================== 📢 Timer started! Stay focused! =================="
echo -e "\n🧠 Work Time: $work_time $unit"
countdown $work_sec "Work"

if [ $? -eq 0 ]; then
    echo -e "\n☕ Break Time: $rest_time $unit"
    countdown $rest_sec "Break"
fi

if [ $? -eq 0 ]; then
    echo -e "\n🎉 ============= Session Complete! Great job! 🥳 ============="
    notify-send "Pomodoro" "Session Complete! Great job!" --urgency=critical
fi
