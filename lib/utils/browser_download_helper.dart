/// 브라우저 파일 다운로드 동작을 감싸는 utility 계약입니다.
/// QR export 같은 Service가 browser API를 직접 노출하지 않고 이 경계로 위임합니다.
/// fields:
/// - [none]: 저장 필드가 없으며, 연결 관계는 생성/호출 위치에서 결정됩니다.
abstract class BrowserDownloadHelper {
  /// byte 데이터를 파일로 다운로드합니다.
  /// QR PNG export나 향후 binary export service가 사용할 수 있습니다.
  /// Parameters:
  /// - [bytes]: 다운로드할 파일 byte 목록입니다.
  /// - [fileName]: 브라우저에 제안할 파일명입니다.
  /// - [mimeType]: 다운로드 MIME type입니다.
  /// Returns:
  /// - [completion]: 비동기 작업 완료를 의미하며 값은 반환하지 않습니다.
  Future<void> downloadBytes({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  });

  /// 문자열 데이터를 파일로 다운로드합니다.
  /// SVG QR fallback이나 텍스트 기반 diagnostic export에서 사용할 수 있습니다.
  /// Parameters:
  /// - [text]: 다운로드할 문자열 내용입니다.
  /// - [fileName]: 브라우저에 제안할 파일명입니다.
  /// - [mimeType]: 다운로드 MIME type입니다.
  /// Returns:
  /// - [completion]: 비동기 작업 완료를 의미하며 값은 반환하지 않습니다.
  Future<void> downloadText({
    required String text,
    required String fileName,
    required String mimeType,
  });
}
