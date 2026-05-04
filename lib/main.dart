import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// Taglow admin Flutter Web 앱의 진입점입니다.
/// Riverpod [ProviderScope]를 앱 최상단에 두어 route, controller, service provider를 사용할 수 있게 합니다.
/// Parameters:
/// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
/// Returns:
/// - [void]: 상태 변경이나 부수 효과만 수행하고 값을 반환하지 않습니다.
void main() {
  runApp(const ProviderScope(child: TaglowAdminApp()));
}
