import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/popup_widget.dart';
import 'package:muntum/api/token_store.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/mypage/components/profile_menu_item.dart';
import 'package:muntum/screens/mypage/password_change_screen.dart';
import 'package:muntum/screens/mypage/withdraw_screen.dart';
import 'package:muntum/screens/onboarding/login_screen.dart';
import 'package:muntum/services/auth_service.dart';
import 'package:muntum/stores/program_scrap_store.dart';
import 'package:muntum/stores/user_preference_store.dart';

class AccountMangeScreen extends StatefulWidget {
  const AccountMangeScreen({super.key});

  @override
  State<AccountMangeScreen> createState() => _AccountMangeScreenState();
}

class _AccountMangeScreenState extends State<AccountMangeScreen> {
  late Future<String?> _emailFuture;

  @override
  void initState() {
    super.initState();
    _emailFuture = _loadEmail();
  }

  Future<String?> _loadEmail() async {
    return TokenStore.instance.readEmail();
  }

  Future<void> _goToLogin() async {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
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
            leadingIcon: "arrow_left.svg",
            center: "계정관리",
            onLeadingTap: () {
              Navigator.pop(context);
            },
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    border: BoxBorder.all(
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
                        "가입한 이메일",
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.gray600,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      FutureBuilder<String?>(
                        future: _emailFuture,
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data ?? '로그인 정보 없음',
                            style: AppTypography.button2.copyWith(
                              color: AppColors.gray900,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                ProfileMenuItem(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PasswordChangeScreen(),
                      ),
                    );
                  },
                  text: '비밀번호 변경',
                ),
                ProfileMenuItem(
                  onTap: () {
                    showPopupWidget(
                      context: context,
                      title: '로그아웃 하시겠어요?',
                      description: '',
                      text1: '취소',
                      text2: '로그아웃하기',
                      onText1Tap: () {
                        Navigator.pop(context);
                      },
                      onText2Tap: () async {
                        Navigator.pop(context);
                        try {
                          await AuthService().logout();
                        } catch (_) {
                          // 서버 토큰 상태가 이미 만료/삭제되어도 로컬 세션은 정리한다.
                        }
                        await TokenStore.instance.clear();
                        ProgramScrapStore.instance.clear(notify: false);
                        UserPreferenceStore.instance.clear();
                        await _goToLogin();
                      },
                    );
                  },
                  text: '로그아웃',
                ),
                ProfileMenuItem(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WithdrawPasswordScreen(),
                      ),
                    );
                  },
                  text: '회원 탈퇴',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
