import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/luck_tickets.dart';
import '../l10n/app_localizations.dart';
import '../models/owned_ticket.dart';
import '../theme/app_theme.dart';
import 'clover_mark.dart';
import 'rarity_style.dart';

/// 행운권 이미지의 출력 형태.
/// - portrait: 9:16 세로 — 잠금/배경화면용
/// - square:   1:1 정사각 — SNS 공유용
enum TicketFormat { portrait, square }

extension TicketFormatX on TicketFormat {
  /// 캡처/렌더의 기준 논리 크기. 캡처 시 pixelRatio 3 → 1080px 기준.
  Size get canvas => this == TicketFormat.portrait
      ? const Size(360, 640)
      : const Size(360, 360);

  bool get isPortrait => this == TicketFormat.portrait;
}

/// 뽑은 행운권을 공유용 카드 한 장으로 그려내는 위젯.
/// 화면 미리보기와 PNG 캡처 양쪽에 같은 위젯을 쓴다(고정 논리 크기).
/// 등급 컬러 포인트 + 클로버 문양 + 행운 문구 + 강화 배지 + LuckyPicky 워드마크.
class TicketCard extends StatelessWidget {
  final LuckTicket ticket;
  final OwnedTicket owned;
  final TicketFormat format;

  const TicketCard({
    super.key,
    required this.ticket,
    required this.owned,
    this.format = TicketFormat.portrait,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final size = format.canvas;
    final p = format.isPortrait;
    final style = RarityStyle.of(ticket.rarity);

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        children: [
          // 전체를 채우는 등급 톤 그라데이션 (배경화면 시 모서리 빈틈 없음).
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: style.panel,
                ),
              ),
            ),
          ),
          // 배경에 크게 깔리는 클로버 워터마크.
          Positioned.fill(
            child: Center(
              child: Transform.rotate(
                angle: -12 * math.pi / 180,
                child: CloverMark(
                  size: p ? 300 : 230,
                  withStem: true,
                  color: style.color.withValues(alpha: 0.07),
                ),
              ),
            ),
          ),
          // 등급 컬러의 얇은 내부 프레임. 신화는 무지개 테두리.
          Positioned.fill(
            child: style.aura != null
                ? _AuraFrame(margin: p ? 14 : 12)
                : Container(
                    margin: EdgeInsets.all(p ? 14 : 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                          color: style.color.withValues(alpha: 0.28), width: 1.4),
                    ),
                  ),
          ),
          // 본문.
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: p ? 38 : 30, vertical: p ? 46 : 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _label(l, lang, p, style),
                  _center(l, lang, p, style),
                  _footer(l, p, style),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(AppLocalizations l, String lang, bool p, RarityStyle style) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          LuckCatalog.rarityName(ticket.rarity, lang).toUpperCase(),
          style: AppText.base(
            size: p ? 12 : 11,
            weight: FontWeight.w800,
            color: style.color,
            letterSpacingEm: 0.34,
          ),
        ),
        SizedBox(height: p ? 8 : 6),
        // 등급 별 표시 — 강화 레벨만큼 채워진 별.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < LuckCatalog.maxLevel; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Icon(
                  i < owned.level ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: p ? 15 : 12,
                  color: i < owned.level
                      ? style.color
                      : style.color.withValues(alpha: 0.3),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _center(AppLocalizations l, String lang, bool p, RarityStyle style) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CloverMark(size: p ? 88 : 58, withStem: true),
        SizedBox(height: p ? 26 : 16),
        Text(
          ticket.text(lang),
          textAlign: TextAlign.center,
          maxLines: p ? 4 : 3,
          overflow: TextOverflow.ellipsis,
          style: AppText.base(
            size: p ? 22 : 17,
            weight: FontWeight.w800,
            height: 1.42,
            letterSpacingEm: -0.03,
          ),
        ),
        if (owned.level > 1) ...[
          SizedBox(height: p ? 16 : 10),
          Container(
            padding: EdgeInsets.symmetric(horizontal: p ? 12 : 10, vertical: p ? 6 : 4),
            decoration: BoxDecoration(
              color: style.soft,
              borderRadius: BorderRadius.circular(AppRadius.chipFull),
            ),
            child: Text(
              l.ticketBoost(owned.level),
              style: AppText.base(
                  size: p ? 13 : 11, weight: FontWeight.w800, color: style.color),
            ),
          ),
        ],
      ],
    );
  }

  Widget _footer(AppLocalizations l, bool p, RarityStyle style) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            owned.firstPulledAt,
            style: AppText.base(
                size: p ? 12 : 11, weight: FontWeight.w700, color: AppColors.muted),
          ),
          SizedBox(height: p ? 12 : 8),
          Container(
              width: p ? 26 : 20,
              height: 1.4,
              color: style.color.withValues(alpha: 0.25)),
          SizedBox(height: p ? 12 : 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CloverMark(size: p ? 16 : 14),
              SizedBox(width: p ? 6 : 5),
              Text('LuckyPicky',
                  style: AppText.base(
                      size: p ? 16 : 14, weight: FontWeight.w800, letterSpacingEm: -0.02)),
            ],
          ),
          SizedBox(height: p ? 4 : 3),
          Text(l.ticketTagline,
              style: AppText.base(
                  size: p ? 10.5 : 9.5, weight: FontWeight.w600, color: AppColors.muted)),
        ],
      );
}

/// 신화 등급 전용 무지개 테두리 프레임 — 내부는 비워두고 선만 그린다.
class _AuraFrame extends StatelessWidget {
  final double margin;
  const _AuraFrame({required this.margin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(margin),
      child: CustomPaint(
        painter: _AuraBorderPainter(RarityStyle.of(Rarity.mythic).aura!),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _AuraBorderPainter extends CustomPainter {
  final Gradient aura;
  _AuraBorderPainter(this.aura);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
        rect.deflate(0.9), const Radius.circular(26));
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = aura.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_AuraBorderPainter old) => false;
}
