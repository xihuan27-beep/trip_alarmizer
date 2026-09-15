# 중복 통합 기록 (Deduplication Notes)

이 대화 세션은 여러 차례 컨텍스트 압축(compaction)을 거쳤습니다. 압축 후에는 이전에 만든 정확한 `keyword_id` 레지스트리를 매번 다시 볼 수 없었기 때문에, 같은 사실에 대해 이름만 다른 키워드를 다시 만든 사례가 발생했습니다. 이 레지스트리를 작성하며 전체 대화 원문(JSONL 트랜스크립트)을 재검토해 다음과 같이 통합했습니다.

| 최종 keyword_id (유지) | 통합되어 사라진 keyword_id | 통합 사유 |
|---|---|---|
| `ubon_wanna_spirit_medium` | `ubon_wanna_spirit_medium_role` | 같은 사실(가문 세습 영매) — 세션 재개 후 동일 논문(Ruangsri 2023)을 재독하며 이름만 다르게 재생성 |
| `ubon_wanna_spirit_medium` | `ubon_wanna_liquor_tax_resistance` | 술세 저항 내용을 영매 키워드에 통합(원래도 같은 문단에서 나온 사실) |
| `yang_na_planting_1899` | `old_lamphun_road_planting_1899` | 동일 논문(Phar Arriyananda 외 2023) 재처리 시 재생성 |
| `yang_na_storm_2021` | `old_lamphun_road_2021_storm_damage` | 상동 |
| `three_kings_temple_inscription` | `wat_chiang_man_three_kings_inscription` | 동일 논문(Teeratusananan & Cansong 2025) 재처리 시 재생성 |
| `chiang_man_name_meaning` | `wat_chiang_man_name_etymology` | 상동 |
| `nalagiri_buddha` | `nalagiri_taming_buddha_image` | 상동 |
| `elephant_chedi` | `chang_lom_chedi` | 상동 |
| `kawila_re_entry_procession_1797` | `kawila_1797_restoration_exact_date` | Easum(1~2장)에서 이미 다룬 사건을 Grabowsky(1999) 재처리 시 재생성 — 단, 후자가 제공한 "1797.3.9(목), 500주년" 이라는 정확한 날짜는 Table D에 새 근거 행으로 추가함 |
| `burmese_occupation_1551`, `mangthra_restoration_1558`, `kawila_restoration` (3건 개별 유지) | `wat_chiang_man_burmese_abandonment_restoration` (통합 키워드였던 것을 재분리) | 왓 치앙만 v1(사전 압축분)에서 이미 세 개의 개별 사건으로 나눠뒀는데, v2(이 세션)에서 하나로 뭉뚱그려 재생성 — 원래의 세분화된 구조를 유지 |
| `dara_phirom_palace_founding` | `dara_phirom_suan_chao_sabai_construction` | 동일 사실(1915년경 착공~1920년경 완공, 70라이 '수언 짜오 사바이') |
| `dara_rasami_agri_matron` | `dara_phirom_agricultural_experiments` | 동일 사실(양배추·멜론·람야이 도입) |
| `dara_rasami_bangkok_mausoleum` | `dara_rasami_wat_suan_dok_own_burial` | 동일 사실(왓 수언독+방콕 분산 안장) — 이미 Castro-Woodhouse ch.4에서 정정 확인된 내용을 Dara Rasami 책 재독 시 재확인하며 별도 키워드로 재생성 |
| `dara_rasami_bangkok_mausoleum` | `dara_phirom_death_and_legacy` (안장 부분만) | 안장 정보는 위 키워드로 흡수, 궁전 건물 자체의 이후 역사(군점유→복원→1990박물관)는 새 정보라 유지 |
| `wat_phra_singh_dara_display` | `dara_rasami_wat_phra_singh_lineage_display` | 동일 사실(왓 프라싱 법당 내 초상 전시) |

## 통합하지 않고 유지한 "유사해 보이지만 실제로 다른" 키워드

- `phra_sihing_shipwreck_origin`(Vickery, 실론 난파 전설) vs `phra_singh_buddha_provenance_chiang_rai`(Penth, 캄팽펫→치앙라이→치앙마이 실제 이송 경로) — 같은 불상의 서로 다른 시대/성격의 두 이야기(전설적 기원 vs 역사적 이송). 보완 관계로 유지.
- `camadevi_wiranga_spear_contest`(Rhum) vs `chet_lin_khun_wiranka_legend`(UNESCO) — 실제로 상충하는 학술 충돌 사례이므로 [conflicts.md](./conflicts.md)에 별도 기재하고 둘 다 유지.
- `san_pa_tong_five_ethnicities`(San Pa Tong 문화자본 논문, 개괄) vs `san_pa_tong_khun_lue_yong_resettlement` + `hang_dong_lua_original_people`(Grabowsky, 구체적 민족별 정착지도) — 후자가 전자를 훨씬 구체적으로 뒷받침하는 관계라 병합하지 않고 서로 참조하도록 유지.
- `dara_phirom_weaving_looms`(우본완나로부터의 직조 계승, 매쨈 문양 수집) vs `dara_rasami_lan_na_dance_troupe`(무용단 '롱 끼') — 둘 다 다라 라사미의 문화 후원이지만 대상(직조 vs 무용)이 달라 별개 키워드로 유지.

## 교훈 (향후 작업 시 참고)

3-4개 논문 이상 연속 처리하기 전에, 또는 컨텍스트 압축이 의심되는 시점마다, 기존 `keywords-table-a.md`를 먼저 열람해 신규 키워드와 대조하는 습관이 필요합니다. 이번 레지스트리 작업 자체가 그 사후 안전망 역할을 했습니다.
