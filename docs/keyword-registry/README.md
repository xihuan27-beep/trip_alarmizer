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
sources(id PK, keyword_id FK→keywords, source, claim, claim_type, status)
```
`type`은 README 하단의 6종 카테고리로 정규화되고, 원본 세부 태그(예: "전설모티프(지명)")는 `type_detail`에 보존됩니다. `is_orphan=1`은 아직 대응 사이트가 없는 "확장 후보" 키워드.

### 충돌·전설 표기 (`claim_type`/`status`, 2025-09 추가)

`sources`(Table D) 각 행은 기본값 `claim_type='historical'`, `status='preferred'`를 갖습니다. 별도 태그가 없으면 이 기본값 그대로 들어가므로 기존 행을 일일이 손댈 필요는 없습니다. 특정 주장에 태그를 달고 싶으면 `sources-table-d.md`의 `claim` 셀 맨 앞에 아래 세 태그 중 하나를 붙이면 `build_db.py`가 파싱해 제거하고 해당 컬럼에 반영합니다:

- `[전설]` → `claim_type='legend'` — 학술적 실사와 별개로 존재하는 기원 설화 (예: `phra_sihing_shipwreck_origin`, 프라싱 불상의 실론 난파 전설. 같은 불상의 실제 이송 경로를 다루는 `phra_singh_buddha_provenance_chiang_rai`는 태그 없이 기본값 `historical` 그대로 — 전설과 실사가 상충이 아니라 같은 이야기의 다른 챕터인 경우).
- `[논쟁]` → `status='disputed'` — 학계가 실제로 갈리고, 어느 한쪽이 "맞다"고 편집팀이 단정하지 않은 경우. 양쪽 행 모두에 붙인다 (예: `khruba_srivichai_first_arrest_dating`의 두 행, `wat_chiang_man_inscription_doubt`).
- `[대체됨]` → `status='superseded'` — 더 최근·강한 실증 근거로 사실상 뒤집힌 구설. 뒤집힌 쪽 행에만 붙이고, 새 정설 행은 태그 없이 기본값 `preferred`로 둔다 (예: `levee_debate`의 Hinz(2010) 행 — Ng/Wood/Ziegler(2015)의 탄소연대측정에 반박됨).

`conflicts.md`는 여전히 사람이 읽는 서사 설명(왜 충돌인지, 콘텐츠 제작 시 어떻게 다룰지)을 담당하고, 이 태그는 그중 "같은 keyword_id 아래 여러 source 행"으로 표현 가능한 것만 구조적으로 반영합니다. 서로 다른 keyword_id 간의 경쟁 서사(예: 짜마테위-위랑가 전설의 두 버전, 각기 다른 keyword_id)는 이 메커니즘으로 잡히지 않으니 `conflicts.md` 서술로만 남습니다.

### `keyword_id`/`site_id` 네임스페이스 규칙 (다국가 확장 대비, 2025-09 추가)

지금까지처럼 ID에 그 사이트/인물의 실제 이름을 그대로 박아 넣는 관례(`wat_chiang_man_*`, `dara_rasami_*`, `khruba_srivichai_*`)를 계속 유지합니다 — 국가/지역 접두어를 강제하지 않습니다. 치앙마이 한 도시 안에서는 이미 충돌이 거의 없었고, 다른 나라 사이트가 추가되더라도 도시/인물명이 서로 다르면 자연히 겹치지 않기 때문입니다. 다만 새 키워드를 만들기 전 항상 기존 레지스트리를 검색하는 규칙(운영 규칙 1번)은 국가가 늘어날수록 더 중요해지므로, ID를 지을 때 그 사이트/인물의 가장 구체적인 이름을 넣어 우발적 충돌 가능성을 스스로 낮추는 걸 관례로 삼습니다.

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

## 다국어 내레이션 스크립트 (scripts/)

키워드를 그냥 나열하지 않고, 사이트별로 **흐름(flow) → 9개 언어 스크립트** 순으로 작성합니다. `wat_chiang_man`을 파일럿으로 검증한 설계를 향후 33개 사이트에도 그대로 적용합니다.

- **흐름 문서** (`scripts/<site_id>/flow.md`): DB에서 그 사이트에 걸린 키워드를 연대기로 엮은 언어중립 비트시트. 각 비트에 사실(fact)뿐 아니라 **"당시 사람들에게 어떤 의미였는지"**를 별도로 적고, 출처에 명시된 것과 합리적 추정을 구분 표시.
- **화자(narrator)**: 그 사이트에 실존 인물이 얽혀 있으면 그 인물을 1인칭 화자로 세운다(예: 왓 치앙만 = 크루바 시위차이). 화자가 직접 안 겪은 과거는 "전해 들은 이야기"로, 화자 사후의 일은 "이야기가 거기서 끝나지 않았다"는 전환구를 거쳐 계속 화자 목소리로 서술한다. 실존 인물이 없는 사이트는 그 자리를 지켰을 법한 대표 인물(절이면 스님, 시장이면 상인 등)을 만들어 화자로 세운다. 학술 정확성을 해치지 않는 선에서, 사실 관계보다 "듣는 재미"를 우선한다 — 추정인 부분은 추정이라고 자연스럽게 티 내면 된다.
- **형식**: 이 스크립트들은 음성(TTS)으로 송출될 것을 전제로 쓴다. `##` 같은 마크다운 헤더로 장을 나누지 않고, "자, 그럼 처음부터…" 같은 구어체 전환 문장으로 흐름을 만든다.
- **비교 시간대 앵커**: 사이트당 2~3곳으로 제한(예전엔 거의 매 문단). 한국어는 한국사, 중국어는 중국사, 나머지 6개 언어(영어·스페인어·독일어·프랑스어·이태리어·러시아어)는 **공통 유럽사 앵커 하나**를 언어별로만 다르게 표현. 태국어는 이미 현지 역사라 앵커 없음. 재사용 레퍼런스는 [scripts/_historical-anchors.md](./scripts/_historical-anchors.md).
- **번역 원칙 (2025-09 확정)**: 한국어 원고를 그대로 옮기지 않고, ①연도 비교는 언어권마다 그 나라 역사로 다시 앵커링, ②직역이 아니라 그 언어 원어민이 자연스럽게 쓸 표현으로 trans-create, ③모든 언어에서 그 언어권 중학생이 듣고 이해할 수 있는 어휘 수준 유지.
- **사이트 간 연결, 순서 가정 금지(2025-09 확정)**: 화자(실존 인물)가 비중 있게 등장하는 다른 사이트가 있으면, `site_links`에서 같은 인물 keyword_id가 걸린 다른 site_id를 찾아 스크립트 맨 끝에 언급한다. 단, **사용자가 사이트를 어떤 순서로 방문할지는 절대 알 수 없다** — "다시 만났네요", "지난번에 말씀드렸듯이", "이어서 들려드릴게요", "마지막 이야기" 같이 다른 사이트를 먼저/나중에 들었다는 걸 전제하는 표현은 금지. 매 사이트가 어떤 순서로 들어도, 심지어 하나만 들어도 완결되는 독립된 글이어야 한다. 화자 자기소개, 교차 등장인물 소개(예: 다라 라사미)는 사이트마다 처음 만나는 사람에게 하듯 매번 새로 완전하게 쓴다. 교차 언급은 "~에 가시면 제 얘기를 더 들으실 수 있어요"처럼 순수 정보성 포인터로만 쓴다.
- **분량**: 기존 sites.json의 200~400자보다 훨씬 길게, 흐름의 비트를 최대한 살린 멀티 단락(추후 필요시 축약).
