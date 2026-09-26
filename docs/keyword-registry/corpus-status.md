# 코퍼스 처리 현황

Google Drive 폴더의 학술 논문/저서 코퍼스(치앙마이/란나 역사) 처리 현황입니다. "산출"은 Table A에 신규로 추가된 키워드 수를 의미합니다(Table D 보강만 있고 신규 키워드가 없는 경우 0건으로 표기, 배경사 참고 자료로서의 가치와는 무관).

## 처리 완료 (32편)

| 저자·제목 | 유형 | 신규 키워드 |
|---|---|---|
| Ng/Wood/Ziegler 외, Wiang Kum Kam 관련 (s11069) | 고고학 | 10건 |
| Wannida Teeratusananan & Li Cansong, "왓 치앙만의 역사와 미술" | 미술사 | 12건(1차) + 확인 위주 재독 |
| 왓 파랏 논문(Kirdsiri & Buranaut) | 건축사 | 8건 |
| Penth, "Which Ratanapañña Composed the Jinakalamali?" | 문헌학 | 5건 |
| Penth, "History of Wat Umong Thera Jan" (JSS 62) | 문헌학 | 8건 |
| Phar Arriyananda 외, 치앙마이-람푼 구도로 고무나무 관리 | 행정학(저용량) | 3건 |
| Waraporn Ruangsri, 우본완나 여성사 (Thammasat, 2023) | 여성사 | 5건(1차) + 확인 위주 재독 |
| Sunkanaporn, 산파통 문화자본 (Veridian) | 지역문화 | 4건 |
| Ruenkhum et al., 왓 수언독 불교관광 | 종교관광학 | 7건 |
| Sukmanee & Arayaphan, JIL 사원·비하라 지식체계 | 문헌정보학 | 6건 |
| Bowie, "Dating the First Arrest of Khruba Srivichai" (JSS 111) | 역사학 | 4건 |
| Bowie, "Erasure" (Modern Asian Studies, 2025) | 역사학 | 3건 |
| Castro-Woodhouse, *Woman between Two Kingdoms* ch.2 "Dara Rasami's Career" | 여성사 | 4건 |
| Castro-Woodhouse, 同 ch.3 "Performing Identity and Ethnicity" | 여성사 | 5건 |
| Castro-Woodhouse, 同 ch.4 "Inventing Lan Na Tradition" | 여성사 | 6건 |
| Castro-Woodhouse, 同 ch.1 "Introducing Lan Na" | 여성사 | 0건(보강만) |
| Castro-Woodhouse, 同 ch.5 "Intertwined Fates"(=단행본 全 재독 시 포함) | 정치사(거시) | 0건 — 태국 왕실 일부다처제 정치사, 특정 사이트 무관 |
| Easum, *Chiang Mai Between Empire and Modern Thailand* (1~2장만; 3~5장은 변환 오류로 미확보) | 도시사 | 6건 |
| Turton, "Remembering Local History: Kuba Wajiraphanya" | 지역사 | 0건(보강만) |
| UNESCO WHTL-doc-6003(세계유산 잠정목록 신청서) | 공식 문서 | 4건 |
| Grabowsky, "Population and State in Lan Na prior to Mid-16th Century" (JSS 93) | 인구사 | 1건 |
| Rhum, "The Cosmology of Power in Lanna" (JSS 75) | 인류학 | 2건 |
| Vickery, "Piltdown 3" (JSS 83) | 문헌학 | 2건 |
| Penth, "Date of Wat Bang Sanuk Inscription" (JSS 84) | 명문학(저용량) | 1건(확장 후보) |
| Renard, "The Image of Chiang Mai" (JSS 87) | 도시사 | 2건 |
| Denes & Pradit, "Chiang Mai's Intangible Cultural Heritage" | 문화인류학 | 3건 |
| Sumonvarangkul & Thaitakoo, "Riverscape Chiang Mai" | 경관생태학 | 3건 |
| "Ethnic Settlement Patterns in Lanna" (Arayaphan & Niemsup) | 문헌정보학(저용량) | 0건 |
| Sarawut Wisaphrom, "란나 문화 상품화 역사" | 사회학(저용량) | 2건 |
| Jared Kirkey, "Tourism and Tradition in Chiang Mai" (2020) | 관광학(저용량) | 1건 |
| Grabowsky, "Forced Resettlement Campaigns in Northern Thailand" (JSS 87) | 인구사 | 5건 |
| Penth, "On the History of Chiang Rai" (파일명은 "HistoryOfChiangMai"였으나 실제로는 치앙라이 논문) | 왕조사(저용량) | 2건 |
| Ken Kirigaya, "Lan Na under Burma: A 'Dark Age'?" (JSS 103) | 수정주의 사학(저용량) | 0건 |

## 미처리 (3편)

1. **Castro-Woodhouse 단행본 5장(정치사 결론부)** — 처리는 했으나(위 표에 포함) 신규 키워드 없음, 별도 챕터가 아니라 단행본 통독의 일부로 확인 완료.
2. **Easum, 3~5장(영국영사관 미시식민지 변형, 나와랏 다리 등 도시 근대화, 크루바 시위차이 성역 복원 캠페인)** — Google Drive `read_file_content` 변환 오류로 각주 하이퍼링크 잔해만 남고 본문 유실. **이후 세션에서 `download_file_content`로 원본 PDF를 통째로 받아 로컬 `pypdf`로 직접 파싱하는 방법이 성공적으로 검증되었음** (Dara Rasami 책·Kirkey 논문 등에 적용) — 같은 방법을 Easum 책에도 시도할 수 있으나, 이 책은 11.8MB로 `download_file_content`의 10MB 제한을 초과해 별도 우회가 필요함(예: 페이지 분할 다운로드).
3. 원래 "35편" 목표 대비 실제 Drive 폴더에는 중복 파일(동일 내용, 파일명만 다름)이 다수 섞여 있어, 순수 고유 논문 수는 32~33편으로 추정됨 — 목록에 없는 편이 있다면 Google Drive 폴더(`parentId: 1uxasZUsqcpuG2HcQPZo0TUnl1HOthJ9k`)를 재조회해 확인 필요.

## 다음 단계 후보

- Easum 책 3~5장 재확보 시도 (기술적으로 가능성 있음, 위 참고)
- 전체 키워드 간 2차 중복 점검 (이 레지스트리 작성 시 1차 점검은 완료했으나, 특히 크루바 시위차이·다라 라사미 관련 키워드는 워낙 많은 논문에 걸쳐 나와 재검토 여지가 있음)
- `wat_sri_suphan_wihan_1503` 등 Table C 미등록 키워드의 정식 편입
