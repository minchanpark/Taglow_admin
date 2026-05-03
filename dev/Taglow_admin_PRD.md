# Taglow 관리자 서비스 PRD v1.0

## 0. 문서 개요

### 문서 목적
본 문서는 **Taglow 관리자 서비스**의 최종 제품 요구사항을 정의한다.  
관리자 서비스는 운영자가 `vote`와 `question`을 생성·관리하고, 현장에서 바로 사용할 수 있는 **참여자 링크, 참여자 QR 코드, 스탠바이미 player 링크**까지 한 번에 준비할 수 있도록 하는 Flutter Web 기반 운영 도구다.

### 문서 범위
이 PRD는 **관리자용 서비스**만 다룬다.

포함 범위:
- Spring ADMIN 로그인
- vote 생성, 조회, 수정, 상태 변경, 삭제
- question 생성, 조회, 수정, 삭제
- question 이미지 S3 업로드
- 참여자 URL 생성 및 복사
- 참여자 QR 코드 생성, 미리보기, 다운로드
- 스탠바이미 player URL 생성, 복사, 새 창 열기
- 저장 결과가 참여자 공개 API와 스탠바이미 player API에서 읽히는지 확인하는 운영 미리보기
- 참여자 프로젝트의 `View -> Controller -> Service -> Gateway/Mapper` 흐름을 관리자 프로젝트에 적용하는 기준

제외 범위:
- 참여자용 모바일 태깅 화면 자체
- 스탠바이미 실시간 player 화면 자체
- 태그 승인/숨김/삭제 moderation UI
- 태그 분석 대시보드
- 리워드 사용자 관리
- CSV/리포트 export
- AI 요약/분석
- 조직/팀/결제/멤버십 관리
- 실시간 스탠바이미 원격 제어

### 핵심 제품 원칙
> 관리자는 코드를 수정하거나 S3 콘솔을 직접 다루지 않고도, 현장 투표와 질문 이미지를 만들고 즉시 참여자 링크, QR 코드, 스탠바이미 player 링크를 얻을 수 있어야 한다.

관리자 서비스는 참여자 경험을 직접 제공하는 서비스가 아니라, 참여자와 스탠바이미가 소비하는 운영 데이터를 만드는 **현장 운영 콘솔**이다.

### 구조 원칙
- API 저장/조회 기능은 `View -> Controller -> Service -> Gateway/Mapper -> Generated Client/Dio -> Server` 흐름을 따른다.
- 이미지 업로드는 Service 계층 안에서 S3 API를 감춰 View/Controller가 storage 구현을 알지 않게 한다.
- 링크와 QR 생성은 서버 저장이 아니라 voteId 기반의 local utility/service에서 처리한다.
- Controller와 Service가 공유하는 데이터는 안정적인 관리자 domain model이어야 한다.
- View와 Controller는 Spring DTO, generated API client, S3 SDK를 직접 참조하지 않는다.
- 서버 API 변경은 Gateway와 Mapper에서 먼저 흡수한다.

---

## 1. 제품 정의

### 1-1. 제품명
**Taglow 관리자 서비스**

### 1-2. 한 줄 정의
운영자가 Spring ADMIN 계정으로 로그인해 vote와 question을 만들고, 질문 이미지를 S3에 업로드한 뒤, 참여자 링크·QR 코드·스탠바이미 player 링크를 발급하는 Flutter Web 관리자 도구.

### 1-3. 핵심 가치
- 운영자는 개발자 도움 없이 vote와 question을 만들 수 있다.
- 이미지 업로드, question 생성, 참여자 링크 생성, QR 다운로드, player 링크 확인이 하나의 흐름으로 연결된다.
- 참여자 서비스와 스탠바이미 화면이 같은 서버 데이터를 읽으므로 운영 데이터가 일관된다.
- 현장 운영자는 관리자 화면 하나만으로 부스 운영 준비를 끝낼 수 있다.
- API 스펙이 바뀌어도 Flutter 관리자 View/Controller 수정이 최소화된다.
- 관리자 프로젝트도 참여자 프로젝트와 같은 서버-Service-Model-Controller 구조를 따라 장기 유지보수 비용을 낮춘다.

---

## 2. 사용자 정의

## 2-1. 1차 사용자: 현장 운영자

### 상황
축제, 전시, 데모데이, 팝업스토어 현장에서 운영자가 태깅 참여용 투표와 질문 이미지를 준비한다.

### 니즈
- 로그인 후 바로 새 vote를 만들고 싶다.
- 질문 이미지를 업로드하면 question에 자동으로 연결되면 좋겠다.
- 참여자 링크를 바로 복사하고 싶다.
- 참여자 QR 코드를 바로 다운로드해 포스터, 스탠바이미, 태블릿에 띄우고 싶다.
- 스탠바이미 player 링크를 바로 열어서 현장 화면을 확인하고 싶다.
- 운영 중 vote 상태를 `PROGRESS` 또는 `END`로 바꾸고 싶다.

### 설계 포인트
- 화면은 운영 도구답게 조용하고 밀도 있게 구성한다.
- 입력 폼은 실수 방지를 위해 저장 전 검증과 미리보기를 제공한다.
- 저장 후 바로 링크/QR/player를 확인할 수 있어야 한다.
- QR은 현장에서 바로 쓸 수 있도록 충분히 큰 미리보기와 다운로드를 제공한다.

## 2-2. 2차 사용자: 개발/운영 관리자

### 상황
서버 API, S3, 배포 설정, player 연결 상태를 확인하고 운영 중 문제를 점검한다.

### 니즈
- 현재 API base URL과 배포 origin을 확인하고 싶다.
- 참여자 base URL과 player base URL이 올바른지 확인하고 싶다.
- 이미지 업로드 실패와 API 저장 실패를 구분하고 싶다.
- 공개 API에서 실제로 데이터가 내려오는지 확인하고 싶다.
- player 링크를 열었을 때 스탠바이미 화면이 정상적으로 뜨는지 확인하고 싶다.

### 설계 포인트
- 오류 메시지는 운영자가 조치할 수 있게 구체적이어야 한다.
- 서버 DTO나 내부 API 이름이 화면에 그대로 노출되지 않아야 한다.
- 디버그 정보는 운영 화면이 아니라 진단 화면과 개발자 콘솔/로그 중심으로 둔다.

---

## 3. 목표와 비목표

### 3-1. 목표
1. ADMIN 사용자가 로그인 후 vote를 생성할 수 있다.
2. ADMIN 사용자가 vote 이름과 상태를 수정할 수 있다.
3. ADMIN 사용자가 vote 안에 question을 생성할 수 있다.
4. ADMIN 사용자가 question 이미지를 S3에 직접 업로드할 수 있다.
5. question 저장 시 서버에는 이미지 bytes가 아니라 `imageUrl`과 `imageRatio`만 전달한다.
6. 저장된 vote/question은 참여자 공개 API와 스탠바이미 display API에서 읽혀야 한다.
7. 관리자 화면에서 참여자 URL `https://taglow-acca6.web.app/e/{voteId}`를 생성하고 복사할 수 있다.
8. 관리자 화면에서 참여자 URL을 payload로 하는 QR 코드를 생성하고 다운로드할 수 있다.
9. 관리자 화면에서 스탠바이미 player URL `https://taglow-player.web.app/display/{voteId}`를 생성하고 복사할 수 있다.
10. 관리자 화면에서 player URL을 새 창으로 열어 실제 스탠바이미 화면을 확인할 수 있다.
11. Flutter View/Controller는 서버 API DTO를 직접 알지 않고 안정적인 domain model만 사용한다.
12. 로그인, vote 관리, question 관리, 공개 API 미리보기는 모두 `View -> Controller -> Service -> Gateway/Mapper` 계층을 통해 수행한다.
13. question 이미지 업로드는 Controller가 storage SDK를 직접 쓰지 않고 `QuestionImageUploadService`를 통해 수행한다.

### 3-2. 비목표
1. 태그 승인/숨김/moderation은 MVP 범위에서 제외한다.
2. 태그 통계, 히트맵, 리워드 사용자 목록은 MVP 범위에서 제외한다.
3. 관리자 다중 조직/권한 세분화는 MVP 범위에서 제외한다.
4. 이미지 편집, 크롭, 리사이즈 도구는 MVP 범위에서 제외한다.
5. 실시간 스탠바이미 원격 제어는 MVP 범위에서 제외한다.
6. Spring 서버 모델을 그대로 노출하는 CRUD 생성기는 만들지 않는다.
7. QR 서버 생성 API는 MVP 범위에서 제외한다. QR은 관리자 Flutter Web에서 생성한다.

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
5. 관리자는 vote 상세 화면으로 이동해 question과 운영 링크를 관리한다.

## 4-3. question 생성 플로우
1. 관리자가 vote 상세 화면에서 question 추가를 누른다.
2. 제목, 상세 설명을 입력한다.
3. 질문 이미지를 선택한다.
4. Flutter가 이미지 bytes를 S3에 직접 업로드한다.
5. 업로드 완료 후 `imageUrl`과 이미지 원본 비율 `imageRatio`를 계산한다.
6. 서버에 question 생성 요청을 보낸다.
7. 저장된 question이 vote 상세 목록에 표시된다.
8. 공개 API 미리보기로 참여자/스탠바이미에서 읽히는지 확인한다.

## 4-4. 운영 링크/QR 발급 플로우
1. 관리자가 vote 상세 화면의 운영 링크 패널을 확인한다.
2. 참여자 URL은 `TAGLOW_PARTICIPANT_BASE_URL/e/{voteId}` 형식으로 생성된다.
3. 참여자 QR 코드는 참여자 URL을 payload로 하여 관리자 Flutter Web에서 렌더링된다.
4. 운영자는 참여자 URL을 복사할 수 있다.
5. 운영자는 QR 코드를 PNG 또는 SVG로 다운로드할 수 있다.
6. 스탠바이미 player URL은 `TAGLOW_PLAYER_BASE_URL/display/{voteId}` 형식으로 생성된다.
7. 운영자는 player URL을 복사하거나 새 창으로 열어 화면을 확인할 수 있다.
8. 공개 API quick check를 통해 player가 읽을 데이터가 존재하는지 확인한다.

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
  AdminService / MockAdminService / OpenApiAdminService / QuestionImageUploadService / QrExportService
    ↓ API payload conversion, URL generation, QR export, or storage operation
Gateway / Mapper
  AdminApiGateway / AdminPayloadMapper
    ↓ generated client and Dio
External Client / Storage
  Generated API Client / Dio / S3 API
    ↓
Server / Storage
  Spring Boot API / AWS S3

Model
  AdminUser / AdminVote / AdminQuestion / AdminVoteLinks / QuestionImageUploadResult
```

정책:
- View는 Controller 상태를 렌더링하고 사용자 입력만 전달한다.
- Controller는 `AdminService` 계약과 관리자 domain model만 사용한다.
- Service는 서버 저장, 공개 API 확인, 이미지 업로드, QR export 같은 유스케이스를 조합한다.
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
│   ├── 운영 링크/QR 패널
│   │   ├── 참여자 URL
│   │   ├── 참여자 QR 코드
│   │   ├── QR 다운로드
│   │   ├── 스탠바이미 player URL
│   │   └── player 새 창 열기
│   ├── 공개 API 미리보기
│   └── question 목록
├── question 작성/수정 화면
│   ├── 제목/상세 입력
│   ├── 이미지 업로드
│   ├── 이미지 비율 미리보기
│   └── 저장/취소
└── 설정/진단 화면
    ├── API base URL
    ├── 참여자 base URL
    ├── player base URL
    ├── S3 설정 상태
    ├── CORS 안내
    └── 공개 API quick check
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
하나의 vote에 포함된 question, 운영 링크, QR 코드, 스탠바이미 player 링크를 관리한다.

## 주요 UI
- vote 이름과 상태
- 이름 수정 버튼
- 상태 변경 control
- 운영 링크/QR 패널
- 공개 API 미리보기
- question 목록
- question 추가 버튼

## 기능 요구사항
- `GET /api/votes/{voteId}`와 `GET /api/votes/{voteId}/questions` 결과를 조합한다.
- vote 이름과 상태를 수정할 수 있다.
- 참여자 URL은 voteId 기반으로 생성한다.
- 참여자 QR 코드는 참여자 URL 기반으로 생성한다.
- 스탠바이미 player URL은 voteId 기반으로 생성한다.
- 공개 API 미리보기는 `GET /api/public/votes/{voteId}/display`와 `GET /api/public/votes/{voteId}/questions` 결과를 확인한다.

## 성공 기준
- vote 상세에서 question을 생성하고 참여자 URL을 복사할 수 있다.
- QR 코드를 미리보고 다운로드할 수 있다.
- player URL을 복사하거나 새 창으로 열 수 있다.
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
- `imageRatio`는 반응형 참여자 화면과 player 화면에서 이미지 bounds 계산에 쓰인다.
- 저장 실패 시 업로드 성공/서버 저장 실패를 구분해 표시한다.

## 성공 기준
- 운영자는 S3 콘솔 없이 question 이미지를 업로드하고 저장할 수 있다.
- 저장 후 참여자 화면과 player 화면에서 이미지가 표시된다.

# A5. 설정/진단 화면

## 화면 목적
운영/개발자가 관리자 배포와 API/S3/player 연결 상태를 점검한다.

## 주요 UI
- API base URL
- 관리자 배포 origin
- 참여자 base URL
- player base URL
- S3 bucket/region 설정 표시
- CORS 안내
- 공개 API quick check 버튼
- player route check 버튼

## 기능 요구사항
- secret이나 AWS access key는 표시하지 않는다.
- S3 업로드 설정 누락 시 question 저장 전 명확히 알린다.
- CORS 문제와 인증 문제를 구분해 안내한다.
- 참여자 링크와 player 링크의 base URL 설정 누락을 구분해 안내한다.

# A6. 운영 링크/QR 패널

## 화면 목적
운영자가 생성한 vote를 현장에서 바로 사용할 수 있도록 참여자 링크, 참여자 QR 코드, 스탠바이미 player 링크를 제공한다.

## 주요 UI
- 참여자 링크 표시
- 참여자 링크 복사 버튼
- 참여자 QR 코드 미리보기
- QR 코드 다운로드 버튼
- 스탠바이미 player 링크 표시
- player 링크 복사 버튼
- player 새 창 열기 버튼
- 공개 API quick check 버튼

## 기능 요구사항
- 참여자 링크는 `TAGLOW_PARTICIPANT_BASE_URL/e/{voteId}` 형식으로 생성한다.
- QR 코드는 참여자 링크를 payload로 하여 관리자 Flutter Web에서 렌더링한다.
- QR 코드는 PNG 다운로드를 기본으로 제공한다.
- 브라우저/렌더러 문제로 PNG export가 실패할 경우 SVG 또는 URL 복사 fallback을 제공한다.
- 스탠바이미 player 링크는 `TAGLOW_PLAYER_BASE_URL/display/{voteId}` 형식으로 생성한다.
- player 링크를 새 창으로 열어 실제 스탠바이미 화면을 확인할 수 있어야 한다.
- vote가 저장되지 않은 상태에서는 링크와 QR을 생성하지 않는다.
- 공개 API 미리보기에서 vote/question 데이터가 정상적으로 내려오는지 확인할 수 있어야 한다.

## 성공 기준
- 운영자는 개발자 도움 없이 참여자 링크를 복사할 수 있다.
- 운영자는 관리자 화면에서 QR 코드를 바로 확인하고 다운로드할 수 있다.
- 운영자는 스탠바이미 player 링크를 복사하거나 새 창으로 열 수 있다.
- QR을 스캔하면 참여자 모바일 화면으로 이동한다.
- player 링크를 열면 해당 vote의 스탠바이미 화면이 표시된다.

---

## 7. 데이터 모델

## 7-1. AdminUser
관리자 로그인 사용자.

필드 예시:
- `id`
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

## 7-6. AdminVoteLinks
vote 기반 운영 링크 묶음.

필드 예시:
- `voteId`
- `participantUrl`
- `participantQrPayload`
- `playerUrl`
- `playerPreviewUrl`

정책:
- `participantQrPayload`는 기본적으로 `participantUrl`과 동일하다.
- `playerUrl`은 스탠바이미 화면 진입 URL이다.
- MVP에서는 `voteId`를 player의 `eventId`로 사용한다.

---

## 8. URL / QR 정책

### 8-1. 참여자 URL

```text
{TAGLOW_PARTICIPANT_BASE_URL}/e/{voteId}
```

예시:

```text
https://taglow-acca6.web.app/e/venturous-2026
```

### 8-2. QR 코드

```text
QR payload = participantUrl
```

정책:
- QR은 관리자 Flutter Web에서 렌더링한다.
- 서버에 QR 이미지 생성 API를 요구하지 않는다.
- QR 다운로드 파일명은 `taglow-{voteId}-participant-qr.png`를 기본으로 한다.
- QR에는 관리자 URL, secret, token, AWS 정보 등을 넣지 않는다.

### 8-3. 스탠바이미 player URL

```text
{TAGLOW_PLAYER_BASE_URL}/display/{voteId}
```

예시:

```text
https://taglow-player.web.app/display/venturous-2026
```

### 8-4. player 문서와의 도메인 매핑

스탠바이미 player 문서에서 사용하는 용어와 관리자 도메인의 용어는 다음처럼 매핑한다.

| 관리자 도메인 | player 도메인 | 설명 |
|---|---|---|
| `voteId` | `eventId` | 하나의 현장 투표/전시 세션 |
| `questionId` | `itemId` | player에서 순환 표시되는 항목 |

MVP에서는 별도 event 도메인을 만들지 않고 `vote`를 display event 단위로 사용한다.

---

## 9. API와 도메인 분리 정책

관리자 Flutter는 Spring API와 서버 DTO를 View/Controller에서 직접 알지 않는다.

원칙:
- View는 Controller만 사용한다.
- Controller는 `AdminService` domain API만 호출한다.
- `OpenApiAdminService`는 `AdminApiGateway`와 `AdminPayloadMapper`를 조합한다.
- `AdminApiGateway`는 endpoint, path, header, generated client 변화를 흡수한다.
- `AdminPayloadMapper`는 서버 payload와 관리자 domain model 사이 변환만 담당한다.
- 서버 API가 바뀌어도 View/Controller는 가능하면 수정하지 않는다.
- 링크/QR 생성은 서버 API와 분리된 local utility/service로 처리한다.

계층별 금지 사항:

| 계층 | 허용 | 금지 |
|---|---|---|
| View | Controller provider 구독, UI 렌더링, 사용자 입력 전달 | Dio 호출, generated DTO import, S3 SDK 호출 |
| Controller | domain model 상태 관리, validation, `AdminService` 호출, 링크/QR export service 호출 | endpoint 문자열 보유, payload key 직접 조립 |
| Service | 유스케이스 orchestration, mapper/gateway 조합, QR export | Widget import, 화면 전용 상태 보유 |
| Mapper | payload와 domain model 변환 | 네트워크 호출, Riverpod provider 참조 |
| Gateway | endpoint, header, cookie, generated client 호출 | domain UI 상태 관리, Widget import |

---

## 10. 보안 및 개인정보 정책

### 10-1. 인증과 권한
- 관리자 서비스는 로그인 없이 접근할 수 없다.
- ADMIN role이 없는 사용자는 vote/question 관리 화면에 접근할 수 없다.
- Spring session/cookie 인증을 기본으로 한다.
- 클라이언트는 서버 secret, AWS access key, 관리자 비밀번호를 저장하지 않는다.
- 클라이언트 route guard는 UX 보호 수단이며, 서버 API는 반드시 ADMIN 권한을 검증해야 한다.

### 10-2. S3 보안
- Flutter에는 장기 AWS access key를 넣지 않는다.
- S3 업로드는 Cognito 임시 자격 증명 또는 서버 발급 upload policy를 사용한다.
- MVP 기본값은 Cognito/Amplify 기반 S3 직접 업로드다.
- 질문 이미지 prefix는 `public/question-images`를 기본으로 한다.

### 10-3. 링크/QR 보안
- 참여자 QR에는 공개 참여자 URL만 포함한다.
- QR에는 관리자 URL, 관리자 token, session, 내부 API URL을 포함하지 않는다.
- player URL은 공개 display 화면 진입용 URL이므로 secret을 포함하지 않는다.
- player 접근 제어가 필요해지면 MVP 이후 별도 PRD/TDD에서 다룬다.

### 10-4. 데이터 노출
- 관리자 화면은 참여자 개인정보를 다루지 않는다.
- 리워드 사용자 데이터는 MVP 범위가 아니다.
- 공개 참여자 API에 노출될 vote/question 데이터만 생성한다.

---

## 11. 검증 및 QA 시나리오

### 11-1. 기본 생성 시나리오
1. ADMIN 사용자가 로그인한다.
2. vote 목록 화면에 진입한다.
3. 새 vote를 생성한다.
4. vote 상세 화면에서 question 추가를 누른다.
5. 이미지를 선택하고 업로드한다.
6. 제목과 상세 설명을 입력한다.
7. question을 저장한다.
8. 운영 링크/QR 패널에서 참여자 URL을 복사한다.
9. QR 코드를 다운로드한다.
10. player URL을 새 창으로 연다.
11. 공개 API 미리보기에서 vote/question이 보이는지 확인한다.

### 11-2. QR 사용 시나리오
1. 운영자가 vote 상세 화면에서 QR을 확인한다.
2. QR을 다운로드한다.
3. 휴대폰 카메라로 QR을 스캔한다.
4. 참여자 모바일 웹 `/e/{voteId}`로 이동한다.
5. 해당 vote의 question 목록 또는 참여 화면이 표시된다.

### 11-3. player 링크 시나리오
1. 운영자가 vote 상세 화면에서 player URL을 확인한다.
2. player URL을 복사하거나 새 창으로 연다.
3. player 화면 `/display/{voteId}`가 열린다.
4. 해당 vote의 question들이 player 항목으로 표시된다.
5. 참여자가 태그를 남기면 player 화면에 반영된다.

### 11-4. 상태 변경 시나리오
1. vote 상세 화면에 진입한다.
2. 상태를 `END`로 변경한다.
3. 공개 display API의 status도 `END`로 내려오는지 확인한다.
4. 참여자 화면 또는 player 화면에서 종료 상태가 적절히 반영되는지 확인한다.

### 11-5. 실패 시나리오
- 로그인 실패 시 vote 목록에 접근하지 못한다.
- ADMIN role이 없으면 접근 불가 상태가 표시된다.
- S3 업로드 실패 시 question 저장은 실행되지 않는다.
- S3 업로드 성공 후 서버 저장 실패 시 재시도할 수 있다.
- `imageUrl` 또는 `imageRatio`가 없으면 question 저장을 막는다.
- `TAGLOW_PARTICIPANT_BASE_URL`이 없으면 참여자 링크/QR 생성 오류를 표시한다.
- `TAGLOW_PLAYER_BASE_URL`이 없으면 player 링크 생성 오류를 표시한다.
- QR 다운로드 실패 시 URL 복사 fallback을 제공한다.
- CORS 실패와 인증 실패를 운영자가 구분할 수 있어야 한다.

---

## 12. MVP 구현 전 필수 서버/환경 조건

| 항목 | 필수 조건 |
|---|---|
| 관리자 vote 생성 endpoint | `POST /api/votes` 또는 이에 준하는 ADMIN 보호 endpoint 필요 |
| question imageRatio | DB, DTO, OpenAPI schema 모두 double/number 기준 필요 |
| 관리자 인증 | Spring session/cookie 또는 token 방식 확정 필요 |
| CORS | 관리자 배포 origin과 `https://taglow-player.web.app`을 allowlist에 포함해야 함 |
| CSRF | cookie 인증을 쓸 경우 state-changing request의 CSRF 정책 확정 필요 |
| S3 업로드 | Cognito 직접 업로드 또는 서버 presigned URL 방식 중 하나 확정 필요 |
| 참여자 base URL | `TAGLOW_PARTICIPANT_BASE_URL=https://taglow-acca6.web.app` 기준 |
| player base URL | `TAGLOW_PLAYER_BASE_URL=https://taglow-player.web.app` 기준 |
| player route | `/display/{voteId}` route가 player 프로젝트에 구현되어야 함 |

---

## 13. 오픈 이슈

| 항목 | 내용 |
|---|---|
| 관리자 배포 도메인 | Firebase Hosting을 쓸지 AWS Hosting을 쓸지 확정 필요 |
| player route | `https://taglow-player.web.app/display/{voteId}` 기준으로 player 프로젝트 route 구현 확인 필요 |
| vote 생성 endpoint | 현재 OpenAPI의 `POST /api/public/votes`는 관리자 생성 API로 부적절하므로 ADMIN 보호 endpoint 확정 필요 |
| imageRatio 타입 | 현재 OpenAPI는 integer지만 반응형 이미지 계산에는 double 필요 |
| player CORS | runtime preflight 기준 `https://taglow-player.web.app` origin이 아직 거부되므로 서버 allowlist 추가 필요 |
| 인증 방식 | Spring session/cookie 기본. 토큰 방식으로 바뀌면 TDD의 auth gateway에서 흡수 |
| S3 업로드 방식 | Cognito/Amplify 직접 업로드와 서버 presigned URL 중 운영 방식 확정 필요 |
| CloudFront | AWS 계정 검증 완료 전에는 S3 public URL fallback 허용 |
| QR export format | PNG 기본, SVG fallback 제공 여부 확정 필요 |
| 태그 moderation | MVP 이후 관리자 서비스 확장 단계에서 별도 PRD/TDD 필요 |

---

## 14. 최종 구현 기준 요약

Taglow 관리자 서비스는 운영자가 vote와 question을 직접 준비하고, 현장 운영에 필요한 링크와 QR까지 한 번에 발급할 수 있게 하는 별도 Flutter Web 서비스다.

최종 기준:
1. ADMIN 사용자만 접근할 수 있어야 한다.
2. vote와 question 생성/수정/삭제가 가능해야 한다.
3. question 이미지는 S3에 직접 업로드되어야 한다.
4. 서버에는 이미지 bytes가 아니라 URL과 비율만 저장해야 한다.
5. 참여자/스탠바이미 공개 API에서 저장 결과가 확인되어야 한다.
6. 참여자 링크는 voteId 기반으로 생성되어야 한다.
7. 참여자 QR은 참여자 링크를 payload로 생성되어야 한다.
8. QR은 관리자 화면에서 미리보기와 다운로드가 가능해야 한다.
9. 스탠바이미 player 링크는 voteId 기반으로 생성되어야 한다.
10. player 링크를 새 창으로 열어 현장 화면을 확인할 수 있어야 한다.
11. Flutter View/Controller는 서버 DTO와 generated client를 직접 알면 안 된다.
12. 서버 API 변화는 Gateway와 Mapper에서 우선 흡수해야 한다.
13. 관리자 프로젝트의 폴더와 의존성은 참여자 프로젝트의 `api/controller`, `api/model`, `api/service` 구조를 따른다.
