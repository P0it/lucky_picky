<#
  웹 배포 산출물을 build/site 에 조립한다.

    /              site/index.html      — 소개 랜딩
    /privacy.html  site/privacy.html    — 개인정보처리방침
    /app-ads.txt   site/app-ads.txt     — AdMob 크롤러가 읽는 파일 (루트여야 한다)
    /app/          flutter build web    — 데모 앱

  데모 앱은 DEMO_MODE(웹 기본값)로 굽는다 — 게임 백엔드가 DemoGameBackend 로
  바뀌어 실서비스 Supabase 에 쓰지 않는다. lib/config/app_mode.dart 참고.

  --pwa-strategy=none: 서비스워커를 만들지 않는다. 재배포 후 낡은 화면이 남아
  "무한 로딩"으로 보이는 사고를 막는다(vercel.json 의 no-cache 헤더와 한 쌍).

  사용: pwsh tool/build_web.ps1   →   vercel deploy build/site --prod
#>
param([string]$Out = "build/site")

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

flutter build web --release --pwa-strategy=none --base-href /app/
if ($LASTEXITCODE -ne 0) { throw "flutter build web 실패" }

$outDir = Join-Path $root $Out
if (Test-Path $outDir) { Remove-Item -Recurse -Force $outDir }
New-Item -ItemType Directory -Force $outDir | Out-Null

Copy-Item (Join-Path $root "site/*") $outDir -Recurse -Force
Copy-Item (Join-Path $root "build/web") (Join-Path $outDir "app") -Recurse -Force

"조립 완료: $outDir"
Get-ChildItem $outDir | Select-Object Name, Length | Format-Table
