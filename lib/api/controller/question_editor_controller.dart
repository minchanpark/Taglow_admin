import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/admin_question.dart';
import '../model/question_image_upload_result.dart';
import '../service/admin_service.dart';
import '../service/admin_service_provider.dart';
import '../service/question_image_upload_service.dart';

/// vote별 question editor 상태를 제공하는 family provider입니다.
/// View가 voteId를 넘기면 Controller가 [AdminService]와 [QuestionImageUploadService]를 주입받습니다.
/// 이미지 업로드와 question 저장 경계를 UI에서 분리합니다.
final questionEditorControllerProvider =
    StateNotifierProvider.family<
      QuestionEditorController,
      QuestionEditorState,
      String
    >((ref, voteId) {
      return QuestionEditorController(
        voteId: voteId,
        service: ref.watch(adminServiceProvider),
        uploadService: ref.watch(questionImageUploadServiceProvider),
      );
    });

/// question 생성 화면이 렌더링하는 입력, 업로드, 저장 상태입니다.
/// QuestionEditorPage는 이 값만 읽고 upload/storage/API 세부 구현을 알지 않습니다.
/// fields:
/// - [title]: 운영자가 입력한 question 제목입니다.
/// - [detail]: 선택 입력 설명이며 저장 payload의 설명 값으로 전달됩니다.
/// - [image]: 업로드 service가 반환한 이미지 결과입니다.
/// - [savedQuestion]: 저장 성공 후 생성된 question domain model입니다.
/// - [isUploading]: 이미지 업로드 진행 여부입니다.
/// - [isSaving]: question 저장 요청 진행 여부입니다.
/// - [errorMessage]: 업로드 또는 저장 실패를 View에 표시할 메시지입니다.
/// - [successMessage]: 업로드 준비 또는 저장 완료 피드백입니다.
class QuestionEditorState {
  /// question editor 상태를 생성합니다.
  /// Controller가 사용자 입력과 비동기 작업 결과를 불변 값으로 교체합니다.
  /// Parameters:
  /// - [title]: question 제목 입력값입니다.
  /// - [detail]: question 설명 입력값입니다.
  /// - [image]: 업로드 완료 이미지 결과입니다.
  /// - [savedQuestion]: 저장 성공 question입니다.
  /// - [isUploading]: 업로드 로딩 여부입니다.
  /// - [isSaving]: 저장 로딩 여부입니다.
  /// - [errorMessage]: 오류 메시지입니다.
  /// - [successMessage]: 성공 메시지입니다.
  /// Returns:
  /// - [instance]: question editor 상태를 보관하는 새 인스턴스입니다.
  const QuestionEditorState({
    this.title = '',
    this.detail = '',
    this.image,
    this.savedQuestion,
    this.isUploading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  /// question 제목 입력값입니다.
  /// 저장 validation과 Service payload 생성의 기준이 됩니다.
  final String title;

  /// question 설명 입력값입니다.
  /// 저장 시 공백이 trim된 뒤 Service로 전달됩니다.
  final String detail;

  /// 업로드된 question 이미지 결과입니다.
  /// 저장 시 [QuestionImageUploadResult.publicUrl]과 [QuestionImageUploadResult.imageRatio]를 사용합니다.
  final QuestionImageUploadResult? image;

  /// 마지막으로 저장된 question 결과입니다.
  /// 완료 후 상세 화면 이동이나 후속 UI 판단에 사용할 수 있습니다.
  final AdminQuestion? savedQuestion;

  /// 이미지 업로드가 진행 중인지 나타냅니다.
  /// 업로드 버튼의 busy/disabled 상태와 연결됩니다.
  final bool isUploading;

  /// question 저장 요청이 진행 중인지 나타냅니다.
  /// 하단 저장 버튼들의 busy/disabled 상태와 연결됩니다.
  final bool isSaving;

  /// 업로드 또는 저장 실패 메시지입니다.
  /// View는 API나 upload 내부 오류 대신 이 안전한 문구를 표시합니다.
  final String? errorMessage;

  /// 이미지 준비나 question 저장 성공 메시지입니다.
  /// 화면은 이 값을 통해 작업 완료를 운영자에게 알려줍니다.
  final String? successMessage;

  /// 현재 입력 상태로 저장 버튼을 활성화할 수 있는지 계산합니다.
  /// title과 image가 준비되고 저장 중이 아닐 때만 true입니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: 저장 action 활성화 가능 여부입니다.
  bool get canSave => title.trim().isNotEmpty && image != null && !isSaving;

  /// 일부 question editor 상태만 교체한 새 상태를 만듭니다.
  /// 입력 변경, 업로드 결과, 저장 결과, 메시지 정리를 명시적으로 처리합니다.
  /// Parameters:
  /// - [title]: 교체할 제목입니다.
  /// - [detail]: 교체할 설명입니다.
  /// - [image]: 교체할 업로드 결과입니다.
  /// - [clearImage]: 기존 업로드 결과를 지울지 결정합니다.
  /// - [savedQuestion]: 교체할 저장 완료 question입니다.
  /// - [clearSavedQuestion]: 기존 저장 결과를 지울지 결정합니다.
  /// - [isUploading]: 업로드 로딩 상태입니다.
  /// - [isSaving]: 저장 로딩 상태입니다.
  /// - [errorMessage]: 새 오류 메시지입니다.
  /// - [clearError]: 기존 오류 메시지를 지울지 결정합니다.
  /// - [successMessage]: 새 성공 메시지입니다.
  /// - [clearSuccess]: 기존 성공 메시지를 지울지 결정합니다.
  /// Returns:
  /// - [result]: 변경값이 반영된 새 [QuestionEditorState]입니다.
  QuestionEditorState copyWith({
    String? title,
    String? detail,
    QuestionImageUploadResult? image,
    bool clearImage = false,
    AdminQuestion? savedQuestion,
    bool clearSavedQuestion = false,
    bool? isUploading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return QuestionEditorState(
      title: title ?? this.title,
      detail: detail ?? this.detail,
      image: clearImage ? null : image ?? this.image,
      savedQuestion: clearSavedQuestion
          ? null
          : savedQuestion ?? this.savedQuestion,
      isUploading: isUploading ?? this.isUploading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage: clearSuccess
          ? null
          : successMessage ?? this.successMessage,
    );
  }
}

/// question 작성, 이미지 업로드, 저장을 조율하는 Controller입니다.
/// View 이벤트를 Service 호출로 연결하고 저장 payload에는 imageUrl과 imageRatio만 넘깁니다.
/// upload 구현과 Admin API 구현은 각각 주입된 Service 계약 뒤에 둡니다.
/// fields:
/// - [_voteId]: 새 question이 속할 vote 식별자입니다.
/// - [_service]: question 생성 API를 담당하는 관리자 Service 계약입니다.
/// - [_uploadService]: 이미지 업로드와 비율 결과를 제공하는 upload Service 계약입니다.
class QuestionEditorController extends StateNotifier<QuestionEditorState> {
  /// question editor Controller를 생성합니다.
  /// family provider가 voteId와 필요한 Service들을 주입합니다.
  /// Parameters:
  /// - [voteId]: 새 question을 추가할 vote 식별자입니다.
  /// - [service]: question 저장을 수행하는 관리자 Service입니다.
  /// - [uploadService]: 이미지 업로드 결과를 만드는 Service입니다.
  /// Returns:
  /// - [instance]: question editor 상태를 관리하는 새 Controller입니다.
  QuestionEditorController({
    required String voteId,
    required AdminService service,
    required QuestionImageUploadService uploadService,
  }) : _voteId = voteId,
       _service = service,
       _uploadService = uploadService,
       super(const QuestionEditorState());

  /// question 저장 payload에 포함될 vote 식별자입니다.
  /// View는 route parameter로 넘기고 Controller가 Service 호출에 사용합니다.
  final String _voteId;

  /// question 생성 API를 수행하는 Service 의존성입니다.
  /// Controller가 gateway, mapper, endpoint를 직접 알지 않게 합니다.
  final AdminService _service;

  /// 이미지 업로드를 수행하는 Service 의존성입니다.
  /// S3나 presigned URL 같은 저장소 세부 구현을 Controller 밖에 둡니다.
  final QuestionImageUploadService _uploadService;

  /// title 입력 변경을 상태에 반영합니다.
  /// View의 TextField 변경 이벤트와 연결되며 이전 메시지를 정리합니다.
  /// Parameters:
  /// - [value]: 새 question 제목 입력값입니다.
  /// Returns:
  /// - [void]: 상태 변경이나 부수 효과만 수행하고 값을 반환하지 않습니다.
  void updateTitle(String value) {
    state = state.copyWith(title: value, clearError: true, clearSuccess: true);
  }

  /// detail 입력 변경을 상태에 반영합니다.
  /// View의 설명 TextField와 연결되며 저장 payload 전 단계의 draft 값입니다.
  /// Parameters:
  /// - [value]: 새 question 설명 입력값입니다.
  /// Returns:
  /// - [void]: 상태 변경이나 부수 효과만 수행하고 값을 반환하지 않습니다.
  void updateDetail(String value) {
    state = state.copyWith(detail: value, clearError: true, clearSuccess: true);
  }

  /// 이미지 업로드 Service를 호출하고 결과를 editor 상태에 저장합니다.
  /// 현재 구현은 mock 입력을 사용하며 실제 파일 선택/디코딩은 Service 경계 뒤로 확장됩니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [completion]: 비동기 작업 완료를 의미하며 값은 반환하지 않습니다.
  Future<void> uploadImage() async {
    state = state.copyWith(
      isUploading: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final result = await _uploadService.uploadQuestionImage(
        bytes: const <int>[1, 2, 3, 4],
        fileName: 'mock-question.png',
        contentType: 'image/png',
        imageWidth: 900,
        imageHeight: 1200,
      );
      state = state.copyWith(
        image: result,
        isUploading: false,
        successMessage: '이미지가 준비되었습니다.',
      );
    } catch (error) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: _message(error, fallback: '이미지 업로드 서비스를 연결해주세요.'),
      );
    }
  }

  /// question 입력값을 검증한 뒤 AdminService에 저장을 요청합니다.
  /// 서버에는 이미지 bytes가 아니라 업로드 결과의 publicUrl과 imageRatio만 전달합니다.
  /// Parameters:
  /// - [resetAfterSave]: 저장 후 다음 항목 입력을 위해 draft 상태를 초기화할지 결정합니다.
  /// Returns:
  /// - [result]: 저장된 [AdminQuestion]이거나 실패 시 null입니다.
  Future<AdminQuestion?> save({required bool resetAfterSave}) async {
    final validationError = _validate();
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError, clearSuccess: true);
      return null;
    }

    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final image = state.image!;
      final question = await _service.createQuestion(
        voteId: _voteId,
        title: state.title.trim(),
        detail: state.detail.trim(),
        imageUrl: image.publicUrl,
        imageRatio: image.imageRatio,
      );
      state = resetAfterSave
          ? QuestionEditorState(successMessage: '항목이 저장되었습니다.')
          : state.copyWith(
              savedQuestion: question,
              isSaving: false,
              successMessage: '항목이 저장되었습니다.',
            );
      return question;
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: _message(error, fallback: '항목을 저장하지 못했습니다.'),
      );
      return null;
    }
  }

  /// 저장 전 필수 입력과 이미지 비율을 검증합니다.
  /// Controller 단에서 View와 Service 사이의 고위험 validation을 한 번 더 보호합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: validation 실패 메시지이거나 통과 시 null입니다.
  String? _validate() {
    if (state.title.trim().isEmpty) return '항목 제목을 입력해주세요.';
    if (state.image == null) return '포스터 이미지를 업로드해주세요.';
    if (state.image!.imageRatio <= 0) return '이미지 비율을 확인해주세요.';
    return null;
  }

  /// 오류 객체를 editor 화면에 표시할 메시지로 정규화합니다.
  /// upload 실패와 API 저장 실패가 각각 호출자가 지정한 fallback을 유지하게 합니다.
  /// Parameters:
  /// - [error]: Service 호출 중 발생한 오류 객체입니다.
  /// - [fallback]: 오류 문자열이 비어 있을 때 사용할 기본 메시지입니다.
  /// Returns:
  /// - [result]: 사용자에게 표시할 오류 메시지입니다.
  String _message(Object error, {required String fallback}) {
    final text = error.toString();
    return text.isEmpty ? fallback : text;
  }
}
