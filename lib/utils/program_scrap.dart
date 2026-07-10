import 'package:flutter/material.dart';
import 'package:muntum/api/api_config.dart';
import 'package:muntum/api/token_store.dart';
import 'package:muntum/components/action_bottom_sheet.dart';
import 'package:muntum/data/mock_user_data.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/services/scrap_service.dart';
import 'package:muntum/utils/app_toast.dart';

Future<bool> _isLoggedIn() async {
  if (!ApiConfig.hasBaseUrl) {
    return MockUserSession.instance.isLoggedIn;
  }
  final accessToken = TokenStore.instance.accessToken;
  if (accessToken != null && accessToken.isNotEmpty) {
    return true;
  }
  final refreshToken = await TokenStore.instance.readRefreshToken();
  return refreshToken != null && refreshToken.isNotEmpty;
}

Future<void> toggleProgramScrap(
  BuildContext context,
  ProgramModel program,
) async {
  if (!await _isLoggedIn()) {
    if (!context.mounted) return;
    await showActionBottomSheet(
      context,
      type: ActionBottomSheetType.scrapLogin,
    );
    return;
  }

  final previous = MockBookmarkStore.instance.isBookmarked(program);
  MockBookmarkStore.instance.toggle(program);

  if (!ApiConfig.hasBaseUrl || program.id.isEmpty) {
    return;
  }

  try {
    if (MockBookmarkStore.instance.isBookmarked(program)) {
      await ScrapService().scrapProgram(program.id);
    } else {
      await ScrapService().unscrapProgram(program.id);
    }
    MockBookmarkStore.instance.notifyChanged();
  } catch (error) {
    if (!context.mounted) return;
    MockBookmarkStore.instance.setBookmarked(program, previous);
    showAppToast(context, '$error');
  }
}
