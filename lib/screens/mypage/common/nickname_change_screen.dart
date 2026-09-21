import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/api/token_store.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/button_solid.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/services/user_service.dart';
import 'package:muntum/utils/app_toast.dart';
import 'package:muntum/utils/image_upload_format.dart';

class NickNameChangeScreen extends StatefulWidget {
  const NickNameChangeScreen({super.key});

  @override
  State<NickNameChangeScreen> createState() => _NickNameChangeScreenState();
}

class _NickNameChangeScreenState extends State<NickNameChangeScreen> {
  final _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  static const int _maxNicknameLength = 50;
  final _imagePicker = ImagePicker();
  bool _isSaving = false;
  bool _isError = false;
  String _initialNickname = '';
  String? _profileImageUrl;
  XFile? _selectedProfileImage;
  bool _selectedProfileImageIsTemporary = false;
  bool _deleteProfileImage = false;

  bool get _hasChanges =>
      _controller.text.trim() != _initialNickname ||
      _selectedProfileImage != null ||
      _deleteProfileImage;

  bool get _canSave =>
      !_isSaving && _controller.text.trim().isNotEmpty && _hasChanges;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    _loadNickname();
  }

  Future<void> _loadNickname() async {
    try {
      final profile = await UserService().fetchProfile();
      if (!mounted) return;
      _initialNickname = profile.nickname;
      _controller.text = profile.nickname;
      setState(() => _profileImageUrl = profile.profileImageUrl);
    } catch (_) {
      final nickname = await TokenStore.instance.readNickname();
      if (!mounted || nickname == null) return;
      _initialNickname = nickname;
      _controller.text = nickname;
    }
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _onFocusChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _deleteTemporaryProfileImage();
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
            center: "프로필 수정",
            leadingIcon: 'arrow_left.svg',
            onLeadingTap: () {
              Navigator.pop(context);
            },
            trailing: GestureDetector(
              onTap: _canSave ? _saveProfile : null,
              child: Text(
                _isSaving ? "저장 중" : "완료",
                style: AppTypography.button2.copyWith(
                  color: _canSave ? AppColors.gray900 : AppColors.gray500,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 32.h),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _showProfileImageOptions,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildProfileImage(),
                      Positioned(
                        right: -4.r,
                        bottom: -4.r,
                        child: SvgPicture.asset(
                          'assets/icons/profile_image_add.svg',
                          width: 32.r,
                          height: 32.r,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "닉네임",
                      style: AppTypography.button3.copyWith(
                        color: AppColors.gray700,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLength: _maxNicknameLength,
                      cursorColor: AppColors.gray900,
                      style: AppTypography.body1.copyWith(
                        color: AppColors.gray900,
                      ),
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
                        errorText: _isError ? '중복된 닉네임' : null,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    final selected = _selectedProfileImage;
    Widget image;
    if (selected != null) {
      image = Image.file(
        File(selected.path),
        width: 88.r,
        height: 88.r,
        fit: BoxFit.cover,
      );
    } else if (!_deleteProfileImage && _profileImageUrl != null) {
      image = Image.network(
        _profileImageUrl!,
        width: 88.r,
        height: 88.r,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _defaultProfileImage(),
      );
    } else {
      image = _defaultProfileImage();
    }
    return ClipOval(child: image);
  }

  Widget _defaultProfileImage() {
    return Image.asset(
      'assets/default_profile_img.jpg',
      width: 88.r,
      height: 88.r,
      fit: BoxFit.cover,
    );
  }

  Future<void> _showProfileImageOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      barrierColor: AppColors.dimMedium,
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '프로필 이미지 변경',
                style: AppTypography.title4.copyWith(color: AppColors.gray900),
              ),
              SizedBox(height: 12.h),
              _ProfileImageOption(
                text: '앨범에서 선택',
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _pickProfileImage();
                },
              ),
              _ProfileImageOption(
                text: '기본 이미지로 변경',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _deleteTemporaryProfileImage();
                  setState(() {
                    _selectedProfileImage = null;
                    _deleteProfileImage = true;
                  });
                },
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ButtonSolid(
                  text: '닫기',
                  textColor: AppColors.white,
                  boxColor: AppColors.black,
                  padding: EdgeInsets.zero,
                  onTap: () => Navigator.pop(sheetContext),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (!mounted || image == null) return;
    PreparedUploadImage prepared;
    try {
      prepared = await prepareImageForUpload(image.path);
    } catch (_) {
      if (mounted) {
        showAppToast(context, supportedUploadImageMessage, isError: true);
      }
      return;
    }
    if (!mounted) {
      if (prepared.isTemporary) File(prepared.path).delete().ignore();
      return;
    }
    _deleteTemporaryProfileImage();
    setState(() {
      _selectedProfileImage = XFile(prepared.path);
      _selectedProfileImageIsTemporary = prepared.isTemporary;
      _deleteProfileImage = false;
    });
  }

  void _deleteTemporaryProfileImage() {
    final image = _selectedProfileImage;
    if (_selectedProfileImageIsTemporary && image != null) {
      File(image.path).delete().ignore();
    }
    _selectedProfileImageIsTemporary = false;
  }

  Future<void> _saveProfile() async {
    final nickname = _controller.text.trim();
    if (_isSaving || nickname.isEmpty) return;

    setState(() {
      _isSaving = true;
      _isError = false;
    });
    try {
      final service = UserService();
      if (nickname != _initialNickname) {
        await service.updateNickname(nickname);
      }
      final selectedImage = _selectedProfileImage;
      if (selectedImage != null) {
        await service.updateProfileImage(selectedImage.path);
      } else if (_deleteProfileImage && _profileImageUrl != null) {
        await service.deleteProfileImage();
      }
      if (!mounted) return;
      Navigator.pop(context, nickname);
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 409) setState(() => _isError = true);
      showAppToast(context, '$error', isError: true);
    } catch (error) {
      if (mounted) showAppToast(context, '$error', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _ProfileImageOption extends StatelessWidget {
  const _ProfileImageOption({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0.h),
        child: SizedBox(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: AppTypography.body1.copyWith(color: AppColors.gray900),
            ),
          ),
        ),
      ),
    );
  }
}
