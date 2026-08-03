import 'package:flutter/material.dart';
import 'package:muntum/components/update_dialog.dart';
import 'package:muntum/services/update_service.dart';
import 'package:muntum/utils/app_toast.dart';

class UpdateGate extends StatefulWidget {
  final Widget child;

  const UpdateGate({super.key, required this.child});

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> {
  bool _isDialogVisible = false;
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    if (_hasChecked) return;
    _hasChecked = true;

    try {
      final updateInfo = await UpdateService.instance.checkForUpdate();
      if (!mounted || updateInfo == null || _isDialogVisible) return;
      await _showUpdateDialog(updateInfo);
    } catch (error) {
      debugPrint('업데이트 확인 중 오류가 발생했습니다: $error');
    }
  }

  Future<void> _showUpdateDialog(AppUpdateInfo updateInfo) async {
    _isDialogVisible = true;
    await showAppUpdateDialog(
      context: context,
      updateInfo: updateInfo,
      onUpdate: () async {
        final didOpen = await UpdateService.instance.openStore(
          updateInfo.storeUrl,
        );
        if (!didOpen && mounted) {
          showAppToast(context, '스토어를 열지 못했어요.', isError: true);
        }
      },
    );
    _isDialogVisible = false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
