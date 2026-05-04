import 'package:flutter/services.dart';

import 'clipboard_helper.dart';

/// Flutter 플랫폼 클립보드를 사용하는 [ClipboardHelper] 구현입니다.
/// Controller는 이 helper 계약만 호출하므로 View가 직접 플랫폼 채널을 다루지 않습니다.
/// fields:
/// - [none]: 저장 필드가 없으며, 호출 시 전달된 문자열만 클립보드에 복사합니다.
class FlutterClipboardHelper implements ClipboardHelper {
  /// Flutter 클립보드 helper를 생성합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [instance]: 시스템 클립보드 복사 helper 인스턴스입니다.
  const FlutterClipboardHelper();

  /// 문자열을 시스템 클립보드에 복사합니다.
  /// Flutter [Clipboard] API를 사용해 web/mobile/desktop 플랫폼 차이를 숨깁니다.
  /// Parameters:
  /// - [value]: 복사할 문자열입니다.
  /// Returns:
  /// - [completion]: 비동기 복사 작업 완료를 의미합니다.
  @override
  Future<void> copyText(String value) {
    return Clipboard.setData(ClipboardData(text: value));
  }
}
