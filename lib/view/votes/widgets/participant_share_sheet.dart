import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../api/model/admin_vote_links.dart';
import '../../../theme/admin_theme.dart';

/// 참여자 링크와 QR을 공유하기 위한 vote 상세 modal sheet입니다.
/// 링크 값과 action callback은 parent View/Controller에서 주입받아 browser 부수 효과를 직접 다루지 않습니다.
/// fields:
/// - [links]: 참여자 URL과 QR payload를 담은 운영 링크 model입니다.
/// - [onExternalShare]: 외부 공유 button callback입니다.
/// - [onCopyLink]: 참여자 링크 복사 button callback입니다.
class ParticipantShareSheet extends StatefulWidget {
  /// 참여자 공유 sheet를 생성합니다.
  /// Parameters:
  /// - [links]: 표시할 참여자 링크와 QR payload입니다.
  /// - [onExternalShare]: 외부 공유 action입니다.
  /// - [onCopyLink]: 링크 복사 action입니다.
  /// - [key]: Flutter widget 식별 key입니다.
  /// Returns:
  /// - [instance]: 참여자 공유 sheet widget 인스턴스입니다.
  const ParticipantShareSheet({
    required this.links,
    required this.onExternalShare,
    required this.onCopyLink,
    super.key,
  });

  /// 참여자 URL, QR payload, player URL을 담은 운영 링크 model입니다.
  final AdminVoteLinks links;

  /// “외부로 공유하기” button이 호출하는 action입니다.
  final Future<void> Function() onExternalShare;

  /// “링크 복사” button이 호출하는 action입니다.
  final Future<void> Function() onCopyLink;

  /// 참여자 공유 sheet state를 생성합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: 참여자 공유 sheet state 객체입니다.
  @override
  State<ParticipantShareSheet> createState() => _ParticipantShareSheetState();
}

enum _ParticipantShareAction { externalShare, copyLink }

/// 참여자 공유 sheet의 button busy 상태와 layout을 관리합니다.
/// fields:
/// - [_busyAction]: 현재 실행 중인 공유/복사 action입니다.
class _ParticipantShareSheetState extends State<ParticipantShareSheet> {
  _ParticipantShareAction? _busyAction;

  /// 참여자 공유 sheet UI를 빌드합니다.
  /// QR preview, 참여자 링크, 외부 공유/링크 복사 action을 고정된 밀도로 표시합니다.
  /// Parameters:
  /// - [context]: Flutter build context입니다.
  /// Returns:
  /// - [result]: modal sheet widget tree입니다.
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
        decoration: const BoxDecoration(
          color: AdminColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AdminColors.line,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    '참여자 공유',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                ),
                SizedBox.square(
                  dimension: 40,
                  child: IconButton(
                    tooltip: '닫기',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Container(
              width: 226,
              height: 226,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AdminColors.line),
                borderRadius: BorderRadius.circular(18),
              ),
              child: QrImageView(
                data: widget.links.participantQrPayload,
                version: QrVersions.auto,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AdminColors.page,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdminColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    '참여자 링크',
                    style: TextStyle(
                      color: AdminColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    widget.links.participantUrl,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _ShareActionButton(
              label: '외부로 공유하기',
              icon: Icons.ios_share,
              onPressed: _busyAction == null
                  ? () => _runAction(
                      _ParticipantShareAction.externalShare,
                      widget.onExternalShare,
                    )
                  : null,
              isBusy: _busyAction == _ParticipantShareAction.externalShare,
            ),
            const SizedBox(height: 10),
            _ShareActionButton(
              label: '링크 복사',
              icon: Icons.copy_rounded,
              onPressed: _busyAction == null
                  ? () => _runAction(
                      _ParticipantShareAction.copyLink,
                      widget.onCopyLink,
                    )
                  : null,
              isBusy: _busyAction == _ParticipantShareAction.copyLink,
              secondary: true,
            ),
          ],
        ),
      ),
    );
  }

  /// action button busy 상태를 적용하고 callback을 실행합니다.
  /// Parent가 sheet를 닫는 동안 dispose될 수 있으므로 mounted 상태를 확인합니다.
  /// Parameters:
  /// - [action]: 실행 중으로 표시할 action 종류입니다.
  /// - [callback]: parent가 제공한 비동기 action입니다.
  /// Returns:
  /// - [completion]: action 완료를 의미합니다.
  Future<void> _runAction(
    _ParticipantShareAction action,
    Future<void> Function() callback,
  ) async {
    setState(() => _busyAction = action);
    try {
      await callback();
    } finally {
      if (mounted) {
        setState(() => _busyAction = null);
      }
    }
  }
}

/// 참여자 공유 sheet의 고정 높이 action button입니다.
/// fields:
/// - [label]: button label입니다.
/// - [icon]: button leading icon입니다.
/// - [onPressed]: press callback입니다.
/// - [isBusy]: loading indicator 표시 여부입니다.
/// - [secondary]: 보조 button 스타일 사용 여부입니다.
class _ShareActionButton extends StatelessWidget {
  /// 공유 sheet action button을 생성합니다.
  /// Parameters:
  /// - [label]: button label입니다.
  /// - [icon]: button icon입니다.
  /// - [onPressed]: press callback입니다.
  /// - [isBusy]: busy 상태입니다.
  /// - [secondary]: 보조 스타일 여부입니다.
  /// Returns:
  /// - [instance]: action button widget 인스턴스입니다.
  const _ShareActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isBusy,
    this.secondary = false,
  });

  /// button에 표시할 command label입니다.
  final String label;

  /// button leading icon입니다.
  final IconData icon;

  /// button 활성 상태에서 호출할 callback입니다.
  final VoidCallback? onPressed;

  /// 진행 중 indicator 표시 여부입니다.
  final bool isBusy;

  /// 보조 action 스타일을 사용할지 결정합니다.
  final bool secondary;

  /// 고정 높이의 icon+text button을 빌드합니다.
  /// Parameters:
  /// - [context]: Flutter build context입니다.
  /// Returns:
  /// - [result]: button widget tree입니다.
  @override
  Widget build(BuildContext context) {
    final child = isBusy
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon, size: 20);

    final labelWidget = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (secondary) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: child,
          label: labelWidget,
          style: OutlinedButton.styleFrom(
            foregroundColor: AdminColors.black,
            side: const BorderSide(color: AdminColors.line),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: child,
        label: labelWidget,
        style: FilledButton.styleFrom(
          backgroundColor: AdminColors.black,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AdminColors.disabled,
          disabledForegroundColor: AdminColors.muted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
