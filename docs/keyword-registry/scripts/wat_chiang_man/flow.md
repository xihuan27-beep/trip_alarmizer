# 왓 치앙만 — 스토리 흐름 (언어 중립 비트시트)

`site_id = wat_chiang_man`, DB 쿼리: `SELECT k.*, sl.relation FROM site_links sl JOIN keywords k ... WHERE site_id='wat_chiang_man'` (26개 키워드 중 24개를 하나의 연대기로 엮음, 2개는 각주/학술논쟁으로 처리).

| # | 연도 | 비트 | keyword_id |
|---|---|---|---|
| 1 | 1296 | 망라이왕이 파야오·수코타이 왕과 동맹해 삼왕 공동 창건, "도시엔 지탱할 절이 있어야 한다"는 믿음으로 명명 | `capital_relocation_1296`, `three_kings_temple_inscription`, `chiang_man_name_meaning` |
| 2 | 1296 | 하리푼차이 정복 후 가져온 두 불상(백옥불·나라기리 조복상) 안치 | `phra_setangkhamani`, `nalagiri_buddha` |
| 3 | 1296~ | 세계순례부처 전설 속 8대 신성사원 중 하나(상가람)로 등장 | `phra_chao_liap_lok`, `eight_sacred_temples_liap_lok` |
| 4 | 1471 | 틸로카랏왕, 무너진 쩨디를 코끼리 15마리 창롬 쩨디로 재건 | `tilokarat_restoration_1471`, `elephant_chedi` |
| 5 | 1551 | 버마 점령, 폐사 | `burmese_occupation_1551` |
| 6 | 1558 | 점령군 버마왕 몽트라의 역설적 대규모 후원·재건 | `mangthra_restoration_1558` |
| 각주 | 1581 | (학술 논쟁) 비문의 "삼중 성벽" 기록은 후대 창작 가능성 | `wat_chiang_man_inscription_doubt` |
| 7 | 1797.3.9 | 카윌라왕, 망라이 건국 500주년에 정확히 맞춰 재입성, 왕궁 입성 전날 밤을 이곳에서 보냄 | `kawila_re_entry_procession_1797`, `kawila_restoration`, `kawila_kep_phak_sai_sa_policy`, `konbaung_style_influx` |
| 8 | 1890년대 | 치앙마이 최초 담마유티까 종파 거주 | `dhammayutika_first_residence` |
| 9 | 1909 | 다라 라사미가 불상을 방콕으로 가져간 일이 오라버니 급사와 얽혀 흉조로 해석 | `dara_rasami_local_backlash` |
| 10 | 1920~30s | 크루바 시위차이 — 호랑이 서명, '호랑이 교단', 마법검 소지 혐의, 첫 체포 시기·원인 논쟁 | `tiger_signature`, `khruba_srivichai_tiger_order`, `khruba_srivichai_sword_charge`, `khruba_srivichai_first_arrest_dating` |
| 11 | 1962 | 시위차이 추모 사당 건립 | `khruba_srivichai_shrine_1962` |
| 12 | 현재 | 다라 라사미(전통보존)와 시위차이(민중저항), 란나 정체성의 두 상징 공존 | `dara_vs_srivichai_symbolism` |

**분량 결정**: 200~400자였던 기존 sites.json 스토리보다 훨씬 길게, 위 24개 비트를 전부 살린 멀티 단락 스크립트로 작성(2025-09 결정, 필요시 추후 축약).

**미사용 각주 처리**: `wat_chiang_man_inscription_doubt`는 본문 흐름을 끊지 않도록 "학자들의 노트" 형태의 짧은 삽입 단락으로 배치.
