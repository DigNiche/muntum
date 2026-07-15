import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:muntum/models/program_model.dart';

/// Google Analytics event names and parameters used by the app.
///
/// Keep values low-cardinality where they are used as GA custom dimensions.
/// Program IDs are included for BigQuery/funnel analysis, but should not be
/// registered as a custom dimension in GA because they are high-cardinality.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logHomeTabView(String tabName) {
    return _ignoreErrors(
      () => _analytics.logEvent(
        name: 'home_tab_view',
        parameters: {'tab_name': tabName},
      ),
    );
  }

  Future<void> logProgramDetailView({
    required ProgramModel program,
    required String entrySource,
  }) {
    return _ignoreErrors(
      () => _analytics.logEvent(
        name: 'program_detail_view',
        parameters: _programParameters(program, entrySource),
      ),
    );
  }

  Future<void> logScrapChanged({
    required ProgramModel program,
    required String entrySource,
    required bool isScrapped,
  }) {
    return _ignoreErrors(
      () => _analytics.logEvent(
        name: isScrapped ? 'scrap_add' : 'scrap_remove',
        parameters: _programParameters(program, entrySource),
      ),
    );
  }

  Future<void> logExternalLinkClick({
    required ProgramModel program,
    required String entrySource,
    required String linkType,
  }) {
    return _ignoreErrors(
      () => _analytics.logEvent(
        name: 'external_link_click',
        parameters: {
          ..._programParameters(program, entrySource),
          'link_type': linkType,
        },
      ),
    );
  }

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) {
    return _ignoreErrors(
      () => _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      ),
    );
  }

  Future<void> setUserId(String? userId) {
    return _ignoreErrors(
      () => _analytics.setUserId(
        id: userId?.trim().isEmpty == true ? null : userId,
      ),
    );
  }

  Future<void> _ignoreErrors(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Analytics must never interrupt navigation or a user action.
    }
  }

  Map<String, Object> _programParameters(
    ProgramModel program,
    String entrySource,
  ) {
    return {
      if (program.id.trim().isNotEmpty) 'program_id': program.id.trim(),
      'program_type': program.programType?.label ?? 'unknown',
      'entry_source': entrySource,
    };
  }
}
