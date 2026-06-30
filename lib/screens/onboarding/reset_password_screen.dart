import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/mypage/profile_screen.dart';
import 'package:muntum/screens/onboarding/text_field_widget.dart';
import 'package:muntum/screens/onboarding/verification_code_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  TextEditingController _controller1 = TextEditingController();
  FocusNode _focusNode1 = FocusNode();
  bool _isError = false;
  bool _obsecureText1 = false;
  bool _obsecureText2 = false;

  @override
  void initState() {
    super.initState();
    _focusNode1.addListener(() {
      setState(() {});
    });
    _controller1.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller1.dispose();
    _focusNode1.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      isError: _isError,
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
                          color: _isError
                              ? AppColors.gray700
                              : _obsecureText1 &&
                                    _focusNode1.hasFocus &&
                                    !_isError
                              ? AppColors.primary400
                              : AppColors.gray500,
                        ),
                      ),
                      errorText: '비밀번호가 조건에 맞지 않습니다.',
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
              onTap: () {
                pushToScreen(context, VerificationCodeScreen());
              },
            ),
          ),
          SizedBox(height: 80.h),
        ],
      ),
    );
  }
}
