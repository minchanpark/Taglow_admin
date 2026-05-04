import 'package:dio/dio.dart';

/// non-web platform에서 Dio adapter 설정을 맞추는 stub 함수입니다.
/// conditional import를 통해 web 구현과 같은 Service/Gateway API를 유지합니다.
/// Parameters:
/// - [dio]: 설정 대상 Dio client입니다.
/// - [withCredentials]: web 구현에서만 의미가 있는 credential 전송 여부입니다.
/// Returns:
/// - [void]: 상태 변경이나 부수 효과만 수행하고 값을 반환하지 않습니다.
void configureAdminDioAdapter(Dio dio, {required bool withCredentials}) {}
