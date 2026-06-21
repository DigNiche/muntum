import 'package:flutter/material.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/spacing.dart';
import 'package:muntum/constants/typography.dart';

class NicknameScreen extends StatefulWidget {
  const NicknameScreen({super.key});

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  bool get _isNickNameValid {
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final nicknameErrorText = _isNickNameValid ? ' ' : '중복되는 닉네임 입니다.';
    return Scaffold(
      backgroundColor: AppColors.backgroundNormal,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.horizontalMargin,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
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
                  Text('닉네임 생성 하기', style: AppTypography.display),

                  const SizedBox(height: 16),
                  Text(
                    '닉네임은 가입 후에도.\n마이페이지에서 수정할 수 있어요',
                    style: AppTypography.body1,
                  ),
                  const SizedBox(height: 28),
                  Text("닉네임*"),
                  TextField(
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.radius_1),
                        borderSide: BorderSide(
                          color: AppColors.black,
                          width: 2,
                        ),
                      ),
                      hintText: '사용하려는 닉네임을 입력해 주세요 ',
                      prefixIcon: const Icon(Icons.sell_outlined, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.radius_1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nicknameErrorText,
                    style: AppTypography.caption1.copyWith(
                      color: nicknameErrorText.trim().isEmpty
                          ? Colors.transparent
                          : AppColors.error,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
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
                    '다음으로',
                    style: AppTypography.button.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
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
