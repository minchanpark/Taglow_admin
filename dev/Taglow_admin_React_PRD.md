# Taglow 관리자 React 전환 PRD v1.0

## 0. 문서 개요

### 문서 목적

본 문서는 현재 Flutter Web 기반 `Taglow_admin` 운영 콘솔을 **React 기반 프론트엔드**로 재구현하기 위한 제품 요구사항을 정의한다.

React 전환의 목표는 단순 UI 재작성에 그치지 않는다. 현재 프로젝트의 핵심 구조인 `AdminApiGateway`와 `AdminPayloadMapper`를 React에서도 유지해, 서버 API와 프론트엔드 domain model 사이에 명확한 중간 계층을 둔다.

### 전환 핵심

```text
React View
  -> Controller Hook / ViewModel
  -> AdminService
  -> AdminApiGateway + AdminPayloadMapper
  -> Server DTO / Spring API
```

이 구조에서:
- `AdminApiGateway`는 서버 endpoint, HTTP method, credentials, header, CORS, raw payload 정규화를 담당한다.
- `AdminPayloadMapper`는 서버 DTO와 React domain model 간 변환을 담당한다.
- `AdminService`는 controller가 호출하는 앱 내부 use case 계약이다.
- View와 Controller는 서버 DTO, endpoint 문자열, OpenAPI generated type, storage SDK를 직접 알지 않는다.

### 문서 범위

포함 범위:
- React 기반 관리자 콘솔 제품 요구사항
- Spring 로그인, 세션 확인, 로그아웃
- 회원가입 요청. 신규 사용자는 서버 정책에 따라 `USER` role로 생성
- vote 생성, 조회, 수정, 상태 변경, 삭제
- question 생성, 조회, 수정, 삭제
- question 이미지 업로드
- 참여자 URL 생성 및 복사
- 참여자 QR 코드 생성, 미리보기, 다운로드
- 스탠바이미 player URL 생성, 복사, 새 창 열기
- 공개 API quick check
- Firebase Hosting 배포
- Flutter의 `api/controller`, `api/service`, `api/model`, `utils`, `theme`, `view` 구조를 React에 맞게 이식
- `AdminApiGateway`와 `AdminPayloadMapper`를 중간 변환 계층으로 명문화

제외 범위:
- 참여자용 모바일 태깅 화면
- 스탠바이미 player 화면 자체
- moderation UI
- analytics dashboard
- reward user management
- CSV/export/report
- AI 분석
- 조직/결제/멤버십 관리
- 클라이언트에서 `ADMIN` role 생성/승격
- 원격 player 제어

### 제품 원칙

운영자는 코드를 수정하거나 S3 콘솔을 직접 다루지 않고도, 현장 vote와 question 이미지를 만들고 즉시 참여자 링크, QR 코드, 스탠바이미 player 링크를 얻을 수 있어야 한다.

React 전환 후에도 제품의 본질은 **현장 운영 콘솔**이다. 첫 화면과 주요 화면은 마케팅 사이트가 아니라 반복 업무를 빠르게 수행하는 작업 도구여야 한다.

---

## 1. React 전환 목표

### 1-1. 유지할 제품 기능

React 버전은 현재 Flutter 관리자 콘솔의 MVP 범위를 그대로 유지한다.

1. USER 또는 ADMIN 사용자가 로그인 후 운영 콘솔에 진입한다.
2. USER 또는 ADMIN 사용자가 vote를 생성, 조회, 수정, 종료, 삭제한다.
3. USER 또는 ADMIN 사용자가 vote 안의 question을 생성, 조회, 수정, 삭제한다.
4. question 이미지는 서버 payload에 bytes를 넣지 않고 업로드 후 `imageUrl`, `imageRatio`만 저장한다.
5. 참여자 링크는 `TAGLOW_PARTICIPANT_BASE_URL/e/{voteId}`로 생성한다.
6. 참여자 QR payload는 공개 참여자 URL만 사용한다.
7. player 링크는 `TAGLOW_PLAYER_BASE_URL/display/{voteId}`로 생성한다.
8. 저장된 데이터는 공개 display/question API에서 확인 가능해야 한다.
9. 서버 DTO 변경은 View/Controller가 아니라 Gateway/Mapper 계층에서 우선 흡수한다.

### 1-2. React 전환에서 개선할 점

- Flutter의 `StateNotifier` 구조를 React의 **Controller Hook + TanStack Query + Zustand** 조합으로 이식한다.
- server state와 UI/session state를 분리한다.
- endpoint와 DTO 변환을 `AdminApiGateway`, `AdminPayloadMapper`에 더 강하게 고정한다.
- Firebase Hosting 배포와 SPA rewrite를 정식 요구사항으로 둔다.
- React 컴포넌트는 운영자 desktop/tablet workflow에 맞게 더 밀도 있는 화면을 제공한다.

### 1-3. 상태관리 선택

상태관리는 다음 조합을 권장한다.

| 상태 종류 | 권장 도구 | 이유 |
|---|---|---|
| 서버 데이터 | TanStack Query | vote/question/auth/public preview 조회, 캐시, refetch, mutation 상태에 적합 |
| 세션/전역 UI | Zustand | 로그인 사용자, toast, sidebar, selected workspace 같은 작은 전역 상태에 적합 |
| 폼 draft | React Hook Form | 로그인, 회원가입, vote, question form validation과 dirty state에 적합 |
| URL route state | React Router | route params와 navigation guard에 적합 |
| 순수 계산 | utils/model 함수 | URL 생성, imageRatio, mapper 변환 테스트에 적합 |

정책:
- Redux는 MVP 기본값으로 사용하지 않는다. 현재 도메인은 복잡한 client-only event sourcing보다 server state와 domain service 경계가 중요하다.
- Zustand store에 서버 DTO나 API 응답 원본을 넣지 않는다.
- TanStack Query query/mutation function은 `AdminService`만 호출한다.
- View 컴포넌트는 `AdminApiGateway`나 `AdminPayloadMapper`를 직접 import하지 않는다.

---

## 2. 사용자와 운영 플로우

### 2-1. 1차 사용자: 현장 운영자

현장 운영자는 React 관리자 콘솔에서 vote와 question 이미지를 만들고 링크/QR/player 준비를 끝낸다.

주요 니즈:
- 로그인 후 바로 vote 목록을 보고 새 vote를 만든다.
- question 이미지를 업로드하고 저장한다.
- 참여자 링크를 복사한다.
- QR을 미리보고 다운로드한다.
- player 링크를 새 창으로 열어 스탠바이미 화면을 확인한다.
- 운영 중 vote 상태를 `PROGRESS` 또는 `END`로 변경한다.

### 2-2. 2차 사용자: 개발/운영 관리자

개발/운영 관리자는 React 콘솔에서 배포 origin, API base URL, S3 설정, participant/player URL, public API 응답 상태를 점검한다.

주요 니즈:
- 현재 Firebase Hosting origin과 API CORS 상태를 확인한다.
- S3 업로드 실패와 API 저장 실패를 구분한다.
- public display/questions API가 player에서 읽을 데이터를 제공하는지 확인한다.
- 서버 DTO 변경 시 React 화면 수정 범위를 최소화한다.

---

## 3. 정보 구조

```text
React 관리자 웹
├── /login
├── /signup
├── /votes
│   ├── vote 목록
│   ├── 새 vote 생성
│   ├── 검색/상태 필터
│   └── vote row/card
├── /votes/:voteId
│   ├── vote 기본 정보
│   ├── 상태 변경
│   ├── 운영 링크/QR/player 패널
│   ├── 공개 API quick check
│   └── question 목록
├── /votes/:voteId/questions/new
├── /votes/:voteId/questions/:questionId
└── /diagnostics
    ├── API base URL
    ├── Firebase Hosting origin
    ├── participant base URL
    ├── player base URL
    ├── S3 설정
    ├── CORS/CSRF 안내
    └── public API/player route check
```

---

## 4. 화면별 요구사항

### A1. 로그인 화면

주요 UI:
- 아이디 입력
- 비밀번호 입력
- 로그인 버튼
- 회원가입 이동
- 오류/성공 메시지

요구사항:
- `POST /api/auth/login` 후 `GET /api/auth/me` 또는 로그인 응답으로 사용자 role을 확인한다.
- `USER` 또는 `ADMIN` role이 있으면 `/votes`로 이동한다.
- 지원하지 않는 role이면 “운영 콘솔 접근 권한이 없습니다.”를 표시한다.
- 비밀번호는 React state/store에 장기 보관하지 않는다.
- View는 `useAuthController`만 호출한다.

### A1-1. 회원가입 화면

요구사항:
- 계정명 3자 이상, 비밀번호 8자 이상, 확인 일치 여부를 검증한다.
- `POST /api/users`로 회원가입을 요청한다.
- 성공 후 로그인 화면으로 돌아간다.
- `ADMIN` 승격 API를 호출하지 않는다.

### A2. vote 목록 화면

요구사항:
- `AdminService.fetchVotes()`로 목록을 조회한다.
- 각 vote의 question count는 별도 query 또는 detail summary API로 계산한다.
- 로딩, 빈 상태, 오류, 재시도 상태를 제공한다.
- 새 vote 생성은 mutation으로 처리하고 성공 시 목록 cache를 갱신한다.
- 화면은 서버 DTO가 아니라 `AdminVote` model만 표시한다.

### A3. vote 상세 화면

요구사항:
- `AdminService.fetchVote(voteId)`와 `AdminService.fetchQuestions(voteId)`를 조합한다.
- `AdminUrlBuilder`로 participant/player 링크를 만든다.
- QR preview는 participant URL만 payload로 사용한다.
- 참여자 링크 복사, QR 다운로드, player 링크 복사, player 새 창 열기 action을 제공한다.
- public display/questions quick check를 제공한다.
- vote 상태 변경과 삭제를 지원한다.
- View는 endpoint와 DTO field name을 알지 않는다.

### A4. question 작성/수정 화면

요구사항:
- 제목, 설명, 이미지 선택, 업로드, 미리보기, imageRatio 표시를 제공한다.
- 이미지 선택 후 원본 width/height로 `imageRatio = width / height`를 계산한다.
- 업로드 성공 후 question 저장에는 `imageUrl`, `imageRatio`, `title`, `detail`, `voteId`만 전달한다.
- S3 업로드 성공 후 서버 저장 실패 시 업로드 결과를 유지하고 저장 재시도를 제공한다.
- 이미지 bytes는 `AdminService.createQuestion` payload에 들어가지 않는다.

### A5. 운영 링크/QR/player 패널

요구사항:
- participant URL 표시와 복사
- QR preview
- QR PNG 다운로드, SVG 또는 URL 복사 fallback
- player URL 표시와 복사
- player 새 창 열기
- public API quick check
- base URL 설정 누락 시 링크/QR/player action 비활성화

### A6. 진단 화면

요구사항:
- 비밀이 아닌 설정만 표시한다.
- API base URL, Firebase Hosting origin, participant/player base URL, S3 bucket/region/public base URL을 표시한다.
- CORS 실패, 인증 실패, S3 upload 실패, public API 실패를 구분한다.
- 서버 DTO나 내부 endpoint detail을 운영자 문구에 과도하게 노출하지 않는다.

---

## 5. Domain Model 요구사항

React 버전의 domain model은 TypeScript type으로 정의한다. 모든 Controller Hook, Service, View는 이 model을 기준으로 동작한다.

### 5-1. AdminUser

```ts
export type AdminUser = {
  id: string;
  name: string;
  roles: ReadonlySet<string>;
};
```

파생 규칙:
- `isAdmin(user)`는 `roles.has('ADMIN')`
- `canUseAdminConsole(user)`는 `roles.has('USER') || roles.has('ADMIN')`

### 5-2. AdminVote

```ts
export type VoteStatus = 'PROGRESS' | 'END';

export type AdminVote = {
  id: string;
  name: string;
  status: VoteStatus;
  createdByUserId: string;
  isMine: boolean;
  createdAt?: string;
  updatedAt?: string;
};
```

### 5-3. AdminQuestion

```ts
export type AdminQuestion = {
  id: string;
  voteId: string;
  title: string;
  detail: string;
  imageUrl: string;
  imageRatio: number;
  createdAt?: string;
  updatedAt?: string;
};
```

### 5-4. QuestionImageUploadResult

```ts
export type QuestionImageUploadResult = {
  objectKey: string;
  publicUrl: string;
  contentType: string;
  sizeBytes: number;
  imageWidth: number;
  imageHeight: number;
  imageRatio: number;
};
```

### 5-5. AdminVoteLinks

```ts
export type AdminVoteLinks = {
  voteId: string;
  participantUrl: string;
  participantQrPayload: string;
  playerUrl: string;
  playerPreviewUrl?: string;
};
```

정책:
- QR payload는 `participantUrl`과 동일하다.
- player URL은 `/display/{voteId}`를 사용한다.
- MVP에서는 `voteId`가 player의 `eventId`다.

---

## 6. Gateway/Mapper 제품 요구사항

### 6-1. 중간 계층의 제품적 의미

`AdminApiGateway`와 `AdminPayloadMapper`는 단순 개발 편의가 아니라 제품 안정성 요구사항이다.

서버 API가 다음처럼 바뀌어도 운영 화면은 가능하면 그대로 유지되어야 한다.
- `id`가 `voteId`로 내려옴
- `name`이 public display에서 `voteName`으로 내려옴
- `detail`이 `description`으로 바뀜
- `imageRatio`가 현재 integer schema에서 future double schema로 바뀜
- vote 생성 endpoint가 `/api/public/votes`에서 `/api/votes`로 바뀜
- cookie 인증에서 token 인증으로 바뀜

### 6-2. Gateway 요구사항

Gateway는 다음만 담당한다.
- HTTP client 구성
- base URL
- endpoint path
- request method
- credentials/cookie 정책
- CSRF/token header 정책
- raw response를 object/list payload로 정규화
- safe error mapping

Gateway는 다음을 하면 안 된다.
- React state 보유
- View text 결정
- domain model 생성
- form validation
- QR/player URL 생성

### 6-3. Mapper 요구사항

Mapper는 다음만 담당한다.
- server DTO -> domain model
- domain command -> server request payload
- enum 변환
- ID string normalization
- date string normalization
- field alias 흡수
- `imageRatio` 임시 스케일 인코딩/디코딩

Mapper는 다음을 하면 안 된다.
- HTTP 호출
- React Hook 사용
- Zustand/TanStack Query 접근
- Browser API 접근
- 화면 메시지 생성

### 6-4. Service 요구사항

Service는 Gateway와 Mapper를 조합해 Controller-facing 계약을 제공한다.

```text
Controller Hook
  -> AdminService.createQuestion(command)
  -> AdminPayloadMapper.createQuestionToPayload(command)
  -> AdminApiGateway.createQuestion(payload)
  -> AdminPayloadMapper.questionFromPayload(response)
  -> AdminQuestion
```

정책:
- `MockAdminService`와 `OpenApiAdminService`는 같은 `AdminService` 계약을 구현한다.
- Controller와 View는 구현체가 mock인지 real인지 알지 않는다.
- public preview payload는 Controller에 도달하기 전 Service/Gateway에서 안전한 shape으로 정규화한다.

---

## 7. API와 환경 요구사항

### 7-1. 현재 Spring API

기준 snapshot: `dev/tagvote-openapi.json`

| 기능 | API |
|---|---|
| 회원가입 | `POST /api/users` |
| 로그인 | `POST /api/auth/login` |
| 현재 사용자 | `GET /api/auth/me` |
| 로그아웃 | `POST /api/auth/logout` |
| vote 목록 | `GET /api/votes` |
| vote 상세 | `GET /api/votes/{voteId}` |
| vote 생성 | 임시 `POST /api/public/votes`, 목표 `POST /api/votes` |
| vote 수정 | `PATCH /api/votes/{voteId}` |
| vote 삭제 | `DELETE /api/votes/{voteId}` |
| question 목록 | `GET /api/votes/{voteId}/questions` |
| question 생성 | `POST /api/questions` |
| question 수정 | `PATCH /api/questions/{questionId}` |
| question 삭제 | `DELETE /api/questions/{questionId}` |
| public display | `GET /api/public/votes/{voteId}/display` |
| public questions | `GET /api/public/votes/{voteId}/questions` |

### 7-2. 환경변수

React/Vite 기준:

```sh
VITE_TAGLOW_API_BASE_URL=https://vote.newdawnsoi.site
VITE_TAGLOW_PARTICIPANT_BASE_URL=https://taglow-participant.web.app
VITE_TAGLOW_PLAYER_BASE_URL=https://taglow-player.web.app
VITE_TAGLOW_USE_MOCK_SERVICE=false
VITE_TAGLOW_VOTE_CREATE_PATH=/api/votes

VITE_TAGLOW_AWS_REGION=ap-northeast-2
VITE_TAGLOW_COGNITO_IDENTITY_POOL_ID=ap-northeast-2:...
VITE_TAGLOW_S3_BUCKET=tagvote-content-bucket
VITE_TAGLOW_S3_PUBLIC_BASE_URL=https://tagvote-content-bucket.s3.ap-northeast-2.amazonaws.com
VITE_TAGLOW_S3_QUESTION_IMAGE_PREFIX=public/question-images
```

정책:
- `VITE_` 값은 브라우저 번들에 노출될 수 있다.
- 장기 AWS access key, secret key, session cookie, admin password, private token은 `.env` 또는 docs 예시에 넣지 않는다.
- Cognito Identity Pool ID, bucket name, region, public base URL은 비밀 값이 아닌 운영 설정으로 취급한다.

---

## 8. Firebase Hosting 요구사항

### 8-1. Hosting 정책

- React build output은 Firebase Hosting으로 배포한다.
- 도메인은 현재 관리자 프로젝트와 동일한 운영 도메인을 사용한다.
- SPA route를 위해 모든 app route를 `/index.html`로 rewrite한다.
- Firebase Hosting origin은 Spring CORS allowlist에 추가되어야 한다.

### 8-2. `firebase.json` 요구사항

```json
{
  "hosting": {
    "public": "dist",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [{ "source": "**", "destination": "/index.html" }]
  }
}
```

### 8-3. 배포 성공 기준

- `/login`, `/votes`, `/votes/{voteId}`, `/diagnostics` deep link 새로고침이 정상 동작한다.
- Firebase origin에서 Spring login/session cookie가 동작한다.
- Firebase origin에서 S3 upload CORS가 동작한다.
- participant/player 링크는 Firebase 관리자 URL이 아니라 각 public URL을 사용한다.

---

## 9. 보안/개인정보 요구사항

- 로그인 없이 관리자 화면에 접근할 수 없다.
- route guard는 UX 보호 수단이며, 서버가 최종 권한을 검증한다.
- USER와 ADMIN 모두 운영 콘솔 접근 가능 role이다.
- ADMIN은 최고 관리자/개발자 권한 구분이며 일반 운영 접근의 유일 조건이 아니다.
- 비밀번호, session cookie, token, 장기 AWS key를 저장하거나 화면에 노출하지 않는다.
- QR payload에는 공개 participant URL만 들어간다.
- player URL에는 secret을 넣지 않는다.
- server DTO field name을 사용자 표시 문구에 그대로 노출하지 않는다.
- CORS/CSRF/cookie 정책은 Gateway에서 흡수한다.

---

## 10. QA 시나리오

### 10-1. 기본 운영 시나리오

1. USER 또는 ADMIN 사용자가 로그인한다.
2. vote 목록에 진입한다.
3. 새 vote를 생성한다.
4. vote 상세에서 question 추가를 누른다.
5. 이미지를 선택하고 업로드한다.
6. 제목과 설명을 입력한다.
7. question을 저장한다.
8. 참여자 링크를 복사한다.
9. QR을 다운로드한다.
10. player 링크를 새 창으로 연다.
11. public API quick check를 실행한다.

### 10-2. Gateway/Mapper 회귀 시나리오

1. 서버가 `AuthUserResponse.userId`를 반환해도 `AdminUser.id`가 string으로 매핑된다.
2. 서버가 `VoteDisplayResponse.voteName`을 반환해도 `AdminVote.name` 또는 preview display name으로 매핑된다.
3. 서버가 `QuestionWithTagsResponse.question` 중첩 구조를 반환해도 `AdminQuestion`으로 매핑된다.
4. 서버가 `imageRatio`를 integer scaled value로 반환해도 domain model은 실제 double 값을 갖는다.
5. protected vote create endpoint로 바뀌어도 View/Controller는 수정되지 않는다.

### 10-3. 실패 시나리오

- 로그인 실패 시 안전한 메시지를 표시한다.
- role이 없으면 운영 콘솔 접근을 막는다.
- S3 업로드 실패 시 question 저장을 실행하지 않는다.
- S3 업로드 성공 후 API 저장 실패 시 저장 재시도를 제공한다.
- CORS 실패와 인증 실패를 구분한다.
- QR 다운로드 실패 시 URL 복사 fallback을 제공한다.
- player 새 창 열기 실패 시 player URL 복사 fallback을 제공한다.

---

## 11. MVP 완료 기준

1. React 앱이 Firebase Hosting에서 동작한다.
2. USER/ADMIN 로그인과 route guard가 동작한다.
3. vote/question CRUD가 domain model 기준으로 동작한다.
4. `AdminApiGateway`와 `AdminPayloadMapper`가 서버 DTO와 React model 사이 중간 계층을 이룬다.
5. View/Controller는 endpoint와 server DTO를 직접 import하지 않는다.
6. question 이미지는 업로드 후 `imageUrl`, `imageRatio`만 저장한다.
7. participant URL, QR payload, player URL 정책이 Flutter와 동일하다.
8. public display/questions API로 저장 결과를 확인할 수 있다.
9. mock service와 real service가 같은 contract로 교체 가능하다.
10. mapper/gateway/controller/widget/e2e 테스트가 핵심 흐름을 보호한다.

---

## 12. 오픈 이슈

| 항목 | 내용 |
|---|---|
| protected vote create | 현재 snapshot에는 `POST /api/public/votes`만 있으므로 `POST /api/votes` 확정 필요 |
| imageRatio schema | 현재 OpenAPI는 integer int64. React domain은 number double 기준 |
| CORS | Firebase Hosting origin과 `https://taglow-player.web.app` allowlist 필요 |
| CSRF | Spring session/cookie 인증 시 state-changing request 정책 확정 필요 |
| S3 upload 방식 | Cognito 직접 업로드와 presigned URL 중 운영 방식 확정 필요 |
| QR export | PNG 기본, SVG fallback 구현 방식 확정 필요 |
| player route | `https://taglow-player.web.app/display/{voteId}` route 구현 확인 필요 |

---

## 13. 기술 참고

- React state 구조는 React 공식 문서의 state management 원칙을 따른다: https://react.dev/learn/managing-state
- server state는 TanStack Query React 문서를 기준으로 설계한다: https://tanstack.com/query/latest/docs/framework/react/overview
- Firebase Hosting SPA rewrite는 Firebase Hosting 공식 문서를 기준으로 적용한다: https://firebase.google.com/docs/hosting/full-config
