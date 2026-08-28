# 치앙마이 역사 (ChiangMaiHistory)

치앙마이 여행 중 지오펜싱으로 근처 유적지에 들어서면 역사 정보 팝업을 띄워주는 iOS 앱입니다.

## 구성
- SwiftUI + Google Maps SDK for iOS (지도 표시)
- CoreLocation 지역 모니터링 (`CLCircularRegion`)으로 지오펜싱 — 앱이 백그라운드에 있어도 반경에 들어오면 로컬 알림 발송
- `Sources/Resources/sites.json`에 직접 큐레이션한 치앙마이 유적지 17곳 (좌표, 반경, 역사 설명)

## 시작하기 전 필요한 것
1. **Xcode** (App Store에서 설치)
2. **Google Maps SDK for iOS용 API 키**
   - [Google Cloud Console](https://console.cloud.google.com/)에서 프로젝트 생성
   - "Maps SDK for iOS" API 활성화
   - API 키 발급 후, 앱 번들 ID(`com.chiangmaihistory.app`)로 키 사용 제한 설정 (보안 권장)
   - 결제 계정 연결 필요 (매달 무료 크레딧 제공, 여행 앱 수준 사용량이면 대부분 무료 범위 내)

## 실행 방법
1. `ChiangMaiHistory.xcodeproj`를 Xcode로 엽니다.
2. `Sources/APIKeys.swift`의 `YOUR_GOOGLE_MAPS_IOS_API_KEY`를 실제 발급받은 키로 교체합니다.
3. 시뮬레이터 또는 실기기에서 실행합니다.
   - 시뮬레이터: Xcode의 `Features > Location`에서 치앙마이 좌표(예: 18.7883, 98.9853)로 위치를 지정하면 지오펜스 진입을 테스트할 수 있습니다.
   - 실기기(여행 중 권장): 위치 권한을 **"항상 허용"**으로 설정해야 앱이 꺼져 있어도 알림이 옵니다.

## 프로젝트 재생성
`project.yml`을 수정한 뒤에는 아래 명령으로 `.xcodeproj`를 다시 생성하세요.

```bash
xcodegen generate
```

## 유적지 데이터 추가/수정
`Sources/Resources/sites.json`에 아래 형식으로 항목을 추가하면 됩니다.

```json
{
  "id": "고유_id",
  "name": "한글 이름",
  "nameThai": "ไทย ชื่อ",
  "latitude": 18.0000,
  "longitude": 98.0000,
  "radiusMeters": 100,
  "category": "사원",
  "yearBuilt": "몇 년",
  "historicalFact": "역사 설명"
}
```

> iOS는 앱당 동시에 최대 20개의 지오펜스만 모니터링할 수 있습니다. 유적지가 20곳을 넘으면 앱이 사용자 위치에서 가까운 20곳을 자동으로 우선 모니터링하도록 되어 있습니다 (`LocationManager.swift` 참고).

## 알려진 제한사항 (MVP)
- 지도는 Google Maps, 위치/지오펜싱은 Apple CoreLocation을 사용합니다 (지도 SDK와 무관하게 iOS 표준 방식).
- 이미지/사진은 아직 포함하지 않았습니다. 필요하면 `HistoricalSite`에 이미지 필드를 추가하고 `SitePopupView`에 표시하면 됩니다.
- 오프라인에서는 Google 지도 타일 로딩이 안 될 수 있습니다 (지오펜싱 알림 자체는 인터넷 없이도 동작).
