import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/admin_question.dart';
import '../model/question_image_upload_result.dart';
import '../service/admin_service.dart';
import '../service/admin_service_provider.dart';
import '../service/question_image_upload_service.dart';

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

class QuestionEditorState {
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

  final String title;
  final String detail;
  final QuestionImageUploadResult? image;
  final AdminQuestion? savedQuestion;
  final bool isUploading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  bool get canSave => title.trim().isNotEmpty && image != null && !isSaving;

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

class QuestionEditorController extends StateNotifier<QuestionEditorState> {
  QuestionEditorController({
    required String voteId,
    required AdminService service,
    required QuestionImageUploadService uploadService,
  }) : _voteId = voteId,
       _service = service,
       _uploadService = uploadService,
       super(const QuestionEditorState());

  final String _voteId;
  final AdminService _service;
  final QuestionImageUploadService _uploadService;

  void updateTitle(String value) {
    state = state.copyWith(title: value, clearError: true, clearSuccess: true);
  }

  void updateDetail(String value) {
    state = state.copyWith(detail: value, clearError: true, clearSuccess: true);
  }

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

  String? _validate() {
    if (state.title.trim().isEmpty) return '항목 제목을 입력해주세요.';
    if (state.image == null) return '포스터 이미지를 업로드해주세요.';
    if (state.image!.imageRatio <= 0) return '이미지 비율을 확인해주세요.';
    return null;
  }

  String _message(Object error, {required String fallback}) {
    final text = error.toString();
    return text.isEmpty ? fallback : text;
  }
}
