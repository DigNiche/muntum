import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/screens/mypage/components/profile_menu_item.dart';
import 'package:muntum/services/user_service.dart';
import 'package:muntum/utils/app_toast.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _handleLocationPermissionTap() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await _syncLocationTermsConsent(false);
      if (!mounted) return;
      _showMessage('기기의 위치 서비스를 켜주세요.');
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      await _syncLocationTermsConsent(false);
      if (!mounted) return;
      _showMessage('설정에서 위치 권한을 허용해주세요.');
      await Geolocator.openAppSettings();
      return;
    }

    if (permission == LocationPermission.denied) {
      await _syncLocationTermsConsent(false);
      if (!mounted) return;
      _showMessage('위치 권한이 거부되었어요.');
      return;
    }

    await _syncLocationTermsConsent(true);
    if (!mounted) return;
    _showMessage('위치 권한이 허용되었어요.');
  }

  Future<void> _syncLocationTermsConsent(bool agreed) async {
    try {
      await UserService().updateLocationTermsConsent(agreed);
    } catch (_) {
      // 로그인 전이거나 네트워크 오류가 있어도 설정 UI는 계속 사용할 수 있게 둔다.
    }
  }

  void _showMessage(String message) {
    showAppToast(context, message);
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
            leadingIcon: 'arrow_left.svg',
            center: '설정',
            onLeadingTap: () {
              Navigator.pop(context);
            },
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0.w),
            child: ProfileMenuItem(
              onTap: _handleLocationPermissionTap,
              text: '위치 권한 설정',
            ),
          ),
        ],
      ),
    );
  }
}
