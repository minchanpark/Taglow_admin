import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/admin_theme.dart';

/// 모바일 폭의 관리자 화면을 desktop web 중앙에 고정하는 공통 shell입니다.
/// 각 View는 이 shell 안에 screen content를 넣어 tablet-safe 폭과 배경을 공유합니다.
/// fields:
/// - [child]: shell 안에 렌더링할 화면 content입니다.
/// - [backgroundColor]: 화면 내부 배경색이며 기본값은 [AdminColors.page]입니다.
class AdminMobileShell extends StatelessWidget {
  /// 공통 모바일 shell을 생성합니다.
  /// Login, Vote, Question 화면이 같은 최대 폭과 shadow 스타일을 재사용합니다.
  /// Parameters:
  /// - [child]: 표시할 화면 widget입니다.
  /// - [backgroundColor]: 내부 화면 배경색입니다.
  /// - [key]: Flutter widget 식별 key입니다.
  /// Returns:
  /// - [instance]: 관리자 모바일 shell widget 인스턴스입니다.
  const AdminMobileShell({
    required this.child,
    this.backgroundColor = AdminColors.page,
    super.key,
  });

  /// shell 내부에 배치할 실제 화면 content입니다.
  /// 각 View의 Column/ListView 등 page layout이 이 슬롯에 들어갑니다.
  final Widget child;

  /// shell 내부 화면의 배경색입니다.
  /// 로그인 화면처럼 흰 배경이 필요한 경우 View에서 덮어씁니다.
  final Color backgroundColor;

  /// 공통 desktop-centered mobile frame을 빌드합니다.
  /// SafeArea는 화면 content 쪽 lifecycle과 layout을 그대로 보존합니다.
  /// Parameters:
  /// - [context]: Flutter build context입니다.
  /// Returns:
  /// - [result]: 관리자 화면 shell widget tree입니다.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 393),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 60,
                  offset: Offset(0, 20),
                ),
              ],
            ),
            child: SafeArea(top: false, bottom: false, child: child),
          ),
        ),
      ),
    );
  }
}

/// 관리자 화면 상단 제목 bar 공통 widget입니다.
/// detail/create 화면에서 뒤로가기와 trailing action을 일정한 위치에 제공합니다.
/// fields:
/// - [title]: 중앙에 표시할 화면 제목입니다.
/// - [onBack]: 왼쪽 back button을 눌렀을 때 실행할 callback입니다.
/// - [trailing]: 오른쪽 action 영역에 표시할 widget입니다.
class AdminTopBar extends StatelessWidget {
  /// 상단 bar를 생성합니다.
  /// View는 title과 navigation callback만 주입하고 styling은 shared widget이 담당합니다.
  /// Parameters:
  /// - [title]: 화면 제목입니다.
  /// - [onBack]: 뒤로가기 callback입니다.
  /// - [trailing]: 오른쪽 action widget입니다.
  /// - [key]: Flutter widget 식별 key입니다.
  /// Returns:
  /// - [instance]: 관리자 top bar widget 인스턴스입니다.
  const AdminTopBar({
    required this.title,
    this.onBack,
    this.trailing,
    super.key,
  });

  /// top bar 중앙에 표시할 제목입니다.
  /// 긴 vote 이름은 build에서 ellipsis로 안전하게 처리됩니다.
  final String title;

  /// 뒤로가기 button callback입니다.
  /// null이면 icon button이 disabled 상태로 렌더링됩니다.
  final VoidCallback? onBack;

  /// 오른쪽 action 슬롯입니다.
  /// null이면 제목 정렬을 유지하기 위한 고정 크기 placeholder가 들어갑니다.
  final Widget? trailing;

  /// top bar layout을 빌드합니다.
  /// 왼쪽 back button, 중앙 title, 오른쪽 trailing 슬롯의 폭 균형을 맞춥니다.
  /// Parameters:
  /// - [context]: Flutter build context입니다.
  /// Returns:
  /// - [result]: 상단 bar widget tree입니다.
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 48, bottom: 24),
      decoration: const BoxDecoration(
        color: AdminColors.surface,
        border: Border(bottom: BorderSide(color: AdminColors.softLine)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          _CircleIconButton(icon: Icons.chevron_left, onPressed: onBack),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AdminColors.textMuted,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.5,
              ),
            ),
          ),
          trailing ?? const SizedBox(width: 40, height: 40),
        ],
      ),
    );
  }
}

/// 화면 하단 primary action 영역 공통 widget입니다.
/// 저장, 로그인, 다음 단계 같은 주요 action들을 일정 높이와 padding 안에 배치합니다.
/// fields:
/// - [children]: 하단 bar에 배치할 action widget 목록입니다.
/// - [height]: bar 전체 높이입니다.
class AdminBottomBar extends StatelessWidget {
  /// 하단 action bar를 생성합니다.
  /// View는 버튼 구성을 children으로 넘기고 공통 surface 스타일을 재사용합니다.
  /// Parameters:
  /// - [children]: 배치할 하단 action widget들입니다.
  /// - [height]: bar 높이입니다.
  /// - [key]: Flutter widget 식별 key입니다.
  /// Returns:
  /// - [instance]: 관리자 bottom bar widget 인스턴스입니다.
  const AdminBottomBar({required this.children, this.height = 106, super.key});

  /// 하단 bar 안에 가로로 배치할 widget 목록입니다.
  /// 화면별 primary/secondary button 조합이 들어갑니다.
  final List<Widget> children;

  /// 하단 bar 높이입니다.
  /// 로그인/회원가입 화면처럼 보조 링크가 있는 경우 더 큰 값을 사용합니다.
  final double height;

  /// 고정 높이와 상단 border를 가진 action bar를 빌드합니다.
  /// children은 View가 제공한 순서대로 Row 안에 배치됩니다.
  /// Parameters:
  /// - [context]: Flutter build context입니다.
  /// Returns:
  /// - [result]: 하단 action bar widget tree입니다.
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: const BoxDecoration(
        color: AdminColors.surface,
        border: Border(top: BorderSide(color: AdminColors.softLine)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// 관리자 화면에서 사용하는 공통 primary button입니다.
/// enabled, busy, secondary 상태를 같은 시각 언어로 표현합니다.
/// fields:
/// - [label]: 버튼에 표시할 텍스트입니다.
/// - [onPressed]: 활성 상태에서 실행할 callback입니다.
/// - [enabled]: 외부 validation이 허용하는지 나타냅니다.
/// - [isBusy]: 제출/저장 진행 중인지 나타냅니다.
/// - [secondary]: secondary action 색상을 사용할지 결정합니다.
class AdminPrimaryButton extends StatelessWidget {
  /// primary button을 생성합니다.
  /// View는 action 가능 여부와 busy 상태만 넘기고 disabled 스타일은 widget이 계산합니다.
  /// Parameters:
  /// - [label]: 버튼 텍스트입니다.
  /// - [onPressed]: 클릭 callback입니다.
  /// - [enabled]: validation상 활성화 가능 여부입니다.
  /// - [isBusy]: 로딩 indicator 표시 여부입니다.
  /// - [secondary]: secondary action 스타일 사용 여부입니다.
  /// - [key]: Flutter widget 식별 key입니다.
  /// Returns:
  /// - [instance]: 관리자 primary button widget 인스턴스입니다.
  const AdminPrimaryButton({
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.isBusy = false,
    this.secondary = false,
    super.key,
  });

  /// 버튼에 표시할 command label입니다.
  /// 저장, 로그인, 다음 단계 같은 명확한 action 문구를 받습니다.
  final String label;

  /// 버튼이 활성일 때 실행할 callback입니다.
  /// null이면 disabled 상태로 렌더링됩니다.
  final VoidCallback? onPressed;

  /// validation이나 화면 상태가 action을 허용하는지 나타냅니다.
  /// [isBusy]와 [onPressed]까지 함께 고려해 실제 active 상태를 계산합니다.
  final bool enabled;

  /// 비동기 요청이 진행 중인지 나타냅니다.
  /// true이면 text 대신 작은 loading indicator를 표시합니다.
  final bool isBusy;

  /// secondary button 색상을 사용할지 결정합니다.
  /// question editor의 “다음 항목 추가” 같은 보조 action에 사용됩니다.
  final bool secondary;

  /// 버튼의 active/disabled/busy visual state를 빌드합니다.
  /// loading 중에는 action callback을 막고 indicator를 표시합니다.
  /// Parameters:
  /// - [context]: Flutter build context입니다.
  /// Returns:
  /// - [result]: primary button widget tree입니다.
  @override
  Widget build(BuildContext context) {
    final active = enabled && !isBusy && onPressed != null;
    final color = active
        ? AdminColors.black
        : secondary
        ? AdminColors.softLine
        : AdminColors.disabled;
    final textColor = active
        ? Colors.white
        : secondary
        ? AdminColors.muted
        : AdminColors.muted;

    return SizedBox(
      height: 58,
      width: double.infinity,
      child: FilledButton(
        onPressed: active ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color,
          foregroundColor: textColor,
          disabledForegroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            height: 1.5,
          ),
        ),
        child: isBusy
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }
}

/// 관리자 입력 form에서 사용하는 공통 text input widget입니다.
/// View가 controller와 label만 넘기면 underline style과 큰 입력 모드를 공유합니다.
/// fields:
/// - [label]: 입력 field 상단에 표시할 label입니다.
/// - [controller]: Flutter text 입력 상태를 보유하는 controller입니다.
/// - [hintText]: 비어 있을 때 표시할 placeholder입니다.
/// - [obscureText]: 비밀번호 입력처럼 텍스트를 숨길지 결정합니다.
/// - [keyboardType]: 입력에 사용할 keyboard type입니다.
/// - [onChanged]: 입력 변경 callback입니다.
/// - [large]: 큰 제목형 입력 스타일을 사용할지 결정합니다.
class AdminTextInput extends StatelessWidget {
  /// 공통 text input을 생성합니다.
  /// 화면별 Controller는 [onChanged]로 Riverpod Controller 상태를 갱신할 수 있습니다.
  /// Parameters:
  /// - [label]: 입력 label입니다.
  /// - [controller]: text editing controller입니다.
  /// - [hintText]: placeholder 문구입니다.
  /// - [obscureText]: 입력값 숨김 여부입니다.
  /// - [keyboardType]: keyboard type입니다.
  /// - [onChanged]: 값 변경 callback입니다.
  /// - [large]: 큰 입력 스타일 사용 여부입니다.
  /// - [key]: Flutter widget 식별 key입니다.
  /// Returns:
  /// - [instance]: 관리자 text input widget 인스턴스입니다.
  const AdminTextInput({
    required this.label,
    required this.controller,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.large = false,
    super.key,
  });

  /// field 위에 표시할 label입니다.
  /// 운영자가 입력 의미를 빠르게 스캔하도록 짧은 문구를 사용합니다.
  final String label;

  /// TextField의 입력 상태를 보유하는 controller입니다.
  /// Stateful View가 lifecycle에서 생성하고 dispose합니다.
  final TextEditingController controller;

  /// 비어 있는 입력에 표시할 hint 문구입니다.
  /// 입력 예시나 최소 조건을 안내합니다.
  final String? hintText;

  /// 입력 내용을 숨길지 결정합니다.
  /// password field에서 true로 사용됩니다.
  final bool obscureText;

  /// 플랫폼 keyboard type 설정입니다.
  /// URL이나 숫자 입력이 필요할 때 View에서 주입할 수 있습니다.
  final TextInputType? keyboardType;

  /// 입력값이 바뀔 때 호출할 callback입니다.
  /// Controller state update나 local submit 가능 여부 갱신에 사용됩니다.
  final ValueChanged<String>? onChanged;

  /// 큰 입력 typography를 사용할지 결정합니다.
  /// vote 제목과 question 제목 같은 핵심 입력에 사용됩니다.
  final bool large;

  /// label과 underline TextField를 세로로 배치합니다.
  /// text overflow와 입력 density는 공통 theme token에 맞춥니다.
  /// Parameters:
  /// - [context]: Flutter build context입니다.
  /// Returns:
  /// - [result]: text input widget tree입니다.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            color: AdminColors.textMuted,
            fontSize: large ? 12 : 13,
            fontWeight: FontWeight.w700,
            height: 1.5,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: TextStyle(
            color: AdminColors.black,
            fontSize: large ? 20 : 18,
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: const Color(0xFFD1D5DC),
              fontSize: large ? 20 : 18,
              fontWeight: FontWeight.w800,
            ),
            isDense: true,
            contentPadding: EdgeInsets.only(bottom: large ? 12 : 14),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AdminColors.line, width: 1.8),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AdminColors.black, width: 1.8),
            ),
            border: const UnderlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

/// 성공 또는 오류 메시지를 표시하는 공통 feedback widget입니다.
/// Controller state의 user-facing message를 View가 일관된 색상으로 렌더링합니다.
/// fields:
/// - [message]: 화면에 표시할 메시지입니다.
/// - [isError]: 오류 스타일을 사용할지 결정합니다.
class AdminMessage extends StatelessWidget {
  /// 오류 메시지 widget을 생성합니다.
  /// Controller가 전달한 validation/API 실패 문구를 표시할 때 사용합니다.
  /// Parameters:
  /// - [message]: 표시할 오류 메시지입니다.
  /// - [key]: Flutter widget 식별 key입니다.
  /// Returns:
  /// - [instance]: 오류 메시지 widget 인스턴스입니다.
  const AdminMessage.error(this.message, {super.key}) : isError = true;

  /// 성공 메시지 widget을 생성합니다.
  /// 가입 완료, 업로드 준비, 저장 완료 같은 positive feedback에 사용합니다.
  /// Parameters:
  /// - [message]: 표시할 성공 메시지입니다.
  /// - [key]: Flutter widget 식별 key입니다.
  /// Returns:
  /// - [instance]: 성공 메시지 widget 인스턴스입니다.
  const AdminMessage.success(this.message, {super.key}) : isError = false;

  /// 사용자에게 표시할 feedback 문구입니다.
  /// 민감한 서버 상세나 credential 정보가 들어가지 않아야 합니다.
  final String message;

  /// 오류 스타일 적용 여부입니다.
  /// true이면 red 계열, false이면 green 계열 surface를 사용합니다.
  final bool isError;

  /// feedback message box를 빌드합니다.
  /// 화면 폭을 채워 form과 list 사이에서 명확히 보이도록 합니다.
  /// Parameters:
  /// - [context]: Flutter build context입니다.
  /// Returns:
  /// - [result]: message widget tree입니다.
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFFF1F2) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isError ? const Color(0xFFBE123C) : const Color(0xFF166534),
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
      ),
    );
  }
}

/// Taglow 로고 asset을 표시하는 공통 widget입니다.
/// 인증 화면에서 브랜드 식별을 제공하고 asset 경로를 한 곳에 둡니다.
/// fields:
/// - [none]: 저장 필드가 없으며, 연결 관계는 생성/호출 위치에서 결정됩니다.
class TaglowLogo extends StatelessWidget {
  /// 로고 widget을 생성합니다.
  /// 인증 화면이 같은 SVG asset과 sizing을 재사용합니다.
  /// Parameters:
  /// - [key]: Flutter widget 식별 key입니다.
  /// Returns:
  /// - [instance]: Taglow 로고 widget 인스턴스입니다.
  const TaglowLogo({super.key});

  /// SVG 로고 asset을 지정 폭으로 빌드합니다.
  /// asset 경로는 shared widget에 고정되어 View 중복을 줄입니다.
  /// Parameters:
  /// - [context]: Flutter build context입니다.
  /// Returns:
  /// - [result]: SVG 로고 widget입니다.
  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/logo/taglow_logo.svg',
      width: 190,
      fit: BoxFit.contain,
    );
  }
}

/// 새 vote나 새 question을 추가하는 tile형 action widget입니다.
/// 목록과 grid 화면에서 empty/add action을 같은 시각 패턴으로 제공합니다.
/// fields:
/// - [label]: tile 하단에 표시할 action label입니다.
/// - [onTap]: tile을 눌렀을 때 실행할 callback입니다.
class AddTile extends StatelessWidget {
  /// add tile을 생성합니다.
  /// View는 navigation callback과 label만 주입하고 tile style을 재사용합니다.
  /// Parameters:
  /// - [label]: action label입니다.
  /// - [onTap]: tap callback입니다.
  /// - [key]: Flutter widget 식별 key입니다.
  /// Returns:
  /// - [instance]: add tile widget 인스턴스입니다.
  const AddTile({required this.label, required this.onTap, super.key});

  /// tile에 표시할 action label입니다.
  /// “새로운 투표 만들기”, “항목 추가”처럼 현재 화면 action을 나타냅니다.
  final String label;

  /// tile tap 시 실행할 callback입니다.
  /// 주로 go_router navigation action과 연결됩니다.
  final VoidCallback onTap;

  /// add icon과 label을 가진 tile을 빌드합니다.
  /// InkWell로 desktop/tablet click affordance를 제공합니다.
  /// Parameters:
  /// - [context]: Flutter build context입니다.
  /// Returns:
  /// - [result]: add tile widget tree입니다.
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AdminColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFD1D5DC),
            width: 1.8,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: AdminColors.muted),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  color: AdminColors.textMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 관리자 화면에 표시할 날짜 문구를 포맷합니다.
/// Vote list card가 nullable 서버 생성일을 안전한 fallback과 함께 표시합니다.
/// Parameters:
/// - [value]: 표시할 생성 시각입니다.
/// Returns:
/// - [result]: 한국어 생성일 표시 문자열입니다.
String formatAdminDate(DateTime? value) {
  if (value == null) return '생성일 정보 없음';
  final local = value.toLocal();
  return '생성일 ${local.year}.${local.month.toString().padLeft(2, '0')}.${local.day.toString().padLeft(2, '0')}';
}

/// 원형 icon button을 렌더링하는 private helper widget입니다.
/// [AdminTopBar]의 back button처럼 compact action에 사용됩니다.
/// fields:
/// - [icon]: 표시할 Material icon data입니다.
/// - [onPressed]: 버튼을 눌렀을 때 실행할 callback입니다.
class _CircleIconButton extends StatelessWidget {
  /// 원형 icon button helper를 생성합니다.
  /// callback이 null이면 IconButton의 disabled 상태를 그대로 사용합니다.
  /// Parameters:
  /// - [icon]: 표시할 icon입니다.
  /// - [onPressed]: press callback입니다.
  /// Returns:
  /// - [instance]: 원형 icon button widget 인스턴스입니다.
  const _CircleIconButton({required this.icon, this.onPressed});

  /// 버튼에 표시할 icon입니다.
  /// top bar back action은 chevron icon을 사용합니다.
  final IconData icon;

  /// 버튼 press callback입니다.
  /// null이면 disabled 상태가 됩니다.
  final VoidCallback? onPressed;

  /// 고정 크기 icon button을 빌드합니다.
  /// top bar layout shift가 없도록 width와 height를 고정합니다.
  /// Parameters:
  /// - [context]: Flutter build context입니다.
  /// Returns:
  /// - [result]: circle icon button widget tree입니다.
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: AdminColors.black,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
