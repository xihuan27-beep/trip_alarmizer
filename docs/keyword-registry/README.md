# 키워드 레지스트리 (Keyword Registry)

ChiangMaiHistory 앱의 콘텐츠 "모아트(moat)" 구축 작업 — 35편의 학술 논문/저서 코퍼스에서 추출한 키워드를 4-테이블 관계형 스키마로 정리한 문서입니다.

## 배경

`Sources/Resources/sites.json`의 34개 사이트 각각에 이미 존재하는 서사(story)를, 학술 출처로 검증·보강하고 사이트 간 교차 서사(related story) 연결을 만들기 위한 작업입니다. Google Drive의 35편 학술 코퍼스(치앙마이/란나 역사 관련 논문·저서)를 한 편씩 처리하며 아래 4-테이블 스키마로 키워드를 축적했습니다.

## 스키마

**마크다운(사람이 읽는 원본, 계속 여기서 편집)**과 **SQLite(빌드 산출물, 앱/쿼리용)** 두 형태로 존재합니다.

- **Table A — 키워드 마스터** ([keywords-table-a.md](./keywords-table-a.md)): `keyword_id`, 한국어, ไทย, English, 타입. 키워드 1개 = 행 1개, 중복 없이 딱 한 번만 존재.
- **Table B — 사이트 마스터**: `Sources/Resources/sites.json`을 그대로 재사용 (별도 마크다운 파일 없음). SQLite 빌드 시 `sites` 테이블로 그대로 미러링됨.
- **Table C — 키워드-사이트 연결** ([site-links-table-c.md](./site-links-table-c.md)): `keyword_id`, `site_id`, 관계 한줄. 키워드 하나가 여러 사이트에 걸릴 수 있음(예: 크루바 시위차이 관련 키워드가 여러 절에 걸림).
- **Table D — 키워드-근거** ([sources-table-d.md](./sources-table-d.md)): `keyword_id`, 출처, 주장 내용. 같은 키워드에 대해 여러 출처가 각기 다른(때로는 상충하는) 내용을 주장할 수 있어, 키워드당 여러 행 존재 가능.

### SQLite 빌드 ([build_db.py](./build_db.py) → `content.sqlite`)

마크다운 3개 파일 + `sites.json`을 파싱해 `content.sqlite`를 생성합니다. **마크다운이 유일한 소스**이고, `.sqlite` 파일은 빌드 산출물이라 매번 통째로 재생성됩니다(직접 편집 금지).

```bash
cd docs/keyword-registry
python3 build_db.py     # content.sqlite 재생성 + FK 무결성 검증 + 충돌후보 리포트
```

스키마(4테이블 + FK + 인덱스):
```sql
sites(site_id PK, name, name_thai, latitude, longitude, radius_meters, category, year_built, teaser, story)
keywords(keyword_id PK, ko, th, en, type, type_detail, is_orphan)
site_links(id PK, keyword_id FK→keywords, site_id FK→sites, relation)
sources(id PK, keyword_id FK→keywords, source, claim)
```
`type`은 README 하단의 6종 카테고리로 정규화되고, 원본 세부 태그(예: "전설모티프(지명)")는 `type_detail`에 보존됩니다. `is_orphan=1`은 아직 대응 사이트가 없는 "확장 후보" 키워드.

### 조인 예시
```sql
-- 사이트 하나의 콘텐츠 작성
SELECT k.*, sl.relation, src.source, src.claim
FROM site_links sl
JOIN keywords k ON k.keyword_id = sl.keyword_id
LEFT JOIN sources src ON src.keyword_id = k.keyword_id
WHERE sl.site_id = 'wat_chiang_man';

-- 키워드 하나의 교차 사이트(related-story 추천)
SELECT s.site_id, s.name FROM site_links sl
JOIN sites s ON s.site_id = sl.site_id
WHERE sl.keyword_id = 'tiger_signature';

-- 학술 충돌 후보 (출처 2개 이상)
SELECT keyword_id, COUNT(*) c FROM sources
GROUP BY keyword_id HAVING c > 1 ORDER BY c DESC;

-- 아직 키워드가 하나도 안 걸린 사이트 (코퍼스 처리 갭 확인)
SELECT s.site_id, s.name FROM sites s
LEFT JOIN site_links sl ON sl.site_id = s.site_id
WHERE sl.site_id IS NULL;
```

## 타입 분류 (6종)

인물 · 장소 · 사건·날짜 · 사물·유물 · 개념·제도 · 전설모티프

## 운영 규칙 (이 코퍼스 작업 전체에 적용된 원칙)

1. 새 키워드를 만들기 전 기존 `keyword_id` 레지스트리를 먼저 확인해 재사용 — 신규 생성 최소화.
2. `〃`(반복 기호) 사용 금지 — 모든 행에 완전한 값을 직접 기재.
3. 사이트명/정보는 항상 `site_id`로 참조해 sites.json에서 조인 — 직접 재입력 금지(오타/불일치 방지).
4. sites.json에 대응 사이트가 없는 "고아 키워드"(확장 후보)는 Table C 없이 Table A·D에만 존재.
5. 날짜/연도의 사소한 정밀도 차이(±1년 등)는 소비자 가치가 없어 충돌로 취급하지 않음. 극적 구조 자체가 달라지는 경우만 학술적 충돌로 플래그.
6. 모든 키워드·연결에는 한국어/ไทย/English 3개 언어 필드 필수(ไทย는 현지 표지판 대조용, English는 향후 다국어화 대비).
7. 인용 원문은 길게 그대로 복제하지 않고 짧게 한국어로 의역·요약.

## 코퍼스 처리 현황

35편 중 처리 완료된 논문/저서 목록 및 처리 결과는 [corpus-status.md](./corpus-status.md) 참고.

## 알려진 중복·통합 사항

같은 대화 세션이 중간에 컨텍스트 압축(compaction)을 여러 번 거치면서, 일부 키워드가 서로 다른 이름으로 두 번 생성된 사례가 있었습니다. 이 레지스트리를 만들며 전체 대화 기록을 재검토해 다음과 같이 통합했습니다 (자세한 내용은 [dedup-notes.md](./dedup-notes.md)):

- `ubon_wanna_spirit_medium` ← `ubon_wanna_spirit_medium_role` 통합
- `yang_na_planting_1899` ← `old_lamphun_road_planting_1899` 통합
- `yang_na_storm_2021` ← `old_lamphun_road_2021_storm_damage` 통합
- `three_kings_temple_inscription` ← `wat_chiang_man_three_kings_inscription` 통합
- `chiang_man_name_meaning` ← `wat_chiang_man_name_etymology` 통합
- `nalagiri_buddha` ← `nalagiri_taming_buddha_image` 통합
- `elephant_chedi` ← `chang_lom_chedi` 통합
- `kawila_re_entry_procession_1797` ← `kawila_1797_restoration_exact_date` 통합 (날짜 세부사항은 근거로 추가)
- `burmese_occupation_1551` / `mangthra_restoration_1558` / `kawila_restoration` ← `wat_chiang_man_burmese_abandonment_restoration`(중복 묶음 키워드) 통합

## 학술적 충돌 (Step 3 대상)

Table D를 keyword_id로 그룹핑했을 때 실제로 상충하는 주장이 나온 사례는 [conflicts.md](./conflicts.md)에 정리했습니다. 예: 짜마테위-위랑가 전설의 "군사적 패배" vs "여왕의 지략" 버전, 크루바 시위차이 첫 체포 연도/원인 논쟁, 위앙 꿈깜 둔덕의 자연제방 vs 인공제방 논쟁 등.
