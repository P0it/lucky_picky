<#
  웹 배포 산출물을 build/site 에 조립한다 — Vercel 의 tool/build_web.sh 와 같은 일을
  로컬 Windows 에서 하는 판이다. 규칙을 바꾸면 두 파일을 함께 고친다.

    /              Flutter 웹 데모 (앱이 곧 사이트다)
    /privacy.html  개인정보처리방침
    /app-ads.txt   AdMob 크롤러가 읽는 파일 (루트여야 크롤러가 찾는다)

  데모 앱은 DEMO_MODE(웹 기본값)로 굽는다 — 게임 백엔드가 DemoGameBackend 로
  바뀌어 실서비스 Supabase 에 쓰지 않는다. lib/config/app_mode.dart 참고.

  --pwa-strategy=none: 서비스워커를 만들지 않는다. 재배포 후 낡은 화면이 남아
  "무한 로딩"으로 보이는 사고를 막는다(vercel.json 의 no-cache 헤더와 한 쌍).

  사용: pwsh tool/build_web.ps1
#>
param([string]$Out = "build/site")

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

flutter build web --release --pwa-strategy=none
if ($LASTEXITCODE -ne 0) { throw "flutter build web 실패" }

$outDir = Join-Path $root $Out
if (Test-Path $outDir) { Remove-Item -Recurse -Force $outDir }
New-Item -ItemType Directory -Force $outDir | Out-Null

Copy-Item (Join-Path $root "build/web/*") $outDir -Recurse -Force
# 앱 빌드 위에 문서를 얹는다. 겹치는 이름이 없어야 한다(앱은 index.html 을 쓴다).
Copy-Item (Join-Path $root "site/*") $outDir -Recurse -Force

"조립 완료: $outDir"
Get-ChildItem $outDir | Select-Object Name, Length | Format-Table
