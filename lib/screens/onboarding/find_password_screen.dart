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

class FindPasswordScreen extends StatefulWidget {
  const FindPasswordScreen({super.key});

  @override
  State<FindPasswordScreen> createState() => _FindPasswordScreenState();
}

class _FindPasswordScreenState extends State<FindPasswordScreen> {
  TextEditingController _controller = TextEditingController();
  FocusNode _focusNode = FocusNode();
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {});
    });
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
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
                        "비밀번호 찾기",
                        style: AppTypography.display.copyWith(
                          color: AppColors.gray200,
                        ),
                      ),
                    ),
                    SizedBox(height: 30.h),
                    TextFieldWidget(
                      hintText: '가입한 이메일 주소를 입력해주세요.',
                      controller: _controller,
                      obscureText: false,
                      isError: _isError,
                      focusNode: _focusNode,
                      suffixIcon: _focusNode.hasFocus && _controller.text != ''
                          ? GestureDetector(
                              onTap: () {
                                _controller.clear();
                              },
                              child: SvgPicture.asset(
                                'assets/icons/circle_close.svg',
                                width: 20.w,
                                color: AppColors.gray600,
                              ),
                            )
                          : null,
                      errorText: '가입되지 않은 이메일 입니다.',
                      keyboardType: TextInputType.emailAddress,
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
              textColor: _controller.text != ''
                  ? AppColors.gray900
                  : AppColors.gray700,
              boxColor: _controller.text != ''
                  ? AppColors.primary400
                  : Color(0x1AF5F5F3),
              onTap: () {
                if (_controller.text != '') {
                  pushToScreen(context, VerificationCodeScreen());
                }
              },
            ),
          ),
          SizedBox(height: 80.h),
        ],
      ),
    );
  }
}
