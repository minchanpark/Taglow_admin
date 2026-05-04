import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/controller/question_editor_controller.dart';
import '../../api/model/question_image_upload_result.dart';
import '../../theme/admin_theme.dart';
import '../admin_widgets.dart';

/// 특정 vote에 question을 추가하는 화면입니다.
/// 입력과 upload/save 상태는 [questionEditorControllerProvider] family provider에서 읽습니다.
/// fields:
/// - [voteId]: question을 추가할 vote 식별자입니다.
class QuestionEditorPage extends ConsumerStatefulWidget {
  /// question editor 화면 widget을 생성합니다.
  /// route parameter의 voteId를 Controller family provider에 전달합니다.
  /// Parameters:
  /// - [voteId]: question이 속할 vote 식별자입니다.
  /// - [key]: Flutter widget 식별 key입니다.
  /// Returns:
  /// - [instance]: question editor 화면 widget 인스턴스입니다.
  const QuestionEditorPage({required this.voteId, super.key});

  /// question을 추가할 대상 vote 식별자입니다.
  /// 저장 Controller와 뒤로가기 route에 함께 사용됩니다.
  final String voteId;

  /// question editor 화면 state를 생성합니다.
  /// TextEditingController lifecycle과 Controller submit 결과 처리를 state에서 관리합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: question editor 화면 state 객체입니다.
  @override
  ConsumerState<QuestionEditorPage> createState() => _QuestionEditorPageState();
}

/// question form 입력, upload button, save action UI를 관리하는 state입니다.
/// 이미지 선택/업로드와 question 저장은 Controller에 위임하고 View는 상태만 렌더링합니다.
/// fields:
/// - [_titleController]: question 제목 입력 상태입니다.
/// - [_detailController]: question 설명 입력 상태입니다.
class _QuestionEditorPageState extends ConsumerState<QuestionEditorPage> {
  /// question 제목 입력을 보관하는 TextEditingController입니다.
  /// 입력 변경 시 [QuestionEditorController.updateTitle]과 동기화됩니다.
  final _titleController = TextEditingController();

  /// question 설명 입력을 보관하는 TextEditingController입니다.
  /// 선택 입력값을 [QuestionEditorController.updateDetail]로 전달합니다.
  final _detailController = TextEditingController();

  /// form 입력 controller 자원을 해제합니다.
  /// 업로드 결과와 저장 상태는 Riverpod Controller lifecycle이 관리합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [void]: 상태 변경이나 부수 효과만 수행하고 값을 반환하지 않습니다.
  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  /// question editor 화면 UI를 빌드합니다.
  /// upload/save action은 Controller method를 호출하고 성공 결과에 따라 입력 초기화나 route 이동을 처리합니다.
  /// Parameters:
  /// - [context]: Flutter build context입니다.
  /// Returns:
  /// - [result]: question editor 화면 widget tree입니다.
  @override
  Widget build(BuildContext context) {
    final provider = questionEditorControllerProvider(widget.voteId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    return AdminMobileShell(
      child: Column(
        children: <Widget>[
          AdminTopBar(
            title: '항목 추가',
            onBack: () => context.go('/votes/${widget.voteId}'),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    '세부 항목 정보를\n입력해주세요.',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '투표에 들어갈 항목을 여러 개 추가할 수 있습니다.',
                    style: TextStyle(
                      color: AdminColors.textMuted,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AdminColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AdminColors.line),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      children: <Widget>[
                        AdminTextInput(
                          label: '항목 제목',
                          controller: _titleController,
                          hintText: '예: 실소',
                          large: true,
                          onChanged: controller.updateTitle,
                        ),
                        const SizedBox(height: 24),
                        AdminTextInput(
                          label: '설명 (선택)',
                          controller: _detailController,
                          hintText: '간단한 설명을 입력해주세요.',
                          onChanged: controller.updateDetail,
                        ),
                        const SizedBox(height: 32),
                        _PosterUploadButton(
                          image: state.image,
                          isUploading: state.isUploading,
                          onTap: controller.uploadImage,
                        ),
                      ],
                    ),
                  ),
                  if (state.errorMessage != null) ...<Widget>[
                    const SizedBox(height: 16),
                    AdminMessage.error(state.errorMessage!),
                  ],
                  if (state.successMessage != null) ...<Widget>[
                    const SizedBox(height: 16),
                    AdminMessage.success(state.successMessage!),
                  ],
                ],
              ),
            ),
          ),
          AdminBottomBar(
            children: <Widget>[
              Expanded(
                child: AdminPrimaryButton(
                  label: '다음 항목 추가',
                  secondary: true,
                  enabled: state.canSave,
                  isBusy: state.isSaving,
                  onPressed: () async {
                    final saved = await controller.save(resetAfterSave: true);
                    if (saved != null) {
                      _titleController.clear();
                      _detailController.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminPrimaryButton(
                  label: '완료하기',
                  enabled: state.canSave,
                  isBusy: state.isSaving,
                  onPressed: () async {
                    final saved = await controller.save(resetAfterSave: false);
                    if (!context.mounted) {
                      return;
                    }
                    if (saved != null) {
                      context.go('/votes/${widget.voteId}');
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// question poster image upload action을 표시하는 private widget입니다.
/// View는 업로드 상태와 prepared 상태만 넘기고 실제 upload는 Controller callback으로 수행합니다.
/// fields:
/// - [image]: 업로드 결과가 준비되었을 때 표시할 이미지 정보입니다.
/// - [isUploading]: 업로드 진행 중인지 나타냅니다.
/// - [onTap]: 업로드 시작 action callback입니다.
class _PosterUploadButton extends StatelessWidget {
  /// poster upload button widget을 생성합니다.
  /// Controller state에 따라 check icon, upload icon, loading indicator를 전환합니다.
  /// Parameters:
  /// - [image]: 업로드된 이미지 결과입니다.
  /// - [isUploading]: 업로드 진행 여부입니다.
  /// - [onTap]: tap callback입니다.
  /// Returns:
  /// - [instance]: poster upload button widget 인스턴스입니다.
  const _PosterUploadButton({
    required this.image,
    required this.isUploading,
    required this.onTap,
  });

  /// 이미지 업로드 결과가 준비되었는지 나타냅니다.
  /// null이 아니면 preview와 원본 이미지 비율을 표시합니다.
  final QuestionImageUploadResult? image;

  /// 이미지 업로드가 진행 중인지 나타냅니다.
  /// true이면 tap을 막고 loading indicator를 표시합니다.
  final bool isUploading;

  /// upload button tap callback입니다.
  /// [QuestionEditorController.uploadImage]와 연결됩니다.
  final VoidCallback onTap;

  /// poster upload 영역을 빌드합니다.
  /// 업로드 진행, 완료, 대기 상태를 한 영역 안에서 전환합니다.
  /// Parameters:
  /// - [context]: Flutter build context입니다.
  /// Returns:
  /// - [result]: poster upload widget tree입니다.
  @override
  Widget build(BuildContext context) {
    final uploadedImage = image;
    final hasImage = uploadedImage != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '포스터 이미지',
            style: TextStyle(
              color: AdminColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: isUploading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 370,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AdminColors.page,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD1D5DC), width: 1.8),
            ),
            child: Center(
              child: isUploading
                  ? const CircularProgressIndicator()
                  : hasImage
                  ? _UploadedPosterPreview(image: uploadedImage)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: AdminColors.surface,
                            shape: BoxShape.circle,
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate_outlined,
                            color: AdminColors.muted,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          '이미지를 업로드하려면 탭하세요',
                          style: TextStyle(
                            color: AdminColors.textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 업로드된 question poster preview와 ratio 정보를 표시하는 widget입니다.
/// 네트워크 이미지 로딩 실패 시에도 저장된 URL/ratio 상태가 사라지지 않도록 fallback을 렌더링합니다.
/// fields:
/// - [image]: 업로드된 이미지 결과입니다.
class _UploadedPosterPreview extends StatelessWidget {
  /// 업로드 완료 preview widget을 생성합니다.
  /// Parameters:
  /// - [image]: 업로드된 이미지 결과입니다.
  /// Returns:
  /// - [instance]: 업로드 완료 preview widget입니다.
  const _UploadedPosterPreview({required this.image});

  /// 업로드된 이미지 결과입니다.
  final QuestionImageUploadResult image;

  /// preview와 비율 badge를 빌드합니다.
  /// Parameters:
  /// - [context]: Flutter build context입니다.
  /// Returns:
  /// - [result]: preview widget tree입니다.
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            image.publicUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: _UploadReadyMessage());
            },
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xCCFFFFFF),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Text(
              '이미지가 준비되었습니다 · 비율 ${image.imageRatio.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AdminColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 이미지 URL preview가 실패했을 때 보여주는 업로드 완료 fallback입니다.
/// 업로드는 성공했지만 public read나 테스트 HTTP client가 이미지를 읽지 못하는 상황을 구분합니다.
/// fields:
/// - [none]: 저장 필드가 없으며, 연결 관계는 생성/호출 위치에서 결정됩니다.
class _UploadReadyMessage extends StatelessWidget {
  /// 업로드 완료 fallback widget을 생성합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [instance]: 업로드 완료 fallback widget입니다.
  const _UploadReadyMessage();

  /// 업로드 완료 fallback UI를 빌드합니다.
  /// Parameters:
  /// - [context]: Flutter build context입니다.
  /// Returns:
  /// - [result]: fallback widget tree입니다.
  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.check_rounded, color: AdminColors.muted, size: 32),
        SizedBox(height: 10),
        Text(
          '이미지가 준비되었습니다',
          style: TextStyle(
            color: AdminColors.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
