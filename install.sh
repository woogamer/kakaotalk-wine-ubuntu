#!/bin/bash
# Install KakaoTalk on Ubuntu under a 32-bit Wine prefix, with Korean fonts.
# Verified on: Ubuntu 24.04.4 LTS (Noble), Wine 11.0 stable, ibus 1.5.29.
#
# This script does NOT bundle or download the KakaoTalk installer (proprietary).
# Obtain "KakaoTalk_Setup.exe" yourself from Kakao's official PC download page,
# then either place it next to this script or pass its path:
#     KAKAO_SETUP=/path/to/KakaoTalk_Setup.exe ./install.sh
set -euo pipefail

export WINEPREFIX="${WINEPREFIX:-$HOME/.wine}"
export WINEARCH=win32
export WINEDEBUG=-all

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KAKAO_SETUP="${KAKAO_SETUP:-$SCRIPT_DIR/KakaoTalk_Setup.exe}"

if ! command -v wine >/dev/null 2>&1; then
  echo "ERROR: wine not found. Install WineHQ stable first: https://wiki.winehq.org/Ubuntu"
  exit 1
fi

if [ ! -f "$KAKAO_SETUP" ]; then
  echo "ERROR: KakaoTalk_Setup.exe not found at: $KAKAO_SETUP"
  echo "  Download the PC version from Kakao's official site and place it there,"
  echo "  or run:  KAKAO_SETUP=/path/to/KakaoTalk_Setup.exe ./install.sh"
  exit 1
fi

echo "==> 1/5  Korean locale (ko_KR.UTF-8)"
# Missing ko_KR.UTF-8 is the #1 cause of broken Hangul input — Wine falls back to
# the C locale and can only compose ASCII. locale-gen is permanent (survives reboot).
if ! locale -a 2>/dev/null | grep -qi '^ko_KR\.utf8$'; then
  sudo locale-gen ko_KR.UTF-8
fi

echo "==> 2/5  Packages (i386 arch, Nanum fonts, winetricks)"
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install -y --install-recommends fonts-nanum winetricks

echo "==> 3/5  Create 32-bit Wine prefix at $WINEPREFIX"
wineboot --init
wineserver -w

echo "==> 4/5  Nanum fonts + registry substitutes"
mkdir -p "$WINEPREFIX/drive_c/windows/Fonts"
cp /usr/share/fonts/truetype/nanum/NanumGothic*.ttf "$WINEPREFIX/drive_c/windows/Fonts/" 2>/dev/null || true
wine regedit "$SCRIPT_DIR/nanum_font.reg"

echo "==> 5/5  Silent install KakaoTalk ( /S required — GUI installer fails under Wine )"
wine "$KAKAO_SETUP" /S || true
wineserver -w

echo
echo "Done. Launch with:  $SCRIPT_DIR/kakaotalk.sh"
echo "If Korean input still doesn't work, see README.md -> Troubleshooting."
