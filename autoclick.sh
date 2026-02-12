#!/usr/bin/env bash

PIDFILE="/tmp/autoclicker.pid"
INTERVAL="${1:-1}"

if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    kill "$(cat "$PIDFILE")"
    rm "$PIDFILE"
    notify-send "Autoclicker" "Stopped"
else
    (
        while true; do
            ydotool click 0xC0
            sleep "$INTERVAL"
        done
    ) &
    echo $! > "$PIDFILE"
    notify-send "Autoclicker" "Started (${INTERVAL}s interval)"
fi
