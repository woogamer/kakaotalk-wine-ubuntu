# 우분투에서 카카오톡 실행하기 (Wine) — 한글 입력까지

Windows용 **카카오톡** 데스크톱 클라이언트를 Ubuntu에서 Wine으로 실행합니다.
채팅창에서 **한글 입력이 실제로 동작**하는 설정까지 포함합니다.

공식 리눅스 클라이언트가 없어 Wine이 유일한 경로입니다. 어려운 건 카카오톡을
띄우는 게 아니라 채팅창 안에서 한글이 조합되도록 만드는 것입니다. 이 저장소는
동작하는 설정과 함께, 대부분의 가이드가 틀리는 입력 문제의 근본 원인 노트를
담고 있습니다.

검증 환경: **Ubuntu 24.04.4 LTS (Noble), Wine 11.0 stable, ibus 1.5.29 + ibus-hangul 1.5.5**, 32비트 prefix.

> **설치 파일 안내:** 이 저장소에는 `KakaoTalk_Setup.exe`가 포함되어 있지
> **않습니다**. 카카오의 독점 소프트웨어이기 때문입니다. 카카오 공식 사이트에서
> PC 버전을 직접 내려받은 뒤 설치 스크립트에 경로를 지정하세요.

## 빠른 시작

```bash
# 0. 먼저 WineHQ stable 설치:  https://wiki.winehq.org/Ubuntu
# 1. 카카오 공식 사이트에서 KakaoTalk_Setup.exe (PC 버전)를 받아
#    이 폴더에 두거나 KAKAO_SETUP=/경로/파일.exe 로 지정.
git clone https://github.com/woogamer/kakaotalk-wine-ubuntu.git
cd kakaotalk-wine-ubuntu
chmod +x install.sh kakaotalk.sh kakao-restart.sh

./install.sh        # 32비트 prefix, 폰트, ko_KR locale, 사일런트 설치
./kakaotalk.sh      # 실행
```

`install.sh`는 기본적으로 `$HOME/.wine`를 사용합니다. 별도 prefix를 쓰려면
`WINEPREFIX=...`로 덮어쓰세요.

## 파일 구성

| 파일 | 용도 |
|------|------|
| `install.sh` | 한 번에 설치: `ko_KR.UTF-8` locale, 32비트 prefix, 나눔폰트, 사일런트 설치 |
| `kakaotalk.sh` | 한글 입력에 필요한 **ibus** IME 환경변수를 세팅한 실행 스크립트 |
| `kakao-restart.sh` | 검은/짤린 창 글리치 복구용 클린 재시작 (`wineserver -k` + 재실행) |
| `nanum_font.reg` | 두부(□) 대신 한글이 렌더링되도록 하는 폰트 치환 |

## 왜 32비트 prefix인가

`WINEARCH=win32`을 씁니다. 64비트 prefix에서는 입력이 완전히 깨졌습니다(아래 표
참고). `.exe`는 `/S` 플래그로 **사일런트 설치**해야 합니다 — GUI 설치는 Wine에서
실패합니다.

## 트러블슈팅 — 한글 입력이 안 될 때

여기서 대부분 막힙니다. 시스템 IME(ibus + ibus-hangul)는 다른 곳에서 멀쩡한데
카카오톡에서만 영어만 입력된다면, **원인은 거의 항상 아래 둘 중 하나입니다.
ibus/fcitx를 건드리기 전에 이것부터 확인하세요:**

**1. `ko_KR.UTF-8` locale 누락 (가장 흔한 원인).**
   - 증상: `locale -a | grep ko_KR`가 아무것도 출력하지 않음. `LANG=ko_KR.UTF-8 locale`
     실행 시 "Cannot set LC_CTYPE" 오류. 실행 스크립트가 `LANG=ko_KR.UTF-8`을
     강제하지만 해당 locale이 없으면 Wine이 C 로케일로 돌아가 한글을 조합하지 못함.
   - 해결: `sudo locale-gen ko_KR.UTF-8` (영구 적용, 재부팅 무관).

**2. 과거 실험에서 남은 Wine `InputStyle=root` 잔재.**
   - 해결 — 기본값 복원:
     ```bash
     WINEPREFIX="$HOME/.wine" wine reg delete \
       "HKCU\\Software\\Wine\\X11 Driver" /v InputStyle /f
     ```

둘 중 하나를 고친 뒤: `wineserver -k` → `./kakaotalk.sh` 재실행.

> 이 문제를 "고치겠다고" ibus 데몬을 재시작(`ibus-daemon -drx`, `ibus exit`)하거나
> fcitx로 바꾸지 **마세요**. 그러면 실행 중인 다른 모든 앱(터미널, 브라우저 등)의
> 한글 입력이 **시스템 전체에서** 깨지며, 애초에 진짜 원인도 아니었습니다.

### 실행 스크립트는 ibus 환경변수를 써야 함

이 환경의 시스템 IME는 **ibus**입니다. 실행 스크립트는 다음을 export합니다:

```bash
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
```

시스템이 ibus로 도는데 카카오톡만 fcitx 환경변수로 실행하면 카카오톡 안에서
입력이 실패합니다. 이 값들은 `ibus`로 유지하세요.

## 재시작 후 창이 검게/짤려/안 보일 때

Wine이 메인 창을 트레이로 최소화(unmapped)하거나 일부만 리페인트(검은/짤린 창)된
상태로 두는 경우가 있습니다. **카카오톡 프로세스만 재시작해서는 풀리지 않고**,
Wine 세션 전체를 종료해야 합니다:

```bash
./kakao-restart.sh     # `wineserver -k` 실행 후 ibus 환경변수로 재실행
```

`wineserver -k`는 ibus 데몬을 **건드리지 않으므로** 한글 입력이 유지됩니다.

## 동작하지 않는 설정 (검증된 막다른 길)

| 설정 | 결과 |
|------|------|
| 64비트 prefix + ibus | 입력 자체 불가 |
| 32비트 + ibus (부팅 시 시작된 데몬, 그대로) | 채팅 입력 시 멈춤/크래시 |
| 32비트 + IME 없음 (`@im=none`, xim) | 영어만 가능, 한글 불가 |
| 32비트 + fcitx (ibus 종료 후) | 카카오톡 한글 실패 **+** 다른 앱 한글도 깨짐 |
| 32비트 + ibus + xim 프로토콜 | 한글이 보이지만 채팅창으로 넘어가지 않음 |
| 32비트 + `InputStyle` root / offthespot | 입력 안됨 |

**그 외 피해야 할 것:**
- `Decorated=Y` / `Managed=Y` 레지스트리 → 카카오톡 크래시
- `winetricks riched20` / `riched30` → 채팅창이 안 열림
- Win10 모드 → 효과 없음
- fcitx 데몬 실행 → 시스템 전체 한글 입력 깨짐

## 라이선스

이 저장소의 스크립트와 문서는 MIT입니다. 카카오톡 자체와 그 설치 파일은 카카오의
자산이며 여기서 배포하지 않습니다. [LICENSE](LICENSE) 참고.
