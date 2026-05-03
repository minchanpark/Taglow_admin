import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/controller/question_editor_controller.dart';
import '../../theme/admin_theme.dart';
import '../admin_widgets.dart';

class QuestionEditorPage extends ConsumerStatefulWidget {
  const QuestionEditorPage({required this.voteId, super.key});

  final String voteId;

  @override
  ConsumerState<QuestionEditorPage> createState() => _QuestionEditorPageState();
}

class _QuestionEditorPageState extends ConsumerState<QuestionEditorPage> {
  final _titleController = TextEditingController();
  final _detailController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    super.dispose();
  }

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
                          hasImage: state.image != null,
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

class _PosterUploadButton extends StatelessWidget {
  const _PosterUploadButton({
    required this.hasImage,
    required this.isUploading,
    required this.onTap,
  });

  final bool hasImage;
  final bool isUploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                          child: Icon(
                            hasImage
                                ? Icons.check_rounded
                                : Icons.add_photo_alternate_outlined,
                            color: AdminColors.muted,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          hasImage ? '이미지가 준비되었습니다' : '이미지를 업로드하려면 탭하세요',
                          style: const TextStyle(
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
