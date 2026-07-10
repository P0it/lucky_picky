-- ════════════════════════════════════════════════════════════════
--  시드 데이터 — 카탈로그 70종 id/등급, 등급 가중치, 게임 상수.
--  lib/config/luck_tickets.dart 와 1:1 대응 (id는 불변 키).
-- ════════════════════════════════════════════════════════════════

insert into public.ticket_catalog (id, rarity)
select 'c' || lpad(i::text, 2, '0'), 'common'    from generate_series(1, 30) i
union all
select 'r' || lpad(i::text, 2, '0'), 'rare'      from generate_series(1, 20) i
union all
select 'e' || lpad(i::text, 2, '0'), 'epic'      from generate_series(1, 12) i
union all
select 'l' || lpad(i::text, 2, '0'), 'legendary' from generate_series(1, 6) i
union all
select 'm' || lpad(i::text, 2, '0'), 'mythic'    from generate_series(1, 2) i;

-- 합계 100. 앱의 확률 정보 시트도 이 비율(50/27/15/6/2)을 표시한다.
insert into public.rarity_weights (rarity, weight, sort_order) values
  ('common',    50, 1),
  ('rare',      27, 2),
  ('epic',      15, 3),
  ('legendary',  6, 4),
  ('mythic',     2, 5);

insert into public.game_config (key, value) values
  ('free_pulls_per_day', '3'),
  ('max_level', '5');
