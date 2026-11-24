# 카카오 로그인 로컬 설정

1. Git에서 제외된 프로젝트 루트 `.env`에 `KAKAO_NATIVE_APP_KEY`를 설정합니다. 값은 팀에서 전달받으며 `.env.example`에는 예시만 유지합니다.
2. Android는 빌드 시 `.env`에서 복귀 URI를 설정합니다.
3. iOS는 `pod install` 시 `.env`를 읽어 Git에서 제외된 `ios/Flutter/Kakao.local.xcconfig`를 생성합니다. 키를 변경했다면 `ruby tool/configure_kakao.rb`를 실행한 뒤 앱을 다시 빌드합니다. 핫 리로드만으로는 네이티브 설정이 바뀌지 않습니다.

키가 없으면 카카오 로그인만 설정 안내를 표시하며, 다른 로그인과 둘러보기는 사용할 수 있습니다. CI에서도 빌드 전에 `.env`를 공급하고 iOS 설정 생성 단계를 실행해야 합니다.

Native App Key는 앱에 포함되는 클라이언트 식별자입니다. 이 구성은 저장소에 실제 값을 올리지 않기 위한 것이며, 배포 앱에서 값을 완전히 숨기는 방법은 아닙니다. 카카오 콘솔의 패키지명·키 해시·Bundle ID 제한도 유지해야 합니다. Admin Key, Client Secret, 서명용 개인 키 등 서버 전용 비밀은 앱 소스나 `.env` 자산에 넣지 않습니다.
