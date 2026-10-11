# 큐레이션 API 업데이트 점검 및 적용 보고

검토일: 2026-10-09. 제공 폴더의 Markdown 5개(총 712줄)를 모두 확인했다.
원문 편집일은 모두 2026-10-10으로 표기되어 있다. 이 보고는 제공 명세와 현재
프런트 코드의 대조 결과이며, 서버 배포 완료 또는 실제 DB 동작을 확인한 보고는 아니다.
과거 명세 전체와의 변경 이력 비교가 아니라 이번 계약에서 확인된 사항을 정리했다.

## 1. 확인한 명세

| 문서 | API | 현재 코드와 대조 결과 |
| --- | --- | --- |
| 큐레이션 삭제 | DELETE /api/v1/curations/{curation_id} | 주소·인증·본문 없는 요청은 기존 구현과 일치. APPROVED 삭제 금지 UI를 제거함. |
| 내 큐레이션 목록 | GET /api/v1/curations/me | status 생략 시 모든 심사 상태. 기존 주소·페이징·필드 파싱 일치. 삭제 경합 처리 보완. |
| 내 큐레이션 상세 | GET /api/v1/curations/me/{curation_id} | 본인 전용 조회. 기존 이미지 정렬·날짜·수정요청 사유 파싱 일치. reviewedAt 초기화 보완. |
| 관리자 큐레이션 목록 | GET /api/v1/manager/curations | status 생략은 PENDING. 목록에 publicationStatus가 없으므로 상세에서 확인. 프로그램별 관리 후보 수집 보완. |
| 프로그램 공개 큐레이션 목록 | GET /api/v1/programs/{program_id}/curations | 공개 API. 심사 상태가 아닌 publicationStatus 기준. 기존 공개 모델 분리 유지, 전체 페이지와 삭제 후 갱신 보완. |

### 삭제 계약

- CURATOR 역할의 본인 글만 삭제 가능. MANAGER는 문서의 역할 계층에서 CURATOR 권한을 상속.
- PENDING, CHANGES_REQUESTED, APPROVED 모두 삭제 가능.
- 요청 Body 없음. 성공 응답은 `message`만 있어도 처리 가능.
- 서버가 deletedAt·deletedBy를 기록하고 publicationStatus를 UNPUBLISHED로 변경.
- 큐레이션 행, 이미지 DB·스토리지, 연결된 프로그램은 물리 삭제하지 않음.
- 삭제된 글은 본인·관리자·공개 조회, 검색, 상태별 개수 집계에서 제외.
- 삭제된 글의 수정·재제출·심사 불가. 복구 API 없음.
- 존재하지 않음·이미 삭제됨·다른 사람 글은 404/CU001.
- soft delete 저장과 접근 권한 검증은 백엔드 책임. 앱에서 삭제 상태를 임의로 만들어 API에 보내지 않음.

### 조회 계약

- 목록 page: 기본 0/최소 0, size: 기본 20/범위 1~100.
- 본인 목록 status 생략은 전체; 관리자 목록 status 생략은 PENDING.
- 본인·관리자 목록은 createdAt DESC. 공개 목록은 reviewedAt DESC. 앱에서 재정렬하지 않음.
- 본인 목록은 id, programId, submittedProgramTitle, submittedPlace, tagline,
  status, publicationStatus, createdAt, updatedAt을 포함. 본문·이미지·사유는 상세에서 조회.
- 본인 상세는 content, images(id/imageUrl/displayOrder), changeRequestReason,
  reviewedAt을 추가 제공. images는 displayOrder ASC로 파싱.
- programId는 최초 승인 전 null 가능. 재제출로 PENDING이 되어도 기존 연결 유지 가능.
- resubmit 후 changeRequestReason은 남아 있을 수 있고 reviewedAt은 null로 초기화.
- 심사 상태와 공개 상태는 별개. PENDING/PUBLISHED, CHANGES_REQUESTED/PUBLISHED도 가능.
- 관리자 목록은 curator(curatorId/role/nickname/profileImageUrl), 제출명·장소,
  tagline, status, createdAt 포함. 공개 상태·본문·이미지는 상세에서 확인.
- 공개 목록은 id, curator, tagline, nullable thumbnailUrl만 제공.
  목록에 심사/공개 상태가 없다는 이유로 프런트에서 공개 글을 숨기지 않음.
- ACTIVE/ENDED 프로그램은 공개 조회 가능. HIDDEN/삭제 프로그램은 404/P001.
- 본인 상세는 타인 글 또는 삭제 글에 404/CU001.
- 입력/페이징 오류 400/007, 인증 401/A008, 권한 403/A005,
  관리자 사용자 미존재 404/A002, 서버 오류 500/E001 계약 유지.

## 2. 실제 앱 변경

1. 작성글 목록, 본인 상세, 공개 상세의 본인 글 메뉴에서 승인 글 삭제 제한 제거.
   기존 확인 팝업 및 실패 처리 유지. DELETE 성공 뒤에만 화면을 갱신/닫음.
2. 공개 상세에서 삭제 후 돌아오면 공개 카드 목록을 다시 조회하고 상세 캐시를 초기화.
   삭제 성공 ID는 현재 섹션에서 즉시 제외. 수정 후에도 상세 캐시를 갱신.
3. 공개 큐레이션 목록은 첫 페이지만 읽던 부분을 모든 페이지 조회로 변경.
4. 목록 조회 뒤 상세 조회 중 삭제되어 CU001이 반환되면 본인 목록의 요약 데이터로
   되살리지 않음. 500 등 일시적 상세 실패는 기존 요약 유지 정책을 보존.
5. 공개 상세의 CU001 응답에서 기존 카드 요약을 글 본문처럼 다시 표시하지 않음.
6. 프로그램별 관리자 화면은 세 심사 상태를 각각 조회하고 상세의 programId로 연결을 판단.
   목록에 없는 publicationStatus를 추정하지 않음. 삭제된 상세만 제외하고 다른 글은 유지.
   이전에 기억한 ID도 최신 상세 결과로 교체해 삭제 ID가 계속 남지 않도록 함.
7. 상세 병합에서 reviewedAt:null을 반영해 재제출 전의 심사 시간이 잔류하지 않도록 수정.

## 3. 검증 및 한계

- 전체 Flutter 테스트 169건 통과.
- Android debug APK 및 iOS 시뮬레이터 debug 빌드 성공.
- 추가한 soft delete/조회 회귀 테스트: 14건. 세 상태의 본인 상세 삭제를
  Android/iOS 설정에서 확인; 승인 목록 삭제·개수 갱신·실패·취소·공개 상세 삭제 및
  공개 목록 갱신·삭제 상세 대체표시 방지·추가 페이지 조회·CU001 경합·reviewedAt 초기화 확인.
- 관리자 삭제 경합 테스트 1건 추가: 삭제 글을 제외하고 나머지 카드 표시.
- 최초 새 화면 테스트 2건은 작성자 로그인 상태를 설정하지 않아 메뉴를 못 찾았음.
  테스트에 작성자 인증 상태를 설정한 후 재실행하여 통과.
- 최초 분석에서 새 테스트의 if 중괄호 정보성 알림 1건을 발견하고 수정.
- 변경 코드/테스트 9개 분석: 이상 없음. 공백 검사 통과.
- 전체 분석에 남은 정보성 알림 8건: isNew_badge.dart 파일명 1건;
  recent_search_widget.dart:37, searchbar.dart:99/146,
  stat_card_widget.dart:42, find_password_screen.dart:100,
  verification_code_screen.dart:209, app_toast.dart:47의 deprecated SVG color 7건.
- Android 빌드에서 플러그인 KGP 향후 호환성 및 Java source/target 8 경고가 남음.
- 테스트는 가짜 서비스/응답을 사용. 실제 계정 글 삭제, 실제 DB의 deletedAt/deletedBy,
  이미지 보존, 운영 서버의 권한·삭제 제외·개수 집계는 실행/검증하지 않음.
- 제공 자료에는 공개 상세·관리자 상세 등 전체 API 계약이 없으므로 해당 응답을
  임의로 바꾸거나 새로운 필드를 요구하지 않음.
- 작업 시작 시 존재하던 program_poster_carousel.dart 및 pubspec.yaml 변경은 건드리지 않음.
