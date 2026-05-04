import '../model/qr_export_result.dart';

/// 참여자 QR 이미지를 렌더링하고 다운로드하는 service 계약입니다.
/// QR payload는 공개 participant URL만 받아 browser/download 세부 처리를 Controller 밖에 둡니다.
/// fields:
/// - [none]: 저장 필드가 없으며, 연결 관계는 생성/호출 위치에서 결정됩니다.
abstract class QrExportService {
  /// 참여자 QR 코드를 다운로드하고 export 결과를 반환합니다.
  /// 파일명과 format 정책은 구현체가 관리하며 저장 실패는 저장된 vote/question 상태에 영향을 주지 않습니다.
  /// Parameters:
  /// - [voteId]: QR 파일명과 운영 링크 연결에 사용할 vote 식별자입니다.
  /// - [payload]: QR에 넣을 공개 participant URL입니다.
  /// - [size]: 생성할 QR 이미지 크기입니다.
  /// Returns:
  /// - [result]: 다운로드된 QR 파일 결과입니다.
  Future<QrExportResult> downloadParticipantQr({
    required String voteId,
    required String payload,
    int size = 1024,
  });
}
