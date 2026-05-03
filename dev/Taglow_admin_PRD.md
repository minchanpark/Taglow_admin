# Taglow 관리자 서비스 PRD v0.2

## 0. 문서 개요

### 문서 목적
본 문서는 **Taglow 관리자 서비스**의 제품 요구사항과 구조 요구사항을 정의한다.
운영자가 참여자 서비스와 스탠바이미 실시간 화면이 사용할 `vote`와 `question` 데이터를 생성하고 관리할 수 있도록, 관리자용 Flutter Web 프로젝트의 MVP 범위를 고정한다.
또한 참여자 프로젝트의 서버-Service-Model-Controller 흐름을 관리자 프로젝트에도 동일하게 적용하는 기준을 명시한다.

### 문서 범위
이 PRD는 **관리자용 서비스**만 다룬다.

포함 범위:
- Spring ADMIN 로그인
- vote 생성, 조회, 수정, 상태 변경, 삭제
- question 생성, 조회, 수정, 삭제
- question 이미지 S3 업로드
- 참여자 URL과 스탠바이미 확인 URL 제공
- 저장 결과가 공개 참여자 API와 스탠바이미 API에서 읽히는지 확인하는 운영 미리보기
- 참여자 프로젝트의 `View -> Controller -> Service` 호출 흐름과 `api/model`, Gateway/Mapper 계층을 관리자 프로젝트에 적용하는 기준

제외 범위:
- 참여자용 모바일 태깅 화면
- 스탠바이미 실시간 화면 자체
- 태그 승인/숨김/삭제 운영 UI
- 태그 분석 대시보드
- 리워드 사용자 관리
- CSV/리포트 export
- AI 요약/분석
- 조직/팀/결제/멤버십 관리

### 핵심 제품 원칙
> 관리자는 코드를 수정하거나 S3 콘솔을 직접 다루지 않고도, 현장 투표와 질문 이미지를 만들고 즉시 QR 참여 URL을 얻을 수 있어야 한다.

관리자 서비스는 참여자 경험을 직접 제공하는 서비스가 아니라, 참여자와 스탠바이미가 소비하는 운영 데이터를 만드는 **콘텐츠 운영 도구**다.

구조 원칙:
- API 저장/조회 기능은 `View -> Controller -> Service -> Gateway/Mapper -> Generated Client/Dio -> Server` 흐름을 따른다.
- 이미지 업로드는 Service 계층 안에서 S3 API를 감춰 View/Controller가 storage 구현을 알지 않게 한다.
- Controller와 Service가 공유하는 데이터는 안정적인 관리자 domain model이어야 한다.
- View와 Controller는 Spring DTO, generated API client, S3 SDK를 직접 참조하지 않는다.
- 서버 API 변경은 Gateway와 Mapper에서 먼저 흡수한다.

---

## 1. 제품 정의

### 1-1. 제품명
**Taglow 관리자 서비스**

### 1-2. 한 줄 정의
운영자가 Spring ADMIN 계정으로 로그인해 vote와 question을 만들고, 질문 이미지를 S3에 업로드한 뒤, 참여자 URL과 스탠바이미 표시 데이터를 준비하는 Flutter Web 관리자 도구.

### 1-3. 핵심 가치
- 운영자는 개발자 도움 없이 vote와 question을 만들 수 있다.
- 이미지 업로드, URL 생성, question 생성이 하나의 흐름으로 연결된다.
- 참여자 서비스와 스탠바이미 화면이 같은 서버 데이터를 읽으므로 운영 데이터가 일관된다.
- API 스펙이 바뀌어도 Flutter 관리자 View/Controller 수정이 최소화되도록 한다.
- 관리자 프로젝트도 참여자 프로젝트와 같은 서버-Service-Model-Controller 구조를 따라 장기 유지보수 비용을 낮춘다.

---

## 2. 사용자 정의

## 2-1. 1차 사용자: 현장 운영자

### 상황
축제, 전시, 데모데이, 팝업스토어 현장에서 운영자가 태깅 참여용 투표와 질문 이미지를 준비한다.

### 니즈
- 로그인 후 바로 새 vote를 만들고 싶다.
- 질문 이미지를 업로드하면 URL이 자동으로 연결되면 좋겠다.
- 참여자 QR URL을 바로 복사하고 싶다.
- 스탠바이미 화면에서 제대로 보일지 미리 확인하고 싶다.
- 운영 중 vote 상태를 진행/종료로 바꾸고 싶다.

### 설계 포인트
- 화면은 운영 도구답게 조용하고 밀도 있게 구성한다.
- 입력 폼은 실수 방지를 위해 저장 전 검증과 미리보기를 제공한다.
- 저장 후 바로 참여자 URL을 확인할 수 있어야 한다.

## 2-2. 2차 사용자: 개발/운영 관리자

### 상황
서버 API, S3, 배포 설정을 확인하고 운영 중 문제를 점검한다.

### 니즈
- 현재 API base URL과 배포 origin을 확인하고 싶다.
- 이미지 업로드 실패와 API 저장 실패를 구분하고 싶다.
- 공개 API에서 실제로 데이터가 내려오는지 확인하고 싶다.

### 설계 포인트
- 오류 메시지는 운영자가 조치할 수 있게 구체적이어야 한다.
- 서버 DTO나 내부 API 이름이 화면에 그대로 노출되지 않아야 한다.
- 디버그 정보는 운영 화면이 아니라 개발자 콘솔/로그 중심으로 둔다.

---

## 3. 목표와 비목표

### 3-1. 목표
1. ADMIN 사용자가 로그인 후 vote를 생성할 수 있다.
2. ADMIN 사용자가 vote 이름과 상태를 수정할 수 있다.
3. ADMIN 사용자가 vote 안에 question을 생성할 수 있다.
4. ADMIN 사용자가 question 이미지를 S3에 직접 업로드할 수 있다.
5. question 저장 시 서버에는 이미지 bytes가 아니라 `imageUrl`과 `imageRatio`만 전달한다.
6. 저장된 vote/question은 참여자 공개 API와 스탠바이미 display API에서 읽혀야 한다.
7. 관리자 화면에서 참여자 URL `https://taglow-acca6.web.app/e/{voteId}`를 복사할 수 있다.
8. Flutter View/Controller는 서버 API DTO를 직접 알지 않고 안정적인 domain model만 사용한다.
9. 로그인, vote 관리, question 관리, 공개 API 미리보기는 모두 `View -> Controller -> Service -> Gateway/Mapper` 계층을 통해 수행한다.
10. question 이미지 업로드는 Controller가 storage SDK를 직접 쓰지 않고 `QuestionImageUploadService`를 통해 수행한다.

### 3-2. 비목표
1. 태그 승인/숨김/moderation은 MVP 범위에서 제외한다.
2. 태그 통계, 히트맵, 리워드 사용자 목록은 MVP 범위에서 제외한다.
3. 관리자 다중 조직/권한 세분화는 MVP 범위에서 제외한다.
4. 이미지 편집, 크롭, 리사이즈 도구는 MVP 범위에서 제외한다.
5. 실시간 스탠바이미 원격 제어는 MVP 범위에서 제외한다.
6. Spring 서버 모델을 그대로 노출하는 CRUD 생성기는 만들지 않는다.

---

## 4. 핵심 운영 플로우

## 4-1. 로그인 플로우

1. 관리자가 관리자 URL에 접속한다.
2. 로그인 화면에서 계정명과 비밀번호를 입력한다.
3. Spring `POST /api/auth/login`으로 인증한다.
4. `GET /api/auth/me` 또는 `GET /api/users/me`로 현재 사용자와 role을 확인한다.
5. `ADMIN` role이 있으면 관리자 홈으로 이동한다.
6. 권한이 없으면 접근 불가 상태를 표시한다.

## 4-2. vote 생성 플로우

1. 관리자가 새 vote 만들기를 누른다.
2. vote 이름을 입력한다.
3. 저장하면 서버에 vote 생성 요청을 보낸다.
4. 생성된 vote는 기본 상태 `PROGRESS` 또는 서버 기본 상태로 표시된다.
5. 관리자는 vote 상세 화면으로 이동해 question을 추가한다.

## 4-3. question 생성 플로우

1. 관리자가 vote 상세 화면에서 question 추가를 누른다.
2. 제목, 상세 설명을 입력한다.
3. 질문 이미지를 선택한다.
4. Flutter가 이미지 bytes를 S3에 직접 업로드한다.
5. 업로드 완료 후 `imageUrl`과 이미지 원본 비율 `imageRatio`를 계산한다.
6. 서버에 question 생성 요청을 보낸다.
7. 저장된 question이 vote 상세 목록에 표시된다.
8. 공개 API 미리보기로 참여자/스탠바이미에서 읽히는지 확인한다.

## 4-4. 참여 URL 확인 플로우

1. 관리자가 vote 상세 화면에서 참여 URL 섹션을 확인한다.
2. 참여자 URL은 `https://taglow-acca6.web.app/e/{voteId}` 형식으로 표시된다.
3. 복사 버튼으로 URL을 복사할 수 있다.
4. 스탠바이미 확인 URL은 별도 player 프로젝트 라우트 기준으로 표시한다.
5. MVP에서는 QR 이미지를 서버에서 생성하지 않고, URL 복사와 미리보기 중심으로 제공한다.

## 4-5. vote 상태 변경 플로우

1. 운영자가 vote 상세 화면에서 상태를 확인한다.
2. `PROGRESS` 상태는 참여자/스탠바이미 노출 가능 상태다.
3. `END` 상태는 운영 종료 상태다.
4. 상태 변경 후 공개 API 응답의 status가 일치하는지 확인한다.

## 4-6. 서버 연동 계층 플로우

모든 운영 플로우는 다음 계층 책임을 따른다.

```text
View
  LoginPage / VoteListPage / VoteDetailPage / QuestionEditorPage
    ↓ user action
Controller
  AuthController / VoteListController / VoteDetailController / QuestionEditorController
    ↓ domain API call
Service
  AdminService / MockAdminService / OpenApiAdminService / QuestionImageUploadService
    ↓ API payload conversion or storage operation
Gateway / Mapper
  AdminApiGateway / AdminPayloadMapper
    ↓ generated client and Dio
External Client / Storage
  Generated API Client / Dio / S3 API
    ↓
Server / Storage
  Spring Boot API / AWS S3

Model
  AdminUser / AdminVote / AdminQuestion / QuestionImageUploadResult
```

정책:
- View는 Controller 상태를 렌더링하고 사용자 입력만 전달한다.
- Controller는 `AdminService` 계약과 관리자 domain model만 사용한다.
- Service는 서버 저장, 공개 API 확인, 이미지 업로드 같은 유스케이스를 조합한다.
- Mapper는 서버 payload와 관리자 domain model 사이 변환만 담당한다.
- Gateway는 endpoint, path, header, cookie, generated DTO 변화를 감싼다.
- Mock과 OpenAPI 구현체는 같은 `AdminService` 계약을 구현하므로 View/Controller 교체가 필요 없어야 한다.

---

## 5. 정보 구조

```text
관리자 웹
├── 로그인 화면
├── vote 목록 화면
│   ├── 새 vote 생성
│   ├── vote 검색/상태 필터
│   └── vote 카드/테이블
├── vote 상세 화면
│   ├── vote 기본 정보
│   ├── 상태 변경
│   ├── 참여자 URL/복사
│   ├── 공개 API 미리보기
│   └── question 목록
├── question 작성/수정 화면
│   ├── 제목/상세 입력
│   ├── 이미지 업로드
│   ├── 이미지 비율 미리보기
│   └── 저장/취소
└── 설정/진단 화면
    ├── API base URL
    ├── S3 설정 상태
    └── 배포 origin 안내
```

---

## 6. 화면별 요구사항

# A1. 로그인 화면

## 화면 목적
ADMIN 사용자만 관리자 기능에 접근하게 한다.

## 주요 UI
- 계정명 입력
- 비밀번호 입력
- 로그인 버튼
- 로그인 실패 메시지

## 기능 요구사항
- 로그인 성공 시 현재 사용자 role을 확인한다.
- `ADMIN` role이 없으면 관리자 홈에 진입하지 않는다.
- 로그인 중 중복 제출을 막는다.
- 비밀번호는 저장하지 않는다.

## 성공 기준
- 정상 ADMIN 계정은 vote 목록으로 이동한다.
- 실패 시 사용자에게 다시 시도할 수 있는 메시지가 표시된다.

# A2. vote 목록 화면

## 화면 목적
운영자가 만든 vote를 확인하고 새 vote를 생성한다.

## 주요 UI
- 상단 작업 바
- 새 vote 버튼
- vote 목록 테이블 또는 리스트
- 상태 chip: `PROGRESS`, `END`
- 상세 진입 버튼

## 기능 요구사항
- 서버에서 vote 목록을 조회한다.
- vote 이름, ID, 상태, 생성/수정 시각을 표시한다.
- 새 vote 생성 drawer 또는 dialog를 제공한다.
- 목록 로딩, 빈 상태, 오류, 재시도 상태를 제공한다.

## 성공 기준
- 운영자는 vote 목록에서 원하는 vote를 찾고 상세로 이동할 수 있다.
- 새 vote 생성 후 목록에 즉시 반영된다.

# A3. vote 상세 화면

## 화면 목적
하나의 vote에 포함된 question과 운영 URL을 관리한다.

## 주요 UI
- vote 이름과 상태
- 이름 수정 버튼
- 상태 변경 control
- 참여자 URL 복사 버튼
- 스탠바이미 확인 URL 표시
- question 목록
- question 추가 버튼

## 기능 요구사항
- `GET /api/votes/{voteId}`와 `GET /api/votes/{voteId}/questions` 결과를 조합한다.
- vote 이름과 상태를 수정할 수 있다.
- 참여자 URL은 voteId 기반으로 생성한다.
- 공개 API 미리보기는 `GET /api/public/votes/{voteId}/display`와 `GET /api/public/votes/{voteId}/questions` 결과를 확인한다.

## 성공 기준
- vote 상세에서 question을 생성하고 참여 URL을 복사할 수 있다.
- 저장된 데이터가 공개 API에서도 확인된다.

# A4. question 작성/수정 화면

## 화면 목적
참여자 화면에 표시될 질문 이미지와 설명을 만든다.

## 주요 UI
- question 제목 입력
- 상세 설명 입력
- 이미지 선택 영역
- 업로드 진행 상태
- 업로드된 이미지 미리보기
- imageRatio 표시
- 저장 버튼

## 기능 요구사항
- 이미지는 관리자 Flutter가 S3에 직접 업로드한다.
- 서버에는 `imageUrl`, `imageRatio`, `title`, `detail`, `voteId`만 전송한다.
- 이미지 비율은 원본 width / height 기준으로 계산한다.
- `imageRatio`는 반응형 참여자 화면에서 이미지 bounds 계산에 쓰인다.
- 저장 실패 시 업로드 성공/서버 저장 실패를 구분해 표시한다.

## 성공 기준
- 운영자는 S3 콘솔 없이 question 이미지를 업로드하고 저장할 수 있다.
- 저장 후 참여자 화면에서 이미지가 표시된다.

# A5. 설정/진단 화면

## 화면 목적
운영/개발자가 관리자 배포와 API/S3 연결 상태를 점검한다.

## 주요 UI
- API base URL
- 관리자 배포 origin
- S3 bucket/region 설정 표시
- CORS 안내
- 공개 API quick check 버튼

## 기능 요구사항
- secret이나 AWS access key는 표시하지 않는다.
- S3 업로드 설정 누락 시 question 저장 전 명확히 알린다.
- CORS 문제와 인증 문제를 구분해 안내한다.

---

## 7. 데이터 모델

## 7-1. AdminUser

관리자 로그인 사용자.

필드 예시:
- `userId`
- `name`
- `roles`
- `isAdmin`

## 7-2. AdminAuthSession

현재 로그인 상태.

필드 예시:
- `user`
- `isAuthenticated`
- `isLoading`
- `errorMessage`

## 7-3. AdminVote

관리자가 생성하는 참여 단위. 서버 도메인에서는 `vote`다.

필드 예시:
- `id`
- `name`
- `status`: `PROGRESS | END`
- `createdByUserId`
- `createdAt`
- `updatedAt`
- `participantUrl`
- `displayPreviewUrl`

## 7-4. AdminQuestion

vote 안에서 참여자가 선택하고 태그를 남기는 이미지 자료 단위.

필드 예시:
- `id`
- `voteId`
- `title`
- `detail`
- `imageUrl`
- `imageRatio`
- `createdAt`
- `updatedAt`

## 7-5. QuestionImageUploadResult

관리자 Flutter가 S3에 업로드한 이미지 결과.

필드 예시:
- `objectKey`
- `publicUrl`
- `contentType`
- `sizeBytes`
- `imageWidth`
- `imageHeight`
- `imageRatio`

---

## 8. API와 도메인 분리 정책

관리자 Flutter는 Spring API와 서버 DTO를 View/Controller에서 직접 알지 않는다.

원칙:
- View는 Controller만 사용한다.
- Controller는 `AdminService` domain API만 호출한다.
- `OpenApiAdminService`는 `AdminApiGateway`와 `AdminPayloadMapper`를 조합한다.
- `AdminApiGateway`는 endpoint, path, header, generated client 변화를 흡수한다.
- `AdminPayloadMapper`는 서버 payload와 관리자 domain model 사이 변환만 담당한다.
- 서버 API가 바뀌어도 View/Controller는 가능하면 수정하지 않는다.

이 정책은 현재 참여자 서비스의 `ParticipantApiGateway`와 `ParticipantPayloadMapper` 구조를 관리자 프로젝트에 동일하게 적용하는 것이다.

계층별 금지 사항:

| 계층 | 허용 | 금지 |
|---|---|---|
| View | Controller provider 구독, UI 렌더링, 사용자 입력 전달 | Dio 호출, generated DTO import, S3 SDK 호출 |
| Controller | domain model 상태 관리, validation, `AdminService` 호출 | endpoint 문자열 보유, payload key 직접 조립 |
| Service | 유스케이스 orchestration, mapper/gateway 조합 | Widget import, 화면 전용 상태 보유 |
| Mapper | payload와 domain model 변환 | 네트워크 호출, Riverpod provider 참조 |
| Gateway | endpoint, header, cookie, generated client 호출 | domain UI 상태 관리, Widget import |

---

## 9. 보안 및 개인정보 정책

### 9-1. 인증과 권한
- 관리자 서비스는 로그인 없이 접근할 수 없다.
- ADMIN role이 없는 사용자는 vote/question 관리 화면에 접근할 수 없다.
- Spring session/cookie 인증을 기본으로 한다.
- 클라이언트는 서버 secret, AWS access key, 관리자 비밀번호를 저장하지 않는다.

### 9-2. S3 보안
- Flutter에는 장기 AWS access key를 넣지 않는다.
- S3 업로드는 Cognito 임시 자격 증명 또는 서버 발급 upload policy를 사용한다.
- MVP 기본값은 Cognito/Amplify 기반 S3 직접 업로드다.
- 질문 이미지 prefix는 `public/question-images`를 기본으로 한다.

### 9-3. 데이터 노출
- 관리자 화면은 참여자 개인정보를 다루지 않는다.
- 리워드 사용자 데이터는 MVP 범위가 아니다.
- 공개 참여자 API에 노출될 vote/question 데이터만 생성한다.

---

## 10. QA 시나리오

### 기본 생성 시나리오
1. ADMIN 사용자가 로그인한다.
2. vote 목록 화면에 진입한다.
3. 새 vote를 생성한다.
4. vote 상세 화면에서 question 추가를 누른다.
5. 이미지를 선택하고 업로드한다.
6. 제목과 상세 설명을 입력한다.
7. question을 저장한다.
8. 참여자 URL을 복사한다.
9. 공개 API 미리보기에서 vote/question이 보이는지 확인한다.

### 상태 변경 시나리오
1. vote 상세 화면에 진입한다.
2. 상태를 `END`로 변경한다.
3. 공개 display API의 status도 `END`로 내려오는지 확인한다.

### 실패 시나리오
- 로그인 실패 시 vote 목록에 접근하지 못한다.
- ADMIN role이 없으면 접근 불가 상태가 표시된다.
- S3 업로드 실패 시 question 저장은 실행되지 않는다.
- S3 업로드 성공 후 서버 저장 실패 시 재시도할 수 있다.
- `imageUrl` 또는 `imageRatio`가 없으면 question 저장을 막는다.
- CORS 실패와 인증 실패를 운영자가 구분할 수 있어야 한다.

---

## 11. 오픈 이슈

| 항목 | 내용 |
|---|---|
| 관리자 배포 도메인 | Firebase Hosting을 쓸지 AWS Hosting을 쓸지 확정 필요 |
| vote 생성 endpoint | 현재 OpenAPI의 `POST /api/public/votes`는 관리자 생성 API로는 부적절하므로 ADMIN 보호 endpoint 확정 필요 |
| imageRatio 타입 | 현재 OpenAPI는 integer지만 반응형 이미지 계산에는 double 필요 |
| 인증 방식 | Spring session/cookie 기본. 토큰 방식으로 바뀌면 TDD의 auth gateway에서 흡수 |
| CloudFront | AWS 계정 검증 완료 전에는 S3 public URL fallback 허용 |
| 태그 moderation | MVP 이후 관리자 서비스 확장 단계에서 별도 PRD/TDD 필요 |

---

## 12. 최종 구현 기준 요약

Taglow 관리자 서비스는 운영자가 vote와 question을 직접 준비할 수 있게 하는 별도 Flutter Web 서비스다.

최종 기준:
1. ADMIN 사용자만 접근할 수 있어야 한다.
2. vote와 question 생성/수정/삭제가 가능해야 한다.
3. question 이미지는 S3에 직접 업로드되어야 한다.
4. 서버에는 이미지 bytes가 아니라 URL과 비율만 저장해야 한다.
5. 참여자/스탠바이미 공개 API에서 저장 결과가 확인되어야 한다.
6. Flutter View/Controller는 서버 DTO와 generated client를 직접 알면 안 된다.
7. 서버 API 변화는 Gateway와 Mapper에서 우선 흡수해야 한다.
8. 관리자 프로젝트의 폴더와 의존성은 참여자 프로젝트의 `api/controller`, `api/model`, `api/service` 구조를 따른다.
