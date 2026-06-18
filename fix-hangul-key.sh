#!/bin/bash
# Fix the SYSTEM-WIDE 한영(Hangul/English) toggle key for ibus-hangul on Ubuntu/GNOME.
#
# Symptom this fixes: the 한영 key (Right Alt) does nothing ANYWHERE — not just in
# KakaoTalk. Even native apps (Firefox, terminal) stay stuck in English.
# (If only KakaoTalk fails but other apps are fine, this is NOT your problem —
#  see README.md → "트러블슈팅 — 한글 입력이 안 될 때" instead.)
#
# Root cause seen on Ubuntu 24.04 / ibus-hangul 1.5.5: the engine's `switch-keys`
# value got corrupted into a list-shaped string the engine cannot parse, e.g.
#     ['Hangul', 'Shift+space'],Alt_R
# so NO key toggles 한/영. Made worse because the GLOBAL ibus trigger ALSO bound
# `Hangul` (stealing the key before the engine sees it) while the engine starts in
# latin mode — leaving you permanently in English.
#
# Fix: restore a valid switch-keys string and let the engine own the 한/영 toggle.
#
# Note: this assumes Right Alt already emits the `Hangul` keysym. On the `kr` layout
# set it once with:  gsettings set org.gnome.desktop.input-sources xkb-options "['korean:ralt_hangul']"
set -euo pipefail

if ! command -v gsettings >/dev/null 2>&1; then
  echo "ERROR: gsettings not found (this script targets GNOME/ibus)."; exit 1
fi

BK="$HOME/ibus-hangul-backup.txt"
{
  echo "switch-keys=$(gsettings get org.freedesktop.ibus.engine.hangul switch-keys)"
  echo "triggers=$(gsettings get org.freedesktop.ibus.general.hotkey triggers)"
} > "$BK"
echo "==> Backed up current values to $BK"

# 1) valid 한/영 switch key — a comma-separated string, NOT a python-style list
gsettings set org.freedesktop.ibus.engine.hangul switch-keys 'Hangul,Shift+space'
# 2) drop Hangul from the GLOBAL trigger so the key reaches the engine; keep Super+space
gsettings set org.freedesktop.ibus.general.hotkey triggers "['<Super>space']"

echo "    switch-keys -> $(gsettings get org.freedesktop.ibus.engine.hangul switch-keys)"
echo "    triggers    -> $(gsettings get org.freedesktop.ibus.general.hotkey triggers)"

# apply (config changes need a daemon restart to take effect)
echo "==> Restarting ibus"
ibus restart 2>/dev/null || ibus-daemon -drxR &
sleep 1

echo
echo "Done. Press Right Alt (한영) in any text field to toggle 한/영."
echo "If it still fails, log out and back in — running apps hold the old ibus connection."
echo "Revert anytime with the values saved in $BK."
