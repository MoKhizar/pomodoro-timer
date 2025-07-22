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
    if [ -f "$LOG_FILE" ]; then
        TOTAL_MIN=$(grep "$TODAY" "$LOG_FILE" | awk '{sum += $2} END {print sum}')
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

# Validate inputs are positive integers
if ! [[ "$work_time" =~ ^[0-9]+$ ]] || ! [[ "$rest_time" =~ ^[0-9]+$ ]] || [ "$work_time" -le 0 ] || [ "$rest_time" -le 0 ]; then
    echo "Error: Inputs must be positive integers."
    exit 1
fi

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
