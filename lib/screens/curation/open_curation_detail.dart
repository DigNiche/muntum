import 'package:material_ui/material_ui.dart';
import 'package:muntum/screens/mypage/manager/curation_review_screen.dart';
import 'package:muntum/screens/mypage/manager/program_curations_manage_screen.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/services/admin_curation_service.dart';
import 'package:muntum/services/curation_service.dart';
import 'package:muntum/services/program_service.dart';
import 'package:muntum/stores/auth_state.dart';

/// Opens the program's curation management page for managers, not the reader.
///
/// Unlinked submissions have no program management page and use review instead.
/// The public reader builder remains lazy for audience and curator accounts.
Future<String?> openCurationDetail(
  BuildContext context, {
  required String curationId,
  required WidgetBuilder publicBuilder,
  String? programId,
  String? programTitle,
  CurationService? curationService,
  AdminCurationService? adminService,
  ProgramService? programService,
}) => Navigator.push<String>(
  context,
  MaterialPageRoute(
    builder: (context) => AuthState.instance.isAdmin
        ? programId != null && programId.isNotEmpty
              ? ProgramCurationsManageScreen(
                  program: ProgramModel.fromJson({
                    'id': programId,
                    'title': programTitle ?? '',
                  }),
                  curationService: curationService,
                  adminService: adminService,
                )
              : CurationReviewScreen.byId(
                  curationId: curationId,
                  service: adminService,
                  programService: programService,
                )
        : publicBuilder(context),
  ),
);
