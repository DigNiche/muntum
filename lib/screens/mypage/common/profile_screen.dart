import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/api/token_store.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/components/label.dart';
import 'package:muntum/components/page_header.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/mypage/audience/keyword_change_screen.dart';
import 'package:muntum/screens/mypage/audience/report_list_screen.dart';
import 'package:muntum/screens/mypage/common/announcement_screen.dart';
import 'package:muntum/screens/mypage/common/components/profile_menu_item.dart';
import 'package:muntum/screens/mypage/manager/announcement_manage_screen.dart';
import 'package:muntum/screens/mypage/manager/curator_application_manage_screen.dart';
import 'package:muntum/screens/mypage/manager/program_manage_screen.dart';
import 'package:muntum/screens/mypage/manager/program_report_manage_screen.dart';
import 'package:muntum/screens/mypage/manager/user_manage_screen.dart';
import 'package:muntum/screens/mypage/common/my_info_edit_screen.dart';
import 'package:muntum/screens/mypage/common/settings_screen.dart';
import 'package:muntum/screens/mypage/common/terms_screen.dart';
import 'package:muntum/screens/mypage/common/version_info_screen.dart';
import 'package:muntum/screens/mypage/curator/curator_application_screen.dart';
import 'package:muntum/screens/onboarding/initial_screen.dart';
import 'package:muntum/services/taste_service.dart';
import 'package:muntum/stores/auth_state.dart';
import 'package:muntum/stores/user_preference_store.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<String?> _nicknameFuture;
  late Future<int> _keywordCountFuture;
  late Future<bool> _isLoggedInFuture;
  bool _profileDataLoaded = false;

  @override
  void initState() {
    super.initState();
    UserPreferenceStore.instance.addListener(_reloadProfile);
    _isLoggedInFuture = _loadIsLoggedIn();
    _nicknameFuture = Future<String?>.value();
    _keywordCountFuture = Future<int>.value(0);
  }

  @override
  void dispose() {
    UserPreferenceStore.instance.removeListener(_reloadProfile);
    super.dispose();
  }

  Future<String?> _loadNickname() => TokenStore.instance.readNickname();

  Future<int> _loadKeywordCount() async {
    final result = await TasteService().fetchMyKeywords();
    UserPreferenceStore.instance.updateKeywords(
      result.selectedKeywords.map((keyword) => keyword.name),
    );
    return result.selectedKeywords.length;
  }

  void _reloadProfile() {
    if (!mounted) return;
    setState(() {
      _profileDataLoaded = false;
      _isLoggedInFuture = _loadIsLoggedIn();
    });
  }

  void _loadAuthenticatedProfileData() {
    _profileDataLoaded = true;
    _nicknameFuture = _loadNickname();
    _keywordCountFuture = _loadKeywordCount();
  }

  Future<void> _openKeywordScreen() async {
    await pushToScreen(context, const KeywordChangeScreen());
    if (mounted) _reloadProfile();
  }

  Future<void> _openMyInfoScreen() async {
    await pushToScreen(context, const MyInfoEditScreen());
    if (mounted) _reloadProfile();
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
          color: AppColors.backgroundNormal,
          child: Column(
            children: [
              SizedBox(height: 50.h),
              PageHeader(
                title: Text(
                  '프로필',
                  style: AppTypography.title2.copyWith(
                    color: AppColors.gray900,
                  ),
                ),
                icon: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => pushToScreen(context, const SettingsScreen()),
                  child: Padding(
                    padding: EdgeInsets.all(4.r),
                    child: SvgPicture.asset(
                      'assets/icons/setting.svg',
                      width: 24.r,
                      height: 24.r,
                      colorFilter: const ColorFilter.mode(
                        AppColors.gray900,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
              if (!isLoggedIn)
                const Expanded(child: _GuestProfileContent())
              else
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20.w, 0.h, 20.w, 28.h),
                    child: Column(
                      children: [
                        _ProfileIdentity(nicknameFuture: _nicknameFuture),
                        SizedBox(height: 12.h),
                        _ProfileMenuCard(
                          children: [
                            ProfileMenuItem(
                              text: '내 취향 키워드',
                              showDivider: false,
                              onTap: _openKeywordScreen,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FutureBuilder<int>(
                                    future: _keywordCountFuture,
                                    builder: (context, snapshot) => Text(
                                      '${snapshot.data ?? 0}',
                                      style: AppTypography.button2.copyWith(
                                        color: AppColors.gray900,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  SvgPicture.asset(
                                    'assets/icons/arrow_right-small.svg',
                                    width: 20.r,
                                    height: 20.r,
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.gray400,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        _ProfileMenuCard(
                          children: [
                            ProfileMenuItem(
                              text: '내 정보 수정',
                              onTap: _openMyInfoScreen,
                            ),
                            ProfileMenuItem(
                              text: '제보하기',
                              onTap: () => pushToScreen(
                                context,
                                const ReportListScreen(),
                              ),
                            ),
                            ProfileMenuItem(
                              text: '공지사항',
                              onTap: () => pushToScreen(
                                context,
                                const AnnouncementScreen(),
                              ),
                            ),
                            ProfileMenuItem(
                              text: '이용약관',
                              onTap: () =>
                                  pushToScreen(context, const TermsScreen()),
                            ),
                            ProfileMenuItem(
                              text: '버전정보',
                              showDivider: false,
                              onTap: () => pushToScreen(
                                context,
                                const VersionInfoScreen(),
                              ),
                            ),
                          ],
                        ),

                        if (AuthState.instance.isAudience) ...[
                          SizedBox(height: 12.h),
                          _ProfileMenuCard(
                            children: [
                              ProfileMenuItem(
                                text: '큐레이터 지원/내역',
                                showDivider: false,
                                onTap: () => pushToScreen(
                                  context,
                                  const CuratorApplicationScreen(),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (AuthState.instance.isAdmin) ...[
                          SizedBox(height: 12.h),
                          const _AdminMenuSection(),
                        ],
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

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({required this.nicknameFuture});

  final Future<String?> nicknameFuture;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/profile_image.svg',
            width: 56.r,
            height: 56.r,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: FutureBuilder<String?>(
              future: nicknameFuture,
              builder: (context, snapshot) => Row(
                children: [
                  Flexible(
                    child: Text(
                      snapshot.data ?? '문화발굴단',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.title4.copyWith(
                        color: AppColors.gray900,
                      ),
                    ),
                  ),
                  if (AuthState.instance.isAdmin)
                    Padding(
                      padding: EdgeInsets.only(left: 6.w),
                      child: const Label(
                        labelType: LabelType.admin,
                        text: '관리자',
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

class _ProfileMenuCard extends StatelessWidget {
  const _ProfileMenuCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.radius_10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const InitialScreen(showBackButton: true),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminMenuSection extends StatelessWidget {
  const _AdminMenuSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileMenuCard(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 20.h, bottom: 10.h),
              child: Text(
                '관리자 메뉴',
                style: AppTypography.headline2.copyWith(
                  color: AppColors.gray500,
                ),
              ),
            ),
            ProfileMenuItem(
              text: '프로그램 관리',
              onTap: () => pushToScreen(context, ProgramManageScreen()),
            ),
            ProfileMenuItem(
              text: '프로그램 제보 관리',
              onTap: () => pushToScreen(context, ProgramReportManageScreen()),
            ),
            ProfileMenuItem(
              text: '공지사항 관리',
              onTap: () => pushToScreen(context, AnnouncementManageScreen()),
            ),
            ProfileMenuItem(
              text: '사용자 관리',
              showDivider: false,
              onTap: () => pushToScreen(context, UserManageScreen()),
            ),
            ProfileMenuItem(
              text: '큐레이터 승인 관리',
              showDivider: false,
              onTap: () =>
                  pushToScreen(context, CuratorApplicationManageScreen()),
            ),
          ],
        ),
      ],
    );
  }
}

Future<T?> pushToScreen<T>(BuildContext context, Widget screen) {
  return Navigator.push<T>(
    context,
    MaterialPageRoute(builder: (context) => screen),
  );
}

Future<bool> _loadIsLoggedIn() async {
  final accessToken = TokenStore.instance.accessToken;
  if (accessToken != null && accessToken.isNotEmpty) return true;
  final refreshToken = await TokenStore.instance.readRefreshToken();
  return refreshToken != null && refreshToken.isNotEmpty;
}
