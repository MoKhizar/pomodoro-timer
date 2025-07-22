# Pomodoro Timer

A simple Bash script implementing a Pomodoro timer for Linux with work and break sessions. It displays a countdown in the terminal, sends desktop notifications, and logs study time.

## Features
- Customizable work and break durations (in minutes or seconds with `--seconds` flag).
- Desktop notifications using `notify-send`.
- Logs completed and interrupted work sessions to a file.
- Displays total study time for the day with `--total` flag.
- Press 'q' to stop the timer early.

## Usage
```bash
./pomodoro.sh <work_minutes> <rest_minutes>
./pomodoro.sh --seconds <work_seconds> <rest_seconds>
./pomodoro.sh --total
