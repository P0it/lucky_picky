# LuckyPicky 작업 규칙

## 커밋 / 푸시

작업이 끝나면 **기능 단위로 자동 커밋하고 푸시한다.** 매번 물어보지 않는다.

- 한 커밋 = 한 기능/수정. 여러 기능을 한 커밋에 섞지 않는다.
- 작업 트리에 무관한 변경(아이콘, ios 프로젝트 파일, 다른 작업 중인 화면 등)이 남아 있어도
  **이번 작업에서 건드린 파일만 골라서** 스테이징한다. `git add .` 금지.
- 커밋 메시지는 기존 관례를 따른다 — Conventional Commits + 한국어 본문:
  `feat(ui): …`, `fix(clover): …`, `docs: …`, `chore: …`
- 커밋 후 현재 브랜치로 바로 푸시한다.
- main 브랜치에서는 커밋하지 않는다 — 먼저 브랜치를 만든다.
- 훅을 건너뛰지 않는다(`--no-verify` 금지). 실패하면 원인을 고친다.

## 코드 스타일

- `dart format` 을 리포지토리 전체/파일 전체에 돌리지 않는다. 현재 코드가 포매터 기본 스타일과
  달라서 diff가 통째로 뒤집힌다. 손댄 블록만 주변 스타일에 맞춰 직접 들여쓴다.
- 검증은 `flutter analyze <파일>` 로 한다.

## UI 확인

레이아웃을 바꿨으면 에뮬레이터에서 실제로 찍어서 확인한다. 실행 방법은 사용자 메모리
(`ooloo-local-run-setup`) 참고 — 요약하면:

```powershell
$env:Path = "C:\Users\Snet\flutter\bin;" + $env:Path
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
flutter build apk --debug
adb -s emulator-5554 install -r build\app\outputs\flutter-apk\app-debug.apk
adb -s emulator-5554 exec-out screencap -p > shot.png
```

`packageDebug` 가 `kernel_blob.bin.jar NoSuchFileException` 로 깨지면
`build\app\intermediates\compressed_assets` 를 지우고 다시 빌드한다.

## 화면 밀도 원칙

각 탭은 기본 상태에서 한 화면에 들어와야 한다(스크롤 없이). 리스트형 탭(행운 지갑,
나의 기록)은 항목이 쌓이면 결국 스크롤되지만, 통상적인 보유량까지는 한 화면에 담는다:

- 행운 지갑: 카드 6~7장
- 나의 기록: 타임라인 6건, 캘린더는 6주짜리 달까지

밀도를 높일 때 폰트 크기와 색은 건드리지 않는다 — 여백·간격·고정 높이부터 줄인다.
