# Taglow 관리자 React 전환 TDD v1.0

## 0. 문서 개요

### 문서 목적

본 문서는 Flutter Web 기반 `Taglow_admin`을 React로 전환하기 위한 기술 설계 문서다.

React 구현은 현재 Flutter 프로젝트의 계층 구조를 유지하되, React 생태계에 맞게 다음 형태로 이식한다.

```text
view/
  React components
    ↓
api/controller/
  Controller hooks / view models
    ↓
api/service/
  AdminService contract
  MockAdminService
  OpenApiAdminService
    ↓
api/service/gateway + mapper
  AdminApiGateway
  AdminPayloadMapper
    ↓
api/generated or HTTP client
  OpenAPI types / fetch client
    ↓
Spring API

api/model/
  stable React domain model
```

### 핵심 설계 결정

현재 Flutter 프로젝트의 핵심 파일인 `lib/api/service/admin_api_gateway.dart`와 `lib/api/service/admin_payload_mapper.dart`에 해당하는 React 계층을 반드시 둔다.

React 전환 후에도 서버 API와 앱 model은 직접 연결하지 않는다. `api`와 `model` 사이에는 다음 중간 계층이 존재한다.

```text
Server DTO / raw JSON
  <-> AdminApiGateway
  <-> AdminPayloadMapper
  <-> React domain model
```

이 계층은 서버 API 변화가 React View와 Controller로 새지 않게 막는 핵심 방어선이다.

---

## 1. 기술 스택

| 영역 | 기술 |
|---|---|
| Frontend | React |
| Language | TypeScript |
| Build | Vite |
| Routing | React Router |
| Server State | TanStack Query |
| Client/UI State | Zustand |
| Form | React Hook Form |
| HTTP | fetch wrapper 또는 openapi-fetch |
| API types | openapi-typescript |
| Validation | Zod 또는 lightweight validator |
| QR Rendering | qrcode.react 또는 동등 라이브러리 |
| QR Export | canvas PNG, SVG fallback |
| Image Upload | AWS S3 Cognito direct upload 또는 presigned URL PUT |
| Test | Vitest, React Testing Library, MSW, Playwright |
| Hosting | Firebase Hosting |

### 상태관리 결정

React 버전은 다음처럼 상태를 분리한다.

```text
TanStack Query
  auth session probe, votes, vote detail, questions, public preview

Zustand
  current user cache, UI shell state, toast, transient operation status

React Hook Form
  login form, signup form, vote form, question editor draft

Controller Hooks
  View event orchestration, service calls, mutation composition, fallback handling
```

정책:
- TanStack Query query/mutation function은 `AdminService`만 호출한다.
- Zustand store에는 raw server DTO를 저장하지 않는다.
- Controller Hook은 Gateway나 Mapper를 직접 import하지 않는다.
- View는 Controller Hook과 domain model만 사용한다.

---

## 2. React 프로젝트 구조

권장 구조:

```text
src/
├── main.tsx
├── app/
│   ├── App.tsx
│   ├── router.tsx
│   ├── queryClient.ts
│   └── providers.tsx
│
├── view/
│   ├── auth/
│   │   ├── LoginPage.tsx
│   │   └── SignupPage.tsx
│   ├── votes/
│   │   ├── VoteListPage.tsx
│   │   ├── VoteCreatePage.tsx
│   │   ├── VoteDetailPage.tsx
│   │   └── widgets/
│   │       ├── OperationLinkPanel.tsx
│   │       ├── ParticipantShareSheet.tsx
│   │       ├── VoteStatusControl.tsx
│   │       ├── PublicPreviewPanel.tsx
│   │       └── QuestionGrid.tsx
│   ├── questions/
│   │   ├── QuestionEditorPage.tsx
│   │   └── widgets/
│   │       ├── QuestionForm.tsx
│   │       ├── QuestionImagePicker.tsx
│   │       └── QuestionPreviewPanel.tsx
│   ├── diagnostics/
│   │   └── AdminDiagnosticsPage.tsx
│   └── common/
│       ├── AdminShell.tsx
│       ├── AdminButton.tsx
│       ├── AdminTextField.tsx
│       └── AdminMessage.tsx
│
├── api/
│   ├── controller/
│   │   ├── useAuthController.ts
│   │   ├── useVoteListController.ts
│   │   ├── useVoteDetailController.ts
│   │   └── useQuestionEditorController.ts
│   ├── model/
│   │   ├── adminUser.ts
│   │   ├── adminAuthSession.ts
│   │   ├── adminVote.ts
│   │   ├── adminQuestion.ts
│   │   ├── adminVoteLinks.ts
│   │   ├── questionImageSelection.ts
│   │   ├── questionImageUploadResult.ts
│   │   └── qrExportResult.ts
│   ├── service/
│   │   ├── adminService.ts
│   │   ├── adminServiceProvider.ts
│   │   ├── mockAdminService.ts
│   │   ├── openApiAdminService.ts
│   │   ├── gateway/
│   │   │   ├── adminApiGateway.ts
│   │   │   ├── fetchAdminApiGateway.ts
│   │   │   └── adminApiErrors.ts
│   │   ├── mapper/
│   │   │   └── adminPayloadMapper.ts
│   │   ├── upload/
│   │   │   ├── questionImagePickerService.ts
│   │   │   ├── questionImageUploadService.ts
│   │   │   ├── s3QuestionImageUploadService.ts
│   │   │   └── presignedQuestionImageUploadService.ts
│   │   ├── qrExportService.ts
│   │   ├── externalLinkLauncher.ts
│   │   └── participantShareService.ts
│   └── generated/
│       ├── tagvoteSchema.ts
│       └── tagvoteClient.ts
│
├── utils/
│   ├── adminUrlBuilder.ts
│   ├── envConfig.ts
│   ├── inputValidator.ts
│   ├── imageRatioReader.ts
│   ├── clipboardHelper.ts
│   └── browserDownloadHelper.ts
│
├── theme/
│   ├── tokens.ts
│   ├── colors.ts
│   ├── typography.ts
│   └── adminTheme.css
│
└── test/
    ├── mocks/
    └── setup.ts
```

### 의존성 방향

```text
view -> controller -> service -> gateway/mapper -> generated/http
                    -> model
utils -> model when needed
theme -> no api dependency
```

금지:
- `view/**`에서 `api/generated`, `AdminApiGateway`, `AdminPayloadMapper`, endpoint string import 금지
- `api/controller/**`에서 generated type, raw DTO, fetch client, S3 SDK import 금지
- `api/model/**`에서 service, controller, view import 금지
- `api/service/mapper/**`에서 HTTP, React, Zustand, TanStack Query import 금지
- `api/service/gateway/**`에서 React component, Controller state import 금지

---

## 3. Domain Model 설계

### 3-1. AdminUser

```ts
export type AdminUser = Readonly<{
  id: string;
  name: string;
  roles: ReadonlySet<string>;
}>;

export const isAdmin = (user: AdminUser) => user.roles.has('ADMIN');

export const canUseAdminConsole = (user: AdminUser) => {
  return user.roles.has('USER') || user.roles.has('ADMIN');
};
```

### 3-2. AuthSession

```ts
export type AdminAuthSession = Readonly<{
  user: AdminUser | null;
  isCheckingSession: boolean;
  errorMessage?: string;
}>;
```

### 3-3. Vote

```ts
export type VoteStatus = 'PROGRESS' | 'END';

export type AdminVote = Readonly<{
  id: string;
  name: string;
  status: VoteStatus;
  createdByUserId: string;
  isMine: boolean;
  createdAt?: string;
  updatedAt?: string;
}>;
```

### 3-4. Question

```ts
export type AdminQuestion = Readonly<{
  id: string;
  voteId: string;
  title: string;
  detail: string;
  imageUrl: string;
  imageRatio: number;
  createdAt?: string;
  updatedAt?: string;
}>;
```

### 3-5. Upload / Link / QR

```ts
export type QuestionImageSelection = Readonly<{
  bytes: Uint8Array;
  fileName: string;
  contentType: string;
  imageWidth: number;
  imageHeight: number;
}>;

export type QuestionImageUploadResult = Readonly<{
  objectKey: string;
  publicUrl: string;
  contentType: string;
  sizeBytes: number;
  imageWidth: number;
  imageHeight: number;
  imageRatio: number;
}>;

export type AdminVoteLinks = Readonly<{
  voteId: string;
  participantUrl: string;
  participantQrPayload: string;
  playerUrl: string;
  playerPreviewUrl?: string;
}>;

export type QrExportFormat = 'png' | 'svg';

export type QrExportResult = Readonly<{
  fileName: string;
  format: QrExportFormat;
  byteLength: number;
}>;
```

---

## 4. Gateway/Mapper 중간 계층 설계

### 4-1. 설계 목표

현재 Flutter의 핵심은 `admin_api_gateway.dart`와 `admin_payload_mapper.dart`가 서버와 앱 model 사이의 변환 벽을 만든다는 점이다. React도 같은 구조를 유지한다.

```text
Server DTO
  raw JSON / generated schema
      ↓
AdminApiGateway
  endpoint, credentials, header, response normalization
      ↓
AdminPayloadMapper
  DTO shape -> React domain model
  domain command -> request payload
      ↓
AdminService
  use case contract
      ↓
Controller Hook
      ↓
View
```

### 4-2. AdminApiGateway 책임

`AdminApiGateway`는 low-level server adapter다.

책임:
- API base URL 적용
- endpoint path와 method 관리
- query/path segment encoding
- `credentials: 'include'` 또는 token header 정책 적용
- CSRF header 정책 적용
- body가 있는 요청에만 JSON `Content-Type` 추가
- body 없는 GET에 불필요한 custom header를 붙이지 않음
- response body를 payload object/list로 정규화
- 401/403/session probe를 앱이 해석 가능한 값으로 정규화
- safe error message를 가진 `AdminApiError` 생성
- debug log redaction

금지:
- domain model 생성
- React Hook 사용
- Zustand/TanStack Query 접근
- QR/player URL 생성
- 화면 copy 작성

### 4-3. AdminPayloadMapper 책임

`AdminPayloadMapper`는 server DTO와 domain model의 번역기다.

책임:
- `AuthUserResponse` 또는 `UserResponse` -> `AdminUser`
- `VoteResponse` 또는 public display payload -> `AdminVote`
- `QuestionResponse` 또는 `QuestionWithTagsResponse` -> `AdminQuestion`
- command object -> server request payload
- `id`, `userId`, `voteId`, `questionId` alias 흡수
- `name`, `voteName` alias 흡수
- `detail`, `description` alias 흡수
- server enum 문자열 -> domain enum
- `imageRatio` integer/double 호환 처리
- null 제거와 partial update payload 생성

금지:
- HTTP 호출
- browser API 호출
- React state 변경
- service provider 접근
- route 이동

### 4-4. 중간 계층 파일 배치

```text
src/api/service/
├── openApiAdminService.ts
├── gateway/
│   ├── adminApiGateway.ts
│   ├── fetchAdminApiGateway.ts
│   └── adminApiErrors.ts
└── mapper/
    └── adminPayloadMapper.ts
```

이 구조는 `api/service` 아래에서 server-facing code를 보관하되, `gateway`와 `mapper`를 하위 디렉터리로 분리해 역할을 더 명확히 한다.

### 4-5. Gateway interface

```ts
export interface AdminApiGateway {
  signup(payload: Record<string, unknown>): Promise<Record<string, unknown>>;
  login(payload: Record<string, unknown>): Promise<Record<string, unknown>>;
  me(): Promise<Record<string, unknown> | null>;
  logout(): Promise<void>;

  fetchVotes(): Promise<Array<Record<string, unknown>>>;
  createVote(payload: Record<string, unknown>): Promise<Record<string, unknown>>;
  fetchVote(voteId: string): Promise<Record<string, unknown>>;
  updateVote(args: {
    voteId: string;
    payload: Record<string, unknown>;
  }): Promise<Record<string, unknown>>;
  deleteVote(voteId: string): Promise<void>;

  fetchQuestions(voteId: string): Promise<Array<Record<string, unknown>>>;
  createQuestion(payload: Record<string, unknown>): Promise<Record<string, unknown>>;
  updateQuestion(args: {
    questionId: string;
    payload: Record<string, unknown>;
  }): Promise<Record<string, unknown>>;
  deleteQuestion(questionId: string): Promise<void>;

  fetchPublicVoteDisplay(voteId: string): Promise<Record<string, unknown>>;
  fetchPublicQuestions(voteId: string): Promise<Array<Record<string, unknown>>>;
}
```

### 4-6. Fetch Gateway 구현 정책

```ts
type FetchAdminApiGatewayOptions = {
  baseUrl: string;
  voteCreatePath: string;
  credentials?: RequestCredentials;
  fetchImpl?: typeof fetch;
  csrfTokenProvider?: () => string | null;
};
```

정책:
- 기본 `credentials`는 `include`다.
- 임시 `/api/public/votes` 생성 경로를 쓸 때는 해당 요청만 credentials를 `omit` 또는 `same-origin`으로 override할 수 있다.
- protected `/api/votes` 생성 endpoint가 확정되면 config만 바꾼다.
- login response와 password payload는 debug log에서 redaction한다.
- 401/403 session probe는 `null` session으로 정규화한다.

### 4-7. Mapper 구현 예시

```ts
const TEMPORARY_IMAGE_RATIO_SCALE = 10000;

export const adminPayloadMapper = {
  loginToPayload(input: { name: string; password: string }) {
    return { name: input.name, password: input.password };
  },

  signupToPayload(input: { name: string; password: string }) {
    return { name: input.name, password: input.password };
  },

  userFromPayload(payload: Record<string, unknown>): AdminUser {
    return {
      id: toStringValue(payload.id ?? payload.userId),
      name: toStringValue(payload.name),
      roles: toRoleSet(payload.roles),
    };
  },

  createQuestionToPayload(input: {
    voteId: string;
    title: string;
    detail: string;
    imageUrl: string;
    imageRatio: number;
  }) {
    return {
      voteId: intOrString(input.voteId),
      title: input.title,
      detail: input.detail,
      imageUrl: input.imageUrl,
      imageRatio: encodeImageRatio(input.imageRatio),
    };
  },

  questionFromPayload(payload: Record<string, unknown>): AdminQuestion {
    const rawQuestion = isRecord(payload.question) ? payload.question : payload;
    return {
      id: toStringValue(rawQuestion.id ?? rawQuestion.questionId),
      voteId: toStringValue(rawQuestion.voteId),
      title: toStringValue(rawQuestion.title),
      detail: toStringValue(rawQuestion.detail ?? rawQuestion.description),
      imageUrl: toStringValue(rawQuestion.imageUrl),
      imageRatio: decodeImageRatio(rawQuestion.imageRatio, 1),
      createdAt: optionalString(rawQuestion.createdAt),
      updatedAt: optionalString(rawQuestion.updatedAt),
    };
  },
};
```

### 4-8. imageRatio 임시 호환 정책

현재 OpenAPI snapshot은 `imageRatio`를 `integer int64`로 정의한다. React domain model은 실제 비율인 `number`를 사용한다.

정책:
- domain model은 항상 `number` double 값이다.
- 서버가 integer만 받는 동안 mapper는 `imageRatio * 10000`을 반올림해 보낼 수 있다.
- 서버가 double로 바뀌면 mapper의 encode 정책만 바꾼다.
- View/Controller/Service contract는 바꾸지 않는다.

```ts
function encodeImageRatio(value: number): number {
  return Math.round(value * TEMPORARY_IMAGE_RATIO_SCALE);
}

function decodeImageRatio(value: unknown, fallback: number): number {
  const parsed = typeof value === 'number' ? value : Number(value);
  if (!Number.isFinite(parsed)) return fallback;
  return Math.abs(parsed) > 20 ? parsed / TEMPORARY_IMAGE_RATIO_SCALE : parsed;
}
```

---

## 5. AdminService 설계

### 5-1. Contract

```ts
export interface AdminService {
  signup(input: { name: string; password: string }): Promise<AdminUser>;
  login(input: { name: string; password: string }): Promise<AdminUser>;
  fetchCurrentUser(): Promise<AdminUser | null>;
  logout(): Promise<void>;

  fetchVotes(): Promise<AdminVote[]>;
  createVote(input: { name: string }): Promise<AdminVote>;
  fetchVote(voteId: string): Promise<AdminVote>;
  updateVote(input: {
    voteId: string;
    name?: string;
    status?: VoteStatus;
  }): Promise<AdminVote>;
  deleteVote(voteId: string): Promise<void>;

  fetchQuestions(voteId: string): Promise<AdminQuestion[]>;
  createQuestion(input: {
    voteId: string;
    title: string;
    detail: string;
    imageUrl: string;
    imageRatio: number;
  }): Promise<AdminQuestion>;
  updateQuestion(input: {
    questionId: string;
    title?: string;
    detail?: string;
    imageUrl?: string;
    imageRatio?: number;
  }): Promise<AdminQuestion>;
  deleteQuestion(questionId: string): Promise<void>;

  fetchPublicVoteDisplay(voteId: string): Promise<Record<string, unknown>>;
  fetchPublicQuestions(voteId: string): Promise<Array<Record<string, unknown>>>;
}
```

### 5-2. OpenApiAdminService

`OpenApiAdminService`는 Gateway와 Mapper를 조합한다.

```ts
export class OpenApiAdminService implements AdminService {
  constructor(
    private readonly gateway: AdminApiGateway,
    private readonly mapper: AdminPayloadMapper,
  ) {}
}
```

정책:
- `currentUser`는 vote 생성 시 `createdByUserId`를 보강하기 위해 service 내부에만 둘 수 있다.
- Service는 raw payload를 Controller에 전달하지 않는다.
- public preview payload는 운영 진단용으로 `Record<string, unknown>` 형태까지 허용하되 generated DTO를 노출하지 않는다.

### 5-3. MockAdminService

정책:
- in-memory vote/question store를 사용한다.
- USER/ADMIN role 허용 정책을 real service와 동일하게 테스트할 수 있어야 한다.
- mock question upload URL과 imageRatio를 deterministic하게 반환한다.
- mock과 real service는 Controller Hook에서 교체 가능해야 한다.

### 5-4. AdminServiceProvider

React에서는 provider factory를 명시적으로 둔다.

```ts
export function createAdminService(env: EnvConfig): AdminService {
  if (env.useMockService) return new MockAdminService();

  return new OpenApiAdminService(
    new FetchAdminApiGateway({
      baseUrl: env.apiBaseUrl,
      voteCreatePath: env.voteCreatePath,
    }),
    new AdminPayloadMapper(),
  );
}
```

React Context로 service 인스턴스를 제공하고, Controller Hook은 `useAdminService()`로 계약만 읽는다.

---

## 6. Controller Hook 설계

### 6-1. useAuthController

책임:
- session check query
- login mutation
- signup mutation
- logout mutation
- USER/ADMIN role validation
- route guard에 필요한 auth state 제공

반환 예시:

```ts
type AuthController = {
  user: AdminUser | null;
  canManage: boolean;
  isCheckingSession: boolean;
  isSubmitting: boolean;
  errorMessage?: string;
  successMessage?: string;
  login(input: { name: string; password: string }): Promise<boolean>;
  signup(input: {
    name: string;
    password: string;
    passwordConfirm: string;
  }): Promise<boolean>;
  logout(): Promise<void>;
  clearMessages(): void;
};
```

### 6-2. useVoteListController

책임:
- vote list query
- question count query composition
- create vote mutation
- loading/empty/error/retry state
- query invalidation

### 6-3. useVoteDetailController

책임:
- vote detail query
- questions query
- update vote name/status mutation
- delete vote mutation
- participant/player link creation
- copy participant/player URL
- QR download
- player new-tab open
- public preview query/mutation

반환 상태:

```ts
type VoteDetailController = {
  vote?: AdminVote;
  questions: AdminQuestion[];
  links?: AdminVoteLinks;
  publicPreview?: {
    display?: Record<string, unknown>;
    questions?: Array<Record<string, unknown>>;
  };
  isLoading: boolean;
  isSaving: boolean;
  isExportingQr: boolean;
  errorMessage?: string;
  refresh(): Promise<void>;
  updateVoteName(name: string): Promise<void>;
  updateVoteStatus(status: VoteStatus): Promise<void>;
  deleteVote(): Promise<void>;
  copyParticipantUrl(): Promise<string>;
  copyPlayerUrl(): Promise<string>;
  downloadParticipantQr(): Promise<string>;
  openPlayerInNewTab(): Promise<string>;
  refreshPublicPreview(): Promise<void>;
};
```

### 6-4. useQuestionEditorController

책임:
- question form draft orchestration
- image file selection
- image dimensions decode
- upload service call
- API save call
- upload failure and API failure separation

정책:
- 이미지 bytes는 upload service에 전달된 뒤 Controller state에 장기 보관하지 않는다.
- 저장 payload에는 `publicUrl`, `imageRatio`만 넣는다.

---

## 7. Routing 설계

```text
/login
/signup
/votes
/votes/new
/votes/:voteId
/votes/:voteId/questions/new
/votes/:voteId/questions/:questionId
/diagnostics
```

Route guard:
- session check 중에는 shell loading state를 표시한다.
- 비로그인 사용자는 `/login`으로 이동한다.
- 로그인했지만 USER/ADMIN role이 없으면 접근 차단 메시지를 표시한다.
- 이미 인증된 USER/ADMIN이 `/login` 또는 `/signup`에 접근하면 `/votes`로 이동한다.
- 회원가입 성공 후 자동 로그인하지 않는다.

---

## 8. URL/QR/Player 설계

### 8-1. AdminUrlBuilder

```ts
export class AdminUrlBuilder {
  constructor(
    private readonly participantBaseUrl: string,
    private readonly playerBaseUrl: string,
  ) {}

  buildParticipantUrl(voteId: string): string {
    return `${trimRightSlash(this.participantBaseUrl)}/e/${encodeURIComponent(voteId)}`;
  }

  buildPlayerUrl(voteId: string): string {
    return `${trimRightSlash(this.playerBaseUrl)}/display/${encodeURIComponent(voteId)}`;
  }

  buildPlayerItemUrl(input: { voteId: string; questionId: string }): string {
    return `${this.buildPlayerUrl(input.voteId)}/items/${encodeURIComponent(input.questionId)}`;
  }

  buildVoteLinks(voteId: string): AdminVoteLinks {
    const participantUrl = this.buildParticipantUrl(voteId);
    return {
      voteId,
      participantUrl,
      participantQrPayload: participantUrl,
      playerUrl: this.buildPlayerUrl(voteId),
    };
  }
}
```

### 8-2. QR Export

```ts
export interface QrExportService {
  downloadParticipantQr(input: {
    voteId: string;
    payload: string;
    size?: number;
  }): Promise<QrExportResult>;
}
```

정책:
- 기본 format은 PNG
- 기본 size는 1024px
- filename은 `taglow-{voteId}-participant-qr.png`
- PNG 실패 시 SVG 또는 URL 복사 fallback
- QR payload에는 participant URL만 포함

### 8-3. ExternalLinkLauncher

```ts
export interface ExternalLinkLauncher {
  openNewTab(url: string): Promise<void>;
}
```

정책:
- `window.open(url, '_blank', 'noopener,noreferrer')` 사용
- 실패 시 player URL 복사 fallback
- View가 `window.open`을 직접 호출하지 않는다.

---

## 9. Image Upload 설계

### 9-1. QuestionImagePickerService

```ts
export interface QuestionImagePickerService {
  pickQuestionImage(file: File): Promise<QuestionImageSelection>;
}
```

정책:
- 허용 content type: `image/jpeg`, `image/png`, `image/webp`
- 최대 용량: 10MB 기본
- `createImageBitmap` 또는 `HTMLImageElement`로 width/height 계산
- 선택 취소는 오류가 아니라 no-op

### 9-2. QuestionImageUploadService

```ts
export interface QuestionImageUploadService {
  uploadQuestionImage(input: QuestionImageSelection): Promise<QuestionImageUploadResult>;
}
```

구현 후보:
- `S3QuestionImageUploadService`: Cognito 임시 자격 증명 + SigV4 PUT
- `PresignedQuestionImageUploadService`: Spring 발급 presigned URL PUT
- `MockQuestionImageUploadService`: 테스트/로컬 demo

정책:
- 장기 AWS key를 frontend에 넣지 않는다.
- 업로드 결과 public URL이 참여자/player에서 접근 가능해야 한다.
- S3 실패와 API 저장 실패를 Controller에서 분리해 표시한다.

---

## 10. API 계약과 Gateway 세부

### 10-1. Current endpoint map

```ts
const paths = {
  signup: '/api/users',
  login: '/api/auth/login',
  me: '/api/auth/me',
  logout: '/api/auth/logout',
  votes: '/api/votes',
  vote: (voteId: string) => `/api/votes/${encodeURIComponent(voteId)}`,
  voteQuestions: (voteId: string) =>
    `/api/votes/${encodeURIComponent(voteId)}/questions`,
  questions: '/api/questions',
  question: (questionId: string) =>
    `/api/questions/${encodeURIComponent(questionId)}`,
  publicDisplay: (voteId: string) =>
    `/api/public/votes/${encodeURIComponent(voteId)}/display`,
  publicQuestions: (voteId: string) =>
    `/api/public/votes/${encodeURIComponent(voteId)}/questions`,
};
```

### 10-2. Auth/CORS policy

기본:
- Spring session/cookie 인증
- browser request credentials: `include`
- Firebase Hosting origin을 Spring CORS allowlist에 추가
- `Access-Control-Allow-Credentials: true`
- cookie cross-origin이면 `SameSite=None; Secure` 확인

주의:
- `POST /api/public/votes` 임시 경로는 credentialed CORS가 아닐 수 있으므로 해당 요청만 credentials override 가능
- protected `POST /api/votes` 확정 후 override 제거

### 10-3. Error mapping

| 상태 | 사용자 메시지 |
|---|---|
| 401 | 로그인이 만료되었습니다. 다시 로그인해주세요. |
| 403 | 운영 콘솔 접근 권한이 없습니다. |
| 404 | 해당 vote 또는 question을 찾을 수 없습니다. |
| 413 | 이미지 용량이 너무 큽니다. |
| 415 | 지원하지 않는 이미지 형식입니다. |
| network/CORS | 관리자 배포 origin 또는 서버 CORS 설정을 확인해주세요. |
| S3 CORS | S3 bucket CORS 설정을 확인해주세요. |
| QR export | QR 저장에 실패했습니다. 참여자 링크를 복사해 사용해주세요. |
| popup blocked | 새 창 열기에 실패했습니다. player 링크를 복사해 브라우저에서 열어주세요. |
| 500 | 서버 오류입니다. 잠시 후 다시 시도해주세요. |

---

## 11. OpenAPI 타입 생성

### 11-1. 동기화 순서

1. Spring `/v3/api-docs`를 `dev/tagvote-openapi.json`에 저장한다.
2. `openapi-typescript`로 TypeScript schema type을 생성한다.
3. generated type은 `src/api/generated`에 둔다.
4. generated file은 직접 수정하지 않는다.
5. generated type은 Gateway/Mapper 내부에서만 사용한다.

### 11-2. package script 예시

```json
{
  "scripts": {
    "sync:openapi": "curl -fsSL https://vote.newdawnsoi.site/v3/api-docs -o dev/tagvote-openapi.json",
    "gen:api": "openapi-typescript dev/tagvote-openapi.json -o src/api/generated/tagvoteSchema.ts"
  }
}
```

정책:
- View/Controller는 `src/api/generated`를 import하지 않는다.
- generated type 이름이 UI copy에 노출되지 않는다.
- OpenAPI가 틀린 경우 runtime mapper test로 실제 payload 차이를 흡수한다.

---

## 12. Firebase Hosting 설계

### 12-1. Build output

```text
npm run build
dist/
```

### 12-2. firebase.json

```json
{
  "hosting": {
    "public": "dist",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [{ "source": "**", "destination": "/index.html" }],
    "headers": [
      {
        "source": "**/*.@(js|css)",
        "headers": [{ "key": "Cache-Control", "value": "max-age=31536000, immutable" }]
      },
      {
        "source": "/index.html",
        "headers": [{ "key": "Cache-Control", "value": "no-cache" }]
      }
    ]
  }
}
```

### 12-3. CORS 필수 확인

Firebase Hosting origin을 다음 CORS 대상에 추가한다.
- Spring API CORS allowlist
- S3 bucket CORS
- Cognito Identity CORS가 필요하면 해당 정책

---

## 13. UI 설계 원칙

- 관리자 도구는 landing page가 아니라 작업 화면이다.
- desktop/tablet 우선으로 dense table/list layout을 사용한다.
- 로그인 후 첫 화면은 vote 목록이다.
- `OperationLinkPanel`은 vote 상세의 상단 또는 오른쪽 sticky area에 배치한다.
- QR은 충분한 대비와 크기를 가진다.
- 버튼은 icon + text 또는 명확한 icon button을 사용한다.
- 긴 문장보다 label, helper text, validation message를 사용한다.
- View는 persistence/network/upload/browser logic을 직접 수행하지 않는다.

---

## 14. 테스트 전략

### 14-1. Unit test

대상:
- `AdminPayloadMapper`
- `FetchAdminApiGateway`
- `AdminUrlBuilder`
- `EnvConfig`
- `InputValidator`
- `ImageRatioReader`
- `QrExportService`
- `QuestionImageUploadService`

필수 mapper test:
- `id`/`userId` alias
- `id`/`voteId` alias
- `name`/`voteName` alias
- `detail`/`description` alias
- nested `{ question, tags }` payload
- `imageRatio` scaled integer decode
- future double `imageRatio` decode
- create/update payload null 제거

필수 gateway test:
- endpoint path
- path segment encoding
- body 없는 GET에 `Content-Type` 미추가
- body 있는 POST/PATCH에 JSON `Content-Type` 추가
- credentials 기본값
- `/api/public/votes` 임시 credentials override
- session probe 401/403 -> null
- login 401/403 -> safe message

### 14-2. Controller Hook test

대상:
- `useAuthController`
- `useVoteListController`
- `useVoteDetailController`
- `useQuestionEditorController`

검증:
- USER/ADMIN role 허용
- unsupported role 차단
- vote 목록 query와 question count
- vote 생성 mutation 후 cache update
- question upload 후 save
- S3 성공/API 실패 분리
- participant/player URL copy
- QR export fallback
- player open fallback
- public preview refresh

### 14-3. Component test

도구:
- React Testing Library
- MSW 또는 fake service provider

검증:
- login form validation
- signup validation
- vote list loading/empty/error/success
- vote detail link panel
- QR preview
- player button
- question editor upload preview
- diagnostics state

### 14-4. E2E test

도구:
- Playwright

검증:
- Firebase hosted app deep link refresh
- login -> vote list
- create vote
- add question
- copy participant URL
- QR preview visible
- player URL generated
- diagnostics page config visible

운영 E2E:
- 실제 Spring API login
- S3 upload
- public display/questions check
- QR scan
- player route open

---

## 15. 개발 단계

### Phase 1. React scaffold

- Vite React TypeScript 프로젝트 생성
- Firebase Hosting 설정
- route skeleton 작성
- theme tokens 이식
- app providers 작성

### Phase 2. Model/Gateway/Mapper foundation

- `api/model` TypeScript type 작성
- `AdminApiGateway` interface 작성
- `FetchAdminApiGateway` 작성
- `AdminPayloadMapper` 작성
- mapper/gateway unit test 작성
- `AdminService` contract 작성

### Phase 3. Mock service and controller hooks

- `MockAdminService` 작성
- service provider/context 작성
- auth/vote/question Controller Hook 작성
- TanStack Query key 정책 작성
- Zustand UI/session store 작성

### Phase 4. Views

- Login/Signup
- VoteList
- VoteCreate
- VoteDetail
- OperationLinkPanel
- ParticipantShareSheet
- QuestionEditor
- Diagnostics

### Phase 5. Real API

- OpenAPI snapshot 동기화
- generated type 생성
- `OpenApiAdminService` 연결
- cookie/CORS/CSRF 확인
- protected vote create endpoint config 확인

### Phase 6. Upload/QR/Player

- image picker/dimension reader
- S3 Cognito direct upload 또는 presigned upload
- QR preview/export
- clipboard/share/download helpers
- player new-tab launcher

### Phase 7. Verification and deploy

- unit/controller/component/e2e test
- Firebase build/deploy
- Spring CORS allowlist
- S3 CORS
- public API quick check
- player route check

---

## 16. 리스크와 대응

| 리스크 | 영향 | 대응 |
|---|---|---|
| Gateway/Mapper 누락 | 서버 DTO 변경이 View 전체로 번짐 | 중간 계층을 필수 구조로 두고 import rule/test로 보호 |
| generated type 직접 import | View가 서버 schema에 결합 | lint/import boundary 설정 |
| vote create endpoint public | 권한 우회 위험 | protected `/api/votes` 요구, 임시 경로는 config로 격리 |
| imageRatio integer | 이미지 왜곡/저장 실패 | mapper 임시 scale, backend double migration |
| cookie CORS 실패 | 로그인 유지 실패 | Firebase origin allowlist, credentials 정책 확인 |
| CSRF 미정 | POST/PATCH/DELETE 실패 | Gateway CSRF token provider 설계 |
| S3 direct upload 권한 과다 | 업로드 남용 위험 | prefix 제한, presigned URL 대안 |
| QR export 실패 | 현장 사용 불편 | SVG/URL fallback |
| popup 차단 | player 확인 실패 | URL copy fallback |

---

## 17. 완료 기준

1. React 프로젝트가 Firebase Hosting에서 배포된다.
2. `src/api/model`은 안정적인 domain model만 정의한다.
3. `src/api/service/gateway`와 `src/api/service/mapper`가 서버 DTO와 domain model 사이 중간 계층을 구성한다.
4. View/Controller는 endpoint, generated DTO, raw payload를 직접 알지 않는다.
5. `AdminService` 구현체는 mock과 real을 같은 contract로 교체할 수 있다.
6. auth, vote, question, upload, link, QR, player, diagnostics flow가 동작한다.
7. mapper/gateway test가 서버 DTO 변화의 주요 alias와 타입 차이를 보호한다.
8. Firebase origin에서 Spring API와 S3 CORS가 통과한다.
9. participant/player URL 정책이 Flutter 버전과 동일하다.
10. public display/questions API에서 저장 결과를 확인할 수 있다.
