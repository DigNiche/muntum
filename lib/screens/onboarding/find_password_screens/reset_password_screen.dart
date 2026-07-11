import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/onboarding/find_password_screens/reset_complete_screen.dart';
import 'package:muntum/screens/onboarding/components/text_field_widget.dart';
import 'package:muntum/services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String resetToken;

  const ResetPasswordScreen({super.key, required this.resetToken});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _controller1 = TextEditingController();
  final TextEditingController _controller2 = TextEditingController();
  final FocusNode _focusNode1 = FocusNode();
  final FocusNode _focusNode2 = FocusNode();
  bool _isError1 = false;
  bool _isError2 = false;
  bool _obsecureText1 = false;
  bool _obsecureText2 = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _focusNode1.addListener(() {
      setState(() {});
    });
    _controller1.addListener(() {
      setState(() {
        _isError1 = false;
      });
    });
    _focusNode2.addListener(() {
      setState(() {});
    });
    _controller2.addListener(() {
      setState(() {
        _isError2 = false;
      });
    });
  }

  @override
  void dispose() {
    _controller1.dispose();
    _focusNode1.dispose();
    _controller2.dispose();
    _focusNode2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.backgroundDark,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 50.h),
            AppBarWidget(
              centerType: AppBarCenterType.none,
              leadingIcon: 'arrow_left.svg',
              leadingColor: AppColors.gray200,
              onLeadingTap: () {
                Navigator.pop(context);
              },
            ),
            SizedBox(height: 32.h),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    children: [
                      Align(
                        alignment: AlignmentGeometry.centerLeft,
                        child: Text(
                          "비밀번호 재설정",
                          style: AppTypography.display.copyWith(
                            color: AppColors.gray200,
                          ),
                        ),
                      ),
                      SizedBox(height: 30.h),
                      TextFieldWidget(
                        hintText: '새로운 비밀번호를 입력해 주세요.',
                        controller: _controller1,
                        obscureText: _obsecureText1,
                        isError: _isError1,
                        focusNode: _focusNode1,
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              _obsecureText1 = !_obsecureText1;
                            });
                          },
                          child: SvgPicture.asset(
                            !_obsecureText1
                                ? 'assets/icons/visibility.svg'
                                : 'assets/icons/visibility-false.svg',
                            width: 20.w,
                            color: _isError1
                                ? AppColors.gray700
                                : !_obsecureText1 && !_isError1
                                ? AppColors.primary400
                                : AppColors.gray500,
                          ),
                        ),
                        errorText: '비밀번호가 조건에 맞지 않습니다.(8자 이상)',
                      ),
                      SizedBox(height: 12.h),
                      TextFieldWidget(
                        hintText: '새로운 비밀번호를 재입력해 주세요.',
                        controller: _controller2,
                        obscureText: _obsecureText2,
                        isError: _isError2,
                        focusNode: _focusNode2,
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              _obsecureText2 = !_obsecureText2;
                            });
                          },
                          child: SvgPicture.asset(
                            !_obsecureText2
                                ? 'assets/icons/visibility.svg'
                                : 'assets/icons/visibility-false.svg',
                            width: 20.w,
                            color: _isError2
                                ? AppColors.gray700
                                : !_obsecureText2 && !_isError2
                                ? AppColors.primary400
                                : AppColors.gray500,
                          ),
                        ),
                        errorText: '비밀번호가 일치하지 않습니다.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0.w),
              child: ButtonSolid(
                text: '다음으로',
                textColor: _controller1.text != ''
                    ? AppColors.gray900
                    : AppColors.gray700,
                boxColor: _controller1.text != ''
                    ? AppColors.primary400
                    : Color(0x1AF5F5F3),
                onTap: _resetPassword,
              ),
            ),
            SizedBox(height: 80.h),
          ],
        ),
      ),
    );
  }

  Future<void> _resetPassword() async {
    if (_isLoading) return;
    setState(() {
      _isError1 = false;
      _isError2 = false;
      _isLoading = true;
    });
    if (_controller1.text != _controller2.text) {
      setState(() {
        _isError2 = true;
        _isLoading = false;
      });
      return;
    }

    if (_controller1.text.length < 8) {
      setState(() {
        _isError1 = true;
        _isLoading = false;
      });
      return;
    }

    try {
      await AuthService().resetPassword(
        resetToken: widget.resetToken,
        newPassword: _controller1.text,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const PasswordResetCompleteScreen(),
        ),
        (Route<dynamic> route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isError1 = true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
