import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/api/token_store.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/services/user_service.dart';
import 'package:muntum/utils/app_toast.dart';

class NickNameChangeScreen extends StatefulWidget {
  const NickNameChangeScreen({super.key});

  @override
  State<NickNameChangeScreen> createState() => _NickNameChangeScreenState();
}

class _NickNameChangeScreenState extends State<NickNameChangeScreen> {
  final _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  static const int _maxNicknameLength = 50;
  bool _isSaving = false;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    _loadNickname();
  }

  Future<void> _loadNickname() async {
    final nickname = await TokenStore.instance.readNickname();
    if (!mounted || nickname == null) return;
    _controller.text = nickname;
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _onFocusChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
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
            center: "닉네임 변경",
            leadingIcon: 'close.svg',
            onLeadingTap: () {
              Navigator.pop(context);
            },
            trailing: GestureDetector(
              onTap: _saveNickname,
              child: Text(
                _isSaving ? "저장 중" : "저장",
                style: AppTypography.button2.copyWith(
                  color: _controller.text.isNotEmpty
                      ? AppColors.gray900
                      : AppColors.gray500,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24.h),
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLength: _maxNicknameLength,
                  cursorColor: AppColors.gray900,
                  style: AppTypography.body1.copyWith(color: AppColors.gray900),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '닉네임을 입력해주세요.',
                    hintStyle: AppTypography.body1.copyWith(
                      color: AppColors.gray900,
                    ),
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 13.h,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(
                        color: AppColors.lineNormal,
                        width: 1.w,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(
                        color: AppColors.gray400,
                        width: 1.w,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(
                        color: AppColors.error,
                        width: 1.w,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(
                        color: AppColors.error,
                        width: 1.w,
                      ),
                    ),
                    errorText: _isError ? '닉네임을 확인해주세요.' : null,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '(${_controller.text.length}/$_maxNicknameLength)',
                  style: AppTypography.caption2.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNickname() async {
    final nickname = _controller.text.trim();
    if (_isSaving || nickname.isEmpty) return;

    setState(() {
      _isSaving = true;
      _isError = false;
    });
    try {
      await UserService().updateNickname(nickname);
      if (!mounted) return;
      Navigator.pop(context, nickname);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isError = true);
      showAppToast(context, '$error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
