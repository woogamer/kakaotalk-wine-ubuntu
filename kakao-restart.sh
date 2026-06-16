#!/bin/bash
# Restart KakaoTalk cleanly.
#
# A process-only restart (killing just KakaoTalk.exe) does NOT recover the
# black/clipped/unmapped window glitch. Killing the whole Wine session with
# `wineserver -k` and relaunching does.
#
# IMPORTANT: never touch the ibus daemon here. No `ibus-daemon -drx`, no
# `ibus exit`, no fcitx — those break Korean input system-wide in every other
# running app (terminals, browser, ...). `wineserver -k` leaves ibus untouched.

export WINEPREFIX="${WINEPREFIX:-$HOME/.wine}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

wineserver -k
setsid "$SCRIPT_DIR/kakaotalk.sh" </dev/null >/tmp/kakaotalk.log 2>&1 & disown
echo "KakaoTalk restarting (log: /tmp/kakaotalk.log)"
