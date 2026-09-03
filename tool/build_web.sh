#!/usr/bin/env bash
#
# Vercel 빌드서버용 웹 빌드 — 깃헙에 푸시하면 여기서 build/site 가 만들어진다.
# (로컬에서 손으로 굽고 싶으면 tool/build_web.ps1 이 같은 일을 한다.)
#
# 산출물 배치:
#   /              site/index.html    — 소개 랜딩
#   /privacy.html  site/privacy.html  — 개인정보처리방침
#   /app-ads.txt   site/app-ads.txt   — AdMob 크롤러가 읽는 파일 (루트여야 한다)
#   /app/          Flutter 웹 데모
#
set -euo pipefail

# Vercel 이미지에는 Flutter 가 없다. 로컬과 같은 버전을 고정해서 받는다 —
# stable 을 그대로 따라가면 어느 날 푸시 하나가 SDK 업그레이드로 깨진다.
FLUTTER_VERSION="3.41.6"
FLUTTER_DIR="${FLUTTER_DIR:-$PWD/.flutter-sdk}"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "Flutter $FLUTTER_VERSION 내려받는 중…"
  git clone --depth 1 -b "$FLUTTER_VERSION" \
    https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"

# clone 한 SDK 는 소유자가 달라 git 이 "dubious ownership" 으로 거부한다.
git config --global --add safe.directory "$FLUTTER_DIR" || true

flutter --version
flutter pub get

# --pwa-strategy=none: 서비스워커를 만들지 않는다. 재배포 후 낡은 번들을 물고
# 스플래시에서 멈추는 사고를 막는다(vercel.json 의 no-cache 헤더와 한 쌍).
# 데모 모드는 웹 기본값이라 따로 넘기지 않는다 — lib/config/app_mode.dart 참고.
flutter build web --release --pwa-strategy=none --base-href /app/

rm -rf build/site
mkdir -p build/site
cp -r site/. build/site/
cp -r build/web build/site/app

echo "조립 완료:"
ls -la build/site
