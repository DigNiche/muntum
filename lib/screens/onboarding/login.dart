import 'package:flutter/material.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/spacing.dart';
import 'package:muntum/constants/typography.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obsecureText = true;

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 60),
              Transform.translate(
                offset: Offset(-20, 0),
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
              Text('안녕하세요!', style: AppTypography.display),
              SizedBox(height: 24),
              Text("Email*"),
              TextField(
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.radius_1),
                    borderSide: BorderSide(color: AppColors.black, width: 2),
                  ),
                  hintText: '이메일을 입력해 주세요',
                  prefixIcon: const Icon(Icons.mail_outline, size: 20),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.radius_1),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text("비밀번호*"),
              TextField(
                obscureText: _obsecureText,
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.radius_1),
                    borderSide: BorderSide(color: AppColors.black, width: 2),
                  ),
                  hintText: '비밀번호를 입력해 주세요',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setState(() {
                        _obsecureText = !_obsecureText;
                      });
                    },
                    child: Icon(
                      _obsecureText
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
                    borderRadius: BorderRadius.circular(AppRadius.radius_1),
                  ),
                ),
              ),
              const SizedBox(height: 180),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    child: Text(
                      '비밀번호를 잊어버렸어요',
                      style: AppTypography.caption1.copyWith(
                        decoration: TextDecoration.underline,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {
                      print('Tab');
                    },
                  ),
                  GestureDetector(
                    child: Text(
                      '아직 계정이 없으신가요?',
                      style: AppTypography.caption1.copyWith(
                        decoration: TextDecoration.underline,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {
                      print('Tab');
                    },
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
                  onPressed: () {},
                  child: Text(
                    '로그인',
                    style: AppTypography.button.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(indent: 35)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '또는',
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.gray700,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(endIndent: 35)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 60,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.radius_1),
                    ),
                  ),
                  onPressed: () {},
                  child: Text(
                    '로그인 없이 둘러보기',
                    style: AppTypography.button.copyWith(
                      fontSize: 16,
                      color: AppColors.gray700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
