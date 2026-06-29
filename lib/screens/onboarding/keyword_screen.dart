import 'package:flutter/material.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/spacing.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/screens/onboarding/loading.dart';

class KeywordScreen extends StatefulWidget {
  const KeywordScreen({super.key});

  @override
  State<KeywordScreen> createState() => _KeywordScreenState();
}

class _KeywordScreenState extends State<KeywordScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
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
                  Text('어떤 문화를 즐기시나요?', style: AppTypography.display),

                  const SizedBox(height: 16),
                  Text(
                    '3개 이상의 취향 키워드를 선택해 주세요.\n많이 선택할 수록 다양한 추천을 받을 수 있어요.',
                    style: AppTypography.body1,
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
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.radius_10,
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoadingScreen()),
                    );
                  },
                  child: Text(
                    '다음으로',
                    style: AppTypography.button1.copyWith(
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
