import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

void configureAdminDioAdapter(Dio dio, {required bool withCredentials}) {
  dio.httpClientAdapter = BrowserHttpClientAdapter()
    ..withCredentials = withCredentials;
}
