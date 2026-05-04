import 'package:flutter/material.dart';

/// 관리자 UI에서 공유하는 semantic color token 모음입니다.
/// View와 Theme가 같은 색상 기준을 사용해 운영 콘솔의 밀도와 대비를 유지합니다.
/// fields:
/// - [black]: 주요 텍스트와 활성 버튼에 쓰는 기본 검정색입니다.
/// - [surface]: card, top bar, 입력 영역의 surface 색상입니다.
/// - [page]: 관리자 화면 배경색입니다.
/// - [line]: 주요 경계선 색상입니다.
/// - [softLine]: 약한 경계선과 비활성 보조 배경색입니다.
/// - [muted]: 보조 아이콘과 약한 텍스트 색상입니다.
/// - [textMuted]: 라벨과 설명 텍스트 색상입니다.
/// - [badgeText]: badge 내부 텍스트 색상입니다.
/// - [disabled]: 비활성 버튼 배경색입니다.
/// - [yellow]: 브랜드 seed color입니다.
class AdminColors {
  /// 인스턴스 생성을 막는 private 생성자입니다.
  /// 색상 token은 static const로만 사용됩니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [instance]: 외부에서 만들 수 없는 token holder 인스턴스입니다.
  const AdminColors._();

  /// 주요 텍스트와 활성 primary action에 쓰는 검정색 token입니다.
  /// 버튼과 제목 대비 기준으로 사용됩니다.
  static const black = Color(0xFF000000);

  /// 카드, app bar, 입력 패널 같은 surface 색상 token입니다.
  /// View 전반의 운영 콘솔 표면 색상과 동기화됩니다.
  static const surface = Color(0xFFFFFFFF);

  /// 화면 기본 배경 색상 token입니다.
  /// [AdminMobileShell]과 scaffold 배경의 기준입니다.
  static const page = Color(0xFFF8F9FA);

  /// 주요 border 색상 token입니다.
  /// 카드와 입력 영역 경계에 사용됩니다.
  static const line = Color(0xFFE5E7EB);

  /// 약한 border 또는 비활성 보조 배경 token입니다.
  /// top/bottom bar 경계와 secondary disabled 상태에 사용됩니다.
  static const softLine = Color(0xFFF3F4F6);

  /// 보조 아이콘과 약한 텍스트에 쓰는 muted token입니다.
  /// 빈 상태, 날짜, icon helper에서 공유됩니다.
  static const muted = Color(0xFF99A1AF);

  /// label과 설명 텍스트에 쓰는 muted text token입니다.
  /// 입력 라벨과 operation 설명 문구의 기준입니다.
  static const textMuted = Color(0xFF6A7282);

  /// badge 내부 텍스트에 쓰는 색상 token입니다.
  /// vote card의 question count badge와 연결됩니다.
  static const badgeText = Color(0xFF4A5565);

  /// 비활성 primary action 배경에 쓰는 색상 token입니다.
  /// 제출 불가 상태가 명확히 보이도록 버튼에서 사용됩니다.
  static const disabled = Color(0xFFE5E7EB);

  /// 브랜드 seed color로 사용하는 노란색 token입니다.
  /// Material color scheme 생성 기준으로 쓰입니다.
  static const yellow = Color(0xFFFED318);
}

/// 관리자 앱 전체 ThemeData를 구성하는 theme factory입니다.
/// typography, color scheme, ripple, scaffold background를 중앙에서 관리합니다.
/// fields:
/// - [none]: 저장 필드가 없으며, 연결 관계는 생성/호출 위치에서 결정됩니다.
class AdminTheme {
  /// 인스턴스 생성을 막는 private 생성자입니다.
  /// theme factory는 static method로만 호출됩니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [instance]: 외부에서 만들 수 없는 theme holder 인스턴스입니다.
  const AdminTheme._();

  /// 앱 전체에서 사용할 [ThemeData]를 생성합니다.
  /// [AdminColors] token과 Noto Sans KR typography를 Material theme에 반영합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: MaterialApp.router에 주입할 관리자 theme입니다.
  static ThemeData data() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AdminColors.yellow,
        surface: AdminColors.surface,
      ),
      fontFamily: 'Noto Sans KR',
      scaffoldBackgroundColor: AdminColors.page,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AdminColors.black,
        displayColor: AdminColors.black,
        fontFamily: 'Noto Sans KR',
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}
