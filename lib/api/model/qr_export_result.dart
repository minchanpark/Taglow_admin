/// QR 다운로드 결과가 어떤 파일 형식으로 만들어졌는지 나타냅니다.
/// QR export service와 Controller가 PNG 기본, SVG fallback 정책을 구분할 수 있습니다.
/// fields:
/// - [png]: 현장 포스터와 스탠바이미에 우선 사용하는 bitmap QR 형식입니다.
/// - [svg]: PNG export가 어렵거나 fallback이 필요할 때 사용할 vector 형식입니다.
enum QrExportFormat { png, svg }

/// 참여자 QR export 작업의 결과를 표현하는 domain model입니다.
/// QR service가 다운로드 완료 정보를 Controller와 View에 안전하게 전달할 때 사용합니다.
/// fields:
/// - [fileName]: 브라우저 다운로드에 사용된 QR 파일명입니다.
/// - [format]: 생성된 QR 파일 형식입니다.
/// - [byteLength]: 생성된 파일의 byte 크기이며 진단과 테스트에 사용됩니다.
class QrExportResult {
  /// QR export 결과 값을 생성합니다.
  /// Service 구현은 다운로드 부수 효과 후 이 값을 반환합니다.
  /// Parameters:
  /// - [fileName]: 다운로드 파일명입니다.
  /// - [format]: QR export 형식입니다.
  /// - [byteLength]: 생성된 파일 크기입니다.
  /// Returns:
  /// - [instance]: QR export 결과를 보관하는 새 인스턴스입니다.
  const QrExportResult({
    required this.fileName,
    required this.format,
    required this.byteLength,
  });

  /// 다운로드된 QR 파일명입니다.
  /// 기본 정책은 voteId를 포함한 participant QR 이름과 동기화됩니다.
  final String fileName;

  /// 실제 생성된 QR 파일 형식입니다.
  /// View나 테스트가 fallback 여부를 확인할 수 있습니다.
  final QrExportFormat format;

  /// 생성된 QR 파일의 byte 크기입니다.
  /// export 성공 여부와 진단 정보로 사용할 수 있습니다.
  final int byteLength;
}
