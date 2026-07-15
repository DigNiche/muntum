import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/components/label.dart';
import 'package:muntum/components/page_header.dart';
import 'package:muntum/components/popup_widget.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/api/token_store.dart';
import 'package:muntum/screens/mypage/account_mange_screen.dart';
import 'package:muntum/screens/mypage/announcement_screen.dart';
import 'package:muntum/screens/mypage/components/profile_menu_item.dart';
import 'package:muntum/screens/mypage/keyword_change_screen.dart';
import 'package:muntum/screens/mypage/manager/announcement_manage_screen.dart';
import 'package:muntum/screens/mypage/manager/program_manage_screen.dart';
import 'package:muntum/screens/mypage/manager/program_report_manage_screen.dart';
import 'package:muntum/screens/mypage/manager/user_manage_screen.dart';
import 'package:muntum/screens/mypage/nickname_change_screen.dart';
import 'package:muntum/screens/mypage/reportlist_screen.dart';
import 'package:muntum/screens/mypage/report_submit_screen.dart';
import 'package:muntum/screens/mypage/settings_screen.dart';
import 'package:muntum/screens/mypage/components/stat_card_widget.dart';
import 'package:muntum/screens/mypage/terms_screen.dart';
import 'package:muntum/screens/mypage/version_info_screen.dart';
import 'package:muntum/screens/onboarding/login_screen.dart';
import 'package:muntum/services/suggestion_service.dart';
import 'package:muntum/stores/auth_state.dart';
import 'package:muntum/services/taste_service.dart';
import 'package:muntum/stores/user_preference_store.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<String?> _nicknameFuture;
  late Future<int> _keywordCountFuture;
  late Future<int> _reportCountFuture;
  late Future<bool> _isLoggedInFuture;
  bool _profileDataLoaded = false;

  @override
  void initState() {
    super.initState();
    UserPreferenceStore.instance.addListener(_reloadProfile);
    _isLoggedInFuture = _loadIsLoggedIn();
    _nicknameFuture = Future<String?>.value();
    _keywordCountFuture = Future<int>.value(0);
    _reportCountFuture = Future<int>.value(0);
  }

  @override
  void dispose() {
    UserPreferenceStore.instance.removeListener(_reloadProfile);
    super.dispose();
  }

  Future<String?> _loadNickname() async {
    return TokenStore.instance.readNickname();
  }

  Future<int> _loadKeywordCount() async {
    final result = await TasteService().fetchMyKeywords();
    UserPreferenceStore.instance.updateKeywords(
      result.selectedKeywords.map((keyword) => keyword.name),
    );
    return result.selectedKeywords.length;
  }

  Future<int> _loadReportCount() async {
    final result = await SuggestionService().fetchMySuggestions(size: 1);
    return result.totalElements == 0
        ? result.content.length
        : result.totalElements;
  }

  void _reloadProfile() {
    setState(() {
      _profileDataLoaded = false;
      _isLoggedInFuture = _loadIsLoggedIn();
    });
  }

  void _loadAuthenticatedProfileData() {
    _profileDataLoaded = true;
    _nicknameFuture = _loadNickname();
    _keywordCountFuture = _loadKeywordCount();
    _reportCountFuture = _loadReportCount();
  }

  Future<void> _handleNicknameEdit() async {
    final nickname = await _loadNickname();
    if (nickname == null || nickname.isEmpty) {
      if (!mounted) return;
      await showPopupWidget(
        context: context,
        title: '로그인이 필요해요',
        description: '닉네임을 변경하려면 먼저 로그인해주세요.',
        text1: '닫기',
        text2: '로그인하기',
        onText1Tap: () => Navigator.pop(context),
        onText2Tap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginScreen(showBackButton: true),
            ),
          );
        },
      );
      return;
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NickNameChangeScreen()),
    );
    _reloadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedInFuture,
      builder: (context, snapshot) {
        final isLoggedIn = snapshot.data ?? false;
        if (snapshot.connectionState == ConnectionState.done &&
            isLoggedIn &&
            !_profileDataLoaded) {
          _loadAuthenticatedProfileData();
        }
        return ColoredBox(
          color: AppColors.white,
          child: Column(
            children: [
              SizedBox(height: 50.h),
              PageHeader(
                firstText: '프로필',
                icon: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsScreen()),
                    );
                  },
                  child: SvgPicture.asset(
                    'assets/icons/setting.svg',
                    width: 24.w,
                    colorFilter: const ColorFilter.mode(
                      AppColors.gray900,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                firstTextColor: AppColors.gray900,
                showIndicator: false,
              ),
              if (!isLoggedIn)
                const Expanded(child: _GuestProfileContent())
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Profile
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 24.h,
                          ),
                          child: Column(
                            spacing: 16.h,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SvgPicture.asset(
                                    'assets/profile_image.svg',
                                    width: 56.r,
                                    height: 56.r,
                                  ),
                                  SizedBox(width: 16.w),
                                  Expanded(
                                    child: FutureBuilder<String?>(
                                      future: _nicknameFuture,
                                      builder: (context, snapshot) {
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                snapshot.data ?? "문화발굴단",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTypography.title4,
                                              ),
                                            ),
                                            if (AuthState.instance.isAdmin)
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  left: 6.w,
                                                ),
                                                child: const Label(
                                                  labelType: LabelType.admin,
                                                  text: '관리자',
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _handleNicknameEdit,
                                    child: SvgPicture.asset(
                                      'assets/icons/edit.svg',
                                      width: 18.w,
                                      colorFilter: const ColorFilter.mode(
                                        AppColors.gray400,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                ],
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: Color(0xfff8f8f8),
                                  borderRadius: BorderRadius.circular(
                                    AppBorderRadius.radius_10,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    StatCard(
                                      title: '키워드',
                                      number: '',
                                      numberWidget: FutureBuilder<int>(
                                        future: _keywordCountFuture,
                                        builder: (context, snapshot) {
                                          return Text(
                                            '${snapshot.data ?? 0}',
                                            style: AppTypography.headline1,
                                          );
                                        },
                                      ),
                                      onTap: () async {
                                        await pushToScreen(
                                          context,
                                          KeywordChangeScreen(),
                                        );
                                        if (mounted) _reloadProfile();
                                      },
                                    ),
                                    Container(
                                      width: 2.w,
                                      color: AppColors.gray200,
                                      height: 30.h,
                                    ),
                                    StatCard(
                                      title: '제보내역',
                                      number: '',
                                      numberWidget: FutureBuilder<int>(
                                        future: _reportCountFuture,
                                        builder: (context, snapshot) {
                                          return Text(
                                            '${snapshot.data ?? 0}',
                                            style: AppTypography.headline1,
                                          );
                                        },
                                      ),
                                      onTap: () async {
                                        await pushToScreen(
                                          context,
                                          ReportListScreen(),
                                        );
                                        if (mounted) _reloadProfile();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 8.h,
                          color: AppColors.lineAlternative,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 4.h,
                          ),
                          child: Column(
                            children: [
                              ProfileMenuItem(
                                text: '제보하기',
                                onTap: () async {
                                  await pushToScreen(
                                    context,
                                    ReportSubmitScreen(),
                                  );
                                  if (mounted) _reloadProfile();
                                },
                              ),
                              ProfileMenuItem(
                                text: '계정관리',
                                onTap: () {
                                  pushToScreen(context, AccountMangeScreen());
                                },
                              ),
                              ProfileMenuItem(
                                text: '공지사항',
                                onTap: () {
                                  pushToScreen(
                                    context,
                                    const AnnouncementScreen(),
                                  );
                                },
                              ),
                              ProfileMenuItem(
                                text: '이용약관',
                                onTap: () {
                                  pushToScreen(context, const TermsScreen());
                                },
                              ),
                              ProfileMenuItem(
                                text: '버전정보',
                                onTap: () {
                                  pushToScreen(
                                    context,
                                    const VersionInfoScreen(),
                                  );
                                },
                              ),
                              if (AuthState.instance.isAdmin)
                                const _AdminMenuSection(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GuestProfileContent extends StatelessWidget {
  const _GuestProfileContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/bottom_sheet/login_light.svg',
              width: 140.w,
              height: 140.w,
            ),
            SizedBox(height: 32.h),
            Text(
              '로그인 후 이용할 수 있어요.',
              textAlign: TextAlign.center,
              style: AppTypography.title4.copyWith(color: AppColors.gray900),
            ),
            SizedBox(height: 8.h),
            Text(
              '내 정보를 관리하고 설정하려면\n로그인이 필요해요!',
              textAlign: TextAlign.center,
              style: AppTypography.body2.copyWith(color: AppColors.gray500),
            ),
            SizedBox(height: 36.h),
            IntrinsicWidth(
              child: ButtonSolid(
                text: '로그인하기',
                textColor: AppColors.white,
                boxColor: AppColors.black,
                padding: EdgeInsets.fromLTRB(20.w, 11.h, 20.w, 10.h),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const LoginScreen(showBackButton: true),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<T?> pushToScreen<T>(BuildContext context, Widget screen) {
  return Navigator.push<T>(
    context,
    MaterialPageRoute(builder: (context) => screen),
  );
}

class _AdminMenuSection extends StatelessWidget {
  const _AdminMenuSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '관리자 메뉴',
            style: AppTypography.headline2.copyWith(color: AppColors.gray500),
          ),
          SizedBox(height: 8.h),
          ProfileMenuItem(
            onTap: () {
              pushToScreen(context, ProgramManageScreen());
            },
            text: '프로그램 관리',
          ),
          ProfileMenuItem(
            onTap: () {
              pushToScreen(context, ProgramReportManageScreen());
            },
            text: '프로그램 제보 관리',
          ),
          ProfileMenuItem(
            onTap: () {
              pushToScreen(context, AnnouncementManageScreen());
            },
            text: '공지사항 관리',
          ),
          ProfileMenuItem(
            onTap: () {
              pushToScreen(context, UserManageScreen());
            },
            text: '사용자 관리',
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}

Future<bool> _loadIsLoggedIn() async {
  final accessToken = TokenStore.instance.accessToken;
  if (accessToken != null && accessToken.isNotEmpty) return true;
  final refreshToken = await TokenStore.instance.readRefreshToken();
  return refreshToken != null && refreshToken.isNotEmpty;
}
