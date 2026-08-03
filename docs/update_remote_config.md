# 앱 업데이트 Remote Config 운영 방법

문틈 앱은 실행 시 Firebase Remote Config에서 최신·최소 지원 버전을 확인한다.
Remote Config 조회에 실패하거나 `update_enabled`가 `false`이면 앱 이용을 막지 않는다.

## 파라미터

| 키 | 타입 | 설명 |
| --- | --- | --- |
| `update_enabled` | Boolean | 업데이트 확인 활성화 여부 |
| `update_title` | String | 안내 모달 제목 |
| `update_message` | String | 안내 모달 설명 |
| `android_latest_version` | String | 최신 권장 Android `versionName` |
| `android_latest_build` | Number | 최신 권장 Android `versionCode` |
| `android_minimum_version` | String | 최소 지원 Android `versionName` |
| `android_minimum_build` | Number | 최소 지원 Android `versionCode` |
| `android_store_url` | String | Google Play URL |
| `ios_latest_version` | String | 최신 권장 iOS `CFBundleShortVersionString` |
| `ios_latest_build` | Number | 최신 권장 iOS `CFBundleVersion` |
| `ios_minimum_version` | String | 최소 지원 iOS `CFBundleShortVersionString` |
| `ios_minimum_build` | Number | 최소 지원 iOS `CFBundleVersion` |
| `ios_store_url` | String | App Store URL |

## 출시 순서

1. `update_enabled=false` 상태에서 새 앱을 심사·출시한다.
2. 스토어에서 새 버전을 실제로 설치할 수 있는지 확인한다.
3. 해당 플랫폼의 `latest_version`, `latest_build`를 새 버전으로 수정한다.
4. 선택 업데이트라면 `minimum_version`, `minimum_build`는 기존 값을 유지한다.
5. 강제 업데이트라면 `minimum_version`, `minimum_build`도 새 최소 지원 버전으로 수정한다.
6. `update_enabled=true`로 변경하고 Remote Config를 게시한다.

두 스토어의 공개 시점이 다르면 먼저 공개된 플랫폼의 최신 값만 변경한다. 다른 플랫폼의
최신 값은 기존 값으로 두면 그 플랫폼에는 모달이 나타나지 않는다.

## 모달 동작

- 설치 버전이 최신 권장 버전보다 낮음: `나중에`, `지금 업데이트` 표시
- 설치 버전이 최소 지원 버전보다 낮음: `지금 업데이트`만 표시하고 뒤로가기 차단
- `version`이 같을 때는 `build` 번호를 비교한다.
- 앱 버전이 Remote Config 버전보다 높은 개발 빌드라면 모달을 표시하지 않는다.

## 배포 명령

저장소의 `remoteconfig.template.json`을 수정한 경우 다음 명령으로 게시한다.

```sh
firebase deploy --only remoteconfig --project muntum-9e227
```

Remote Config 파일 게시 방식은 기존 원격 템플릿 전체를 교체하므로, 콘솔에서 직접 수정한
파라미터가 있다면 먼저 원격 템플릿을 내려받아 병합해야 한다.
