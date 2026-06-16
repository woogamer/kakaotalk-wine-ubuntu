# KakaoTalk on Ubuntu (Wine) — with working Korean input

Run the Windows **KakaoTalk** desktop client on Ubuntu under Wine, including
**Hangul (Korean) input that actually works** in chat windows.

There is no official Linux client, so Wine is the only path. The hard part isn't
running KakaoTalk — it's getting Korean input to compose inside the chat box.
This repo packages a working setup plus the root-cause notes for the input
problems, which most guides get wrong.

Verified on **Ubuntu 24.04.4 LTS (Noble), Wine 11.0 stable, ibus 1.5.29 + ibus-hangul 1.5.5**, 32-bit prefix.

> **Note on the installer:** This repo does **not** include `KakaoTalk_Setup.exe`.
> It is Kakao's proprietary software. Download the PC version from Kakao's
> official site yourself, then point the installer at it.

## Quick start

```bash
# 0. Install WineHQ stable first:  https://wiki.winehq.org/Ubuntu
# 1. Get KakaoTalk_Setup.exe (PC version) from Kakao's official site,
#    drop it in this folder (or pass KAKAO_SETUP=/path/to/it).
git clone https://github.com/woogamer/kakaotalk-wine-ubuntu.git
cd kakaotalk-wine-ubuntu
chmod +x install.sh kakaotalk.sh kakao-restart.sh

./install.sh        # creates a 32-bit prefix, fonts, ko_KR locale, silent install
./kakaotalk.sh      # launch
```

`install.sh` uses `$HOME/.wine` by default. Override with `WINEPREFIX=...` if you
want a dedicated prefix.

## Files

| File | Purpose |
|------|---------|
| `install.sh` | One-shot install: `ko_KR.UTF-8` locale, 32-bit prefix, Nanum fonts, silent install |
| `kakaotalk.sh` | Launcher with the **ibus** IME env vars Korean input needs |
| `kakao-restart.sh` | Clean restart (`wineserver -k` + relaunch) for the black/clipped window glitch |
| `nanum_font.reg` | Font substitution so Korean renders instead of tofu boxes |

## Why a 32-bit prefix

`WINEARCH=win32`. A 64-bit prefix breaks input entirely in testing (see matrix
below). Install the .exe **silently** with `/S` — the GUI installer fails under
Wine.

## Troubleshooting — Korean input doesn't work

This is the part people get stuck on. If the system IME (ibus + ibus-hangul)
works everywhere else but KakaoTalk only types English, **the cause is almost
always one of these two — check them before touching ibus/fcitx at all:**

**1. Missing `ko_KR.UTF-8` locale (the usual culprit).**
   - Symptom: `locale -a | grep ko_KR` prints nothing; `LANG=ko_KR.UTF-8 locale`
     errors with "Cannot set LC_CTYPE". The launcher forces `LANG=ko_KR.UTF-8`,
     but with no such locale Wine falls back to the C locale and can't compose Hangul.
   - Fix: `sudo locale-gen ko_KR.UTF-8` (permanent, survives reboot).

**2. Leftover Wine `InputStyle=root` from past experiments.**
   - Fix — restore the default:
     ```bash
     WINEPREFIX="$HOME/.wine" wine reg delete \
       "HKCU\\Software\\Wine\\X11 Driver" /v InputStyle /f
     ```

After either fix: `wineserver -k`, then relaunch `./kakaotalk.sh`.

> **Do not** restart the ibus daemon (`ibus-daemon -drx`, `ibus exit`) or switch
> to fcitx to "fix" this. Those break Korean input **system-wide** in every other
> running app and were never the actual cause.

### The launcher must use ibus env vars

The system IME here is **ibus**. The launcher exports:

```bash
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
```

If you run KakaoTalk with fcitx env vars while the system runs ibus, input fails
inside KakaoTalk. Keep these as `ibus`.

## Black / clipped / invisible window after restart

Wine sometimes leaves the main window minimized to tray (unmapped) or partially
repainted (black/clipped). Restarting **just the KakaoTalk process does not fix
it** — you must kill the whole Wine session:

```bash
./kakao-restart.sh     # runs `wineserver -k` then relaunches with the ibus env
```

`wineserver -k` does **not** disturb the ibus daemon, so Korean input survives.

## Configurations that do NOT work (tested dead ends)

| Setup | Result |
|-------|--------|
| 64-bit prefix + ibus | Input completely broken |
| 32-bit + ibus (boot-time daemon, untouched) | Freezes / crashes when typing in chat |
| 32-bit + no IME (`@im=none`, xim) | English only, no Korean |
| 32-bit + fcitx (after killing ibus) | KakaoTalk Korean fails **and** breaks Korean in other apps |
| 32-bit + ibus + xim protocol | Hangul shows but doesn't reach the chat box |
| 32-bit + `InputStyle` root / offthespot | Input broken |

**Also avoid:**
- `Decorated=Y` / `Managed=Y` registry tweaks → KakaoTalk crashes
- `winetricks riched20` / `riched30` → chat window won't open
- Win10 mode → no effect
- Running the fcitx daemon → breaks system-wide Korean input

## License

MIT for the scripts and docs in this repo. KakaoTalk itself and its installer are
property of Kakao Corp. and are not distributed here. See [LICENSE](LICENSE).
