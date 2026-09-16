import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/api/token_store.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/popup_widget.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/mypage/common/components/profile_menu_item.dart';
import 'package:muntum/screens/mypage/common/nickname_change_screen.dart';
import 'package:muntum/screens/mypage/common/password_change_screen.dart';
import 'package:muntum/screens/mypage/common/withdraw_screen.dart';
import 'package:muntum/screens/onboarding/initial_screen.dart';
import 'package:muntum/services/auth_service.dart';
import 'package:muntum/stores/program_scrap_store.dart';
import 'package:muntum/stores/user_preference_store.dart';

class MyInfoEditScreen extends StatefulWidget {
  const MyInfoEditScreen({super.key});

  @override
  State<MyInfoEditScreen> createState() => _MyInfoEditScreenState();
}

class _MyInfoEditScreenState extends State<MyInfoEditScreen> {
  late final Future<String?> _emailFuture;
  late final Future<String?> _authProviderFuture;

  @override
  void initState() {
    super.initState();
    _emailFuture = TokenStore.instance.readEmail();
    _authProviderFuture = TokenStore.instance.readAuthProvider();
  }

  Future<void> _goToInitial() async {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const InitialScreen()),
      (route) => false,
    );
  }

  Future<void> _openNicknameChange() async {
    await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => NickNameChangeScreen()),
    );
  }

  Future<void> _logout() async {
    await showPopupWidget(
      context: context,
      title: '로그아웃 하시겠어요?',
      description: '',
      text1: '취소',
      text2: '로그아웃하기',
      onText1Tap: () => Navigator.pop(context),
      onText2Tap: () async {
        Navigator.pop(context);
        try {
          await AuthService().logout();
        } catch (_) {
          // 서버 세션이 이미 만료되어도 기기에 남은 로그인 정보는 정리한다.
        }
        await TokenStore.instance.clear();
        ProgramScrapStore.instance.clear(notify: false);
        UserPreferenceStore.instance.clear();
        await _goToInitial();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          SizedBox(height: 50.h),
          AppBarWidget(
            centerType: AppBarCenterType.text,
            leadingIcon: 'arrow_left.svg',
            center: '내 정보 수정',
            onLeadingTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 24.h),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.lineStrong,
                        width: 1.w,
                      ),
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.radius_10,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '가입한 이메일',
                          style: AppTypography.caption1.copyWith(
                            color: AppColors.gray600,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        FutureBuilder<String?>(
                          future: _emailFuture,
                          builder: (context, snapshot) => Text(
                            snapshot.data ?? '로그인 정보 없음',
                            style: AppTypography.button2.copyWith(
                              color: AppColors.gray900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  ProfileMenuItem(text: '프로필 수정', onTap: _openNicknameChange),
                  FutureBuilder<String?>(
                    future: _authProviderFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done ||
                          snapshot.data == 'APPLE') {
                        return const SizedBox.shrink();
                      }
                      return ProfileMenuItem(
                        text: '비밀번호 변경',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PasswordChangeScreen(),
                          ),
                        ),
                      );
                    },
                  ),
                  ProfileMenuItem(text: '로그아웃', onTap: _logout),
                  ProfileMenuItem(
                    text: '회원 탈퇴',
                    showDivider: false,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WithdrawScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
