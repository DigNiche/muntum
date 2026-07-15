import 'package:flutter/material.dart';
import 'package:muntum/api/token_store.dart';
import 'package:muntum/components/action_bottom_sheet.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/services/scrap_service.dart';
import 'package:muntum/services/analytics_service.dart';
import 'package:muntum/stores/program_scrap_store.dart';
import 'package:muntum/utils/app_toast.dart';

Future<bool> _isLoggedIn() async {
  final accessToken = TokenStore.instance.accessToken;
  if (accessToken != null && accessToken.isNotEmpty) {
    return true;
  }
  final refreshToken = await TokenStore.instance.readRefreshToken();
  return refreshToken != null && refreshToken.isNotEmpty;
}

Future<void> toggleProgramScrap(
  BuildContext context,
  ProgramModel program, {
  String entrySource = 'unknown',
}) async {
  if (!await _isLoggedIn()) {
    if (!context.mounted) return;
    await showActionBottomSheet(
      context,
      type: ActionBottomSheetType.scrapLogin,
    );
    return;
  }

  final previous = ProgramScrapStore.instance.isScrapped(program);
  ProgramScrapStore.instance.setScrapped(program, !previous);

  try {
    if (ProgramScrapStore.instance.isScrapped(program)) {
      await ScrapService().scrapProgram(program.id);
    } else {
      await ScrapService().unscrapProgram(program.id);
    }
    await AnalyticsService.instance.logScrapChanged(
      program: program,
      entrySource: entrySource,
      isScrapped: !previous,
    );
  } catch (error) {
    if (!context.mounted) return;
    ProgramScrapStore.instance.setScrapped(program, previous);
    showAppToast(context, '$error');
  }
}
