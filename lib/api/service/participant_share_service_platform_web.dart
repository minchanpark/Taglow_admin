import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'participant_share_service_base.dart';

/// Web 환경에서 사용할 참여자 공유 service를 생성합니다.
/// Parameters:
/// - [none]: 이 동작은 외부 입력 없이 현재 브라우저 navigator를 사용합니다.
/// Returns:
/// - [result]: Web Share API 기반 공유 service 구현입니다.
ParticipantShareService createPlatformParticipantShareService() {
  return const WebParticipantShareService();
}

/// 브라우저 Web Share API를 사용하는 참여자 링크 공유 service입니다.
/// Web Share API가 없거나 공유가 차단되면 Controller가 복사 fallback을 수행할 수 있게 예외를 던집니다.
/// fields:
/// - [none]: 저장 필드가 없으며 호출 시점의 browser navigator를 사용합니다.
class WebParticipantShareService implements ParticipantShareService {
  /// Web 참여자 공유 service를 생성합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [instance]: Web Share API service 인스턴스입니다.
  const WebParticipantShareService();

  /// Web Share API로 참여자 링크 공유 sheet를 엽니다.
  /// 사용자가 공유를 취소한 경우에는 링크 복사 fallback을 수행하지 않도록 예외를 구분합니다.
  /// Parameters:
  /// - [title]: 공유 sheet 제목입니다.
  /// - [text]: 공유 본문입니다.
  /// - [url]: 공유할 공개 참여자 URL입니다.
  /// Returns:
  /// - [completion]: 브라우저 공유 promise 완료를 의미합니다.
  @override
  Future<void> shareParticipantLink({
    required String title,
    required String text,
    required String url,
  }) async {
    final navigator = web.window.navigator;
    if (!navigator.has('share')) {
      throw const ParticipantShareException('외부 공유를 지원하지 않는 브라우저입니다.');
    }

    try {
      await navigator
          .share(web.ShareData(title: title, text: text, url: url))
          .toDart;
    } catch (error) {
      final name = _jsErrorName(error);
      if (name == 'AbortError') {
        throw const ParticipantShareException(
          '공유가 취소되었습니다.',
          shouldFallbackToCopy: false,
        );
      }
      throw const ParticipantShareException('외부 공유를 열지 못했습니다.');
    }
  }

  /// JS 예외 객체에서 name 속성을 안전하게 읽습니다.
  /// Parameters:
  /// - [error]: Web Share API promise가 전달한 오류 객체입니다.
  /// Returns:
  /// - [result]: JS 오류 name 값이며 없으면 null입니다.
  String? _jsErrorName(Object error) {
    final text = error.toString();
    if (text.contains('AbortError')) return 'AbortError';
    return null;
  }
}
