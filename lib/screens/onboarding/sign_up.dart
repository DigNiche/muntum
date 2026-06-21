import 'package:flutter/material.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/spacing.dart';
import 'package:muntum/constants/typography.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _obsecureText1 = true;
  bool _obsecureText2 = true;

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool get _isEmailValid {
    final email = emailController.text.trim();
    final emailRegExp = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    return emailRegExp.hasMatch(email);
  }

  bool get _isPasswordValid {
    final password = passwordController.text;
    final passwordRegExp = RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#\$%^&*(),.?":{}|<>]).{8,}$',
    );
    return passwordRegExp.hasMatch(password);
  }

  bool get _isConfirmPasswordValid {
    return confirmPasswordController.text == passwordController.text &&
        confirmPasswordController.text.isNotEmpty;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passwordErrorText = _isPasswordValid ? ' ' : '비밀번호가 조건에 일치하지 않습니다.';
    final confirmPasswordErrorText = _isConfirmPasswordValid
        ? ' '
        : '비밀번호가 일치하지 않습니다.';
    final emailErrorText = _isEmailValid ? ' ' : '올바른 이메일 형식이 아닙니다.';

    return Scaffold(
      backgroundColor: AppColors.backgroundNormal,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.horizontalMargin,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),
                    Transform.translate(
                      offset: const Offset(-20, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.chevron_left, size: 36),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text('문틈에 오신 것을 환영합니다!', style: AppTypography.display),
                    const SizedBox(height: 16),
                    Text(
                      '문화, 전시, 예술 등 다양한 프로그램들.\n문틈과 함께 문화의 틈으로 초대합니다.',
                      style: AppTypography.body1,
                    ),
                    const SizedBox(height: 28),
                    Text('Email*'),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) {
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppRadius.radius_1,
                          ),
                          borderSide: BorderSide(
                            color: AppColors.black,
                            width: 2,
                          ),
                        ),
                        hintText: '이메일을 입력해 주세요',
                        prefixIcon: const Icon(Icons.mail_outline, size: 20),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppRadius.radius_1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      emailErrorText,
                      style: AppTypography.caption1.copyWith(
                        color: emailErrorText.trim().isEmpty
                            ? Colors.transparent
                            : AppColors.error,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('비밀번호*'),
                    TextField(
                      controller: passwordController,
                      obscureText: _obsecureText1,
                      onChanged: (_) {
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppRadius.radius_1,
                          ),
                          borderSide: BorderSide(
                            color: AppColors.black,
                            width: 2,
                          ),
                        ),
                        hintText: '영문, 숫자, 특수문자 포함 8자 이상',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              _obsecureText1 = !_obsecureText1;
                            });
                          },
                          child: Icon(
                            _obsecureText1
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppRadius.radius_1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      passwordErrorText,
                      style: AppTypography.caption1.copyWith(
                        color: passwordErrorText.trim().isEmpty
                            ? Colors.transparent
                            : AppColors.error,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('비밀번호 재입력*'),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: _obsecureText2,
                      onChanged: (_) {
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppRadius.radius_1,
                          ),
                          borderSide: BorderSide(
                            color: AppColors.black,
                            width: 2,
                          ),
                        ),
                        hintText: '비밀번호를 재입력해 주세요',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              _obsecureText2 = !_obsecureText2;
                            });
                          },
                          child: Icon(
                            _obsecureText2
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppRadius.radius_1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      confirmPasswordErrorText,
                      style: AppTypography.caption1.copyWith(
                        color: confirmPasswordErrorText.trim().isEmpty
                            ? Colors.transparent
                            : AppColors.error,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '회원가입 시 문틈의 정책 및 약관에 동의합니다.',
                textAlign: TextAlign.center,
                style: AppTypography.caption1.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    child: Text(
                      '서비스 이용약관',
                      style: AppTypography.caption1.copyWith(
                        decoration: TextDecoration.underline,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {
                      print('Tab');
                    },
                  ),
                  const SizedBox(width: 15),
                  GestureDetector(
                    child: Text(
                      '개인정보 처리방침',
                      style: AppTypography.caption1.copyWith(
                        decoration: TextDecoration.underline,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.radius_1),
                    ),
                  ),
                  onPressed:
                      _isEmailValid &&
                          _isPasswordValid &&
                          _isConfirmPasswordValid
                      ? () {}
                      : null,
                  child: Text(
                    '다음으로',
                    style: AppTypography.button.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
