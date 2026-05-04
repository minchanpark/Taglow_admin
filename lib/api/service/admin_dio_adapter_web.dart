import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

/// Flutter Web에서 Dio browser adapter의 credential 정책을 설정합니다.
/// Spring session/cookie 인증 흐름을 Gateway 경계 안에서 처리하게 합니다.
/// Parameters:
/// - [dio]: 설정 대상 Dio client입니다.
/// - [withCredentials]: browser 요청에 cookie credential을 포함할지 여부입니다.
/// Returns:
/// - [void]: 상태 변경이나 부수 효과만 수행하고 값을 반환하지 않습니다.
void configureAdminDioAdapter(Dio dio, {required bool withCredentials}) {
  dio.httpClientAdapter = BrowserHttpClientAdapter()
    ..withCredentials = withCredentials;
}
