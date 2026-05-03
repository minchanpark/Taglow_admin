import '../model/qr_export_result.dart';

abstract class QrExportService {
  Future<QrExportResult> downloadParticipantQr({
    required String voteId,
    required String payload,
    int size = 1024,
  });
}
