#!/bin/bash
# Launch KakaoTalk under Wine (32-bit prefix) with working Korean input.
#
# Korean input requires the launcher's IME env vars to match the SYSTEM IME (ibus).
# Do NOT switch these to fcitx — KakaoTalk's input will break.
# See README.md → Troubleshooting if Korean still doesn't work.

export WINEPREFIX="${WINEPREFIX:-$HOME/.wine}"
export WINEARCH=win32
export WINEDEBUG=-all
export LANG=ko_KR.UTF-8

export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus

exec wine "$WINEPREFIX/drive_c/Program Files/Kakao/KakaoTalk/KakaoTalk.exe"
