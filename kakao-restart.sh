#!/usr/bin/env bash
set -u

KAKAO_EXE='C:\Program Files\Kakao\KakaoTalk\KakaoTalk.exe'
PATTERN='KakaoTalk\.exe'

# Wine prefix (wineserver -k가 이 prefix의 프로세스를 종료) + 한글 입력용 ibus 환경변수.
# 주의: ibus 데몬(ibus-daemon -drx 등)은 절대 건드리지 말 것 — 시스템 전체 한글 입력이 깨짐.
export WINEPREFIX="${WINEPREFIX:-$HOME/.wine}"
export WINEARCH=win32
export WINEDEBUG=-all
export LANG=ko_KR.UTF-8
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus

WINESERVER=$(command -v wineserver || echo /usr/bin/wineserver)

echo "[*] Killing all Wine processes in prefix ($WINESERVER -k)..."
# 카톡만 죽이는 게 아니라 wineserver를 통째로 종료 — 렌더링 깨짐(검은/짤린 창)은
# 카톡 프로세스만 재시작해선 안 풀리고 Wine 전체 재시작이 필요함.
"$WINESERVER" -k 2>/dev/null || true

for _ in 1 2 3 4 5; do
    sleep 1
    pgrep -f "$PATTERN" >/dev/null || break
done

if pgrep -f "$PATTERN" >/dev/null; then
    echo "[!] Still alive — force killing..."
    kill -9 $(pgrep -f "$PATTERN") 2>/dev/null || true
    sleep 1
fi
echo "[*] Wine terminated."

echo "[*] Launching KakaoTalk..."
cd "$HOME"
nohup wine "$KAKAO_EXE" >/dev/null 2>&1 &
disown

sleep 3
new_pid=$(pgrep -f "$PATTERN" | head -n1 || true)
if [[ -n "$new_pid" ]]; then
    echo "[+] KakaoTalk started (PID: $new_pid)"
else
    echo "[!] KakaoTalk did not appear to start. Check wine logs."
    exit 1
fi
