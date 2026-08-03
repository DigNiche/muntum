import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateRemoteConfigKeys {
  static const enabled = 'update_enabled';
  static const title = 'update_title';
  static const message = 'update_message';

  static const androidLatestVersion = 'android_latest_version';
  static const androidLatestBuild = 'android_latest_build';
  static const androidMinimumVersion = 'android_minimum_version';
  static const androidMinimumBuild = 'android_minimum_build';
  static const androidStoreUrl = 'android_store_url';

  static const iosLatestVersion = 'ios_latest_version';
  static const iosLatestBuild = 'ios_latest_build';
  static const iosMinimumVersion = 'ios_minimum_version';
  static const iosMinimumBuild = 'ios_minimum_build';
  static const iosStoreUrl = 'ios_store_url';

  const UpdateRemoteConfigKeys._();
}

class AppUpdateInfo {
  final bool isRequired;
  final String title;
  final String message;
  final Uri storeUrl;
  final AppReleaseVersion installedVersion;
  final AppReleaseVersion latestVersion;

  const AppUpdateInfo({
    required this.isRequired,
    required this.title,
    required this.message,
    required this.storeUrl,
    required this.installedVersion,
    required this.latestVersion,
  });
}

class AppReleaseVersion {
  final List<int> parts;
  final int build;

  const AppReleaseVersion({required this.parts, required this.build});

  factory AppReleaseVersion.parse(String version, {required int build}) {
    final normalizedVersion = version.split('+').first.split('-').first;
    return AppReleaseVersion(
      parts: normalizedVersion
          .split('.')
          .map((part) => int.tryParse(part) ?? 0)
          .toList(),
      build: build,
    );
  }

  int compareVersionTo(AppReleaseVersion other) {
    final partCount = parts.length > other.parts.length
        ? parts.length
        : other.parts.length;
    for (var index = 0; index < partCount; index++) {
      final currentPart = index < parts.length ? parts[index] : 0;
      final otherPart = index < other.parts.length ? other.parts[index] : 0;
      final comparison = currentPart.compareTo(otherPart);
      if (comparison != 0) return comparison;
    }
    return 0;
  }
}

class AppUpdatePolicy {
  const AppUpdatePolicy._();

  static bool isOutdated({
    required TargetPlatform platform,
    required AppReleaseVersion installed,
    required AppReleaseVersion target,
  }) {
    return switch (platform) {
      TargetPlatform.android => installed.build < target.build,
      TargetPlatform.iOS => installed.compareVersionTo(target) < 0,
      _ => false,
    };
  }
}

class UpdateService {
  UpdateService._();

  static final UpdateService instance = UpdateService._();

  static const _androidStoreUrl =
      'https://play.google.com/store/apps/details?id=co.digniche.muntum';
  static const _iosStoreUrl = 'https://apps.apple.com/app/id6789416280';

  Future<AppUpdateInfo?>? _checkFuture;

  Future<AppUpdateInfo?> checkForUpdate({bool forceRefresh = false}) {
    if (forceRefresh || _checkFuture == null) {
      _checkFuture = _checkSafely();
    }
    return _checkFuture!;
  }

  Future<bool> openStore(Uri storeUrl) {
    return launchUrl(storeUrl, mode: LaunchMode.externalApplication);
  }

  Future<AppUpdateInfo?> _checkSafely() async {
    try {
      return await _checkRemoteConfig();
    } catch (error) {
      debugPrint('업데이트 확인 실패: $error');
      return null;
    }
  }

  Future<AppUpdateInfo?> _checkRemoteConfig() async {
    final platform = defaultTargetPlatform;
    final platformPrefix = switch (platform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => null,
    };
    if (platformPrefix == null) return null;

    final packageInfo = await PackageInfo.fromPlatform();
    final installedBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
    final installedVersion = AppReleaseVersion.parse(
      packageInfo.version,
      build: installedBuild,
    );
    final remoteConfig = FirebaseRemoteConfig.instance;

    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode
            ? Duration.zero
            : const Duration(hours: 12),
      ),
    );
    await remoteConfig.setDefaults({
      UpdateRemoteConfigKeys.enabled: false,
      UpdateRemoteConfigKeys.title: '새로운 버전이 있어요',
      UpdateRemoteConfigKeys.message: '문틈의 최신 버전을 사용해보세요.',
      UpdateRemoteConfigKeys.androidLatestVersion: packageInfo.version,
      UpdateRemoteConfigKeys.androidLatestBuild: installedBuild,
      UpdateRemoteConfigKeys.androidMinimumVersion: '0.0.0',
      UpdateRemoteConfigKeys.androidMinimumBuild: 0,
      UpdateRemoteConfigKeys.androidStoreUrl: _androidStoreUrl,
      UpdateRemoteConfigKeys.iosLatestVersion: packageInfo.version,
      UpdateRemoteConfigKeys.iosLatestBuild: installedBuild,
      UpdateRemoteConfigKeys.iosMinimumVersion: '0.0.0',
      UpdateRemoteConfigKeys.iosMinimumBuild: 0,
      UpdateRemoteConfigKeys.iosStoreUrl: _iosStoreUrl,
    });

    try {
      await remoteConfig.fetchAndActivate();
    } catch (error) {
      debugPrint('Remote Config 업데이트 확인 실패: $error');
    }

    if (!remoteConfig.getBool(UpdateRemoteConfigKeys.enabled)) return null;

    final latestVersion = _readVersion(
      remoteConfig,
      '${platformPrefix}_latest_version',
      '${platformPrefix}_latest_build',
    );
    final minimumVersion = _readVersion(
      remoteConfig,
      '${platformPrefix}_minimum_version',
      '${platformPrefix}_minimum_build',
    );
    final isRequired = AppUpdatePolicy.isOutdated(
      platform: platform,
      installed: installedVersion,
      target: minimumVersion,
    );
    final needsUpdate = AppUpdatePolicy.isOutdated(
      platform: platform,
      installed: installedVersion,
      target: latestVersion,
    );
    if (!isRequired && !needsUpdate) return null;

    final storeUrlValue = remoteConfig
        .getString('${platformPrefix}_store_url')
        .trim();
    final storeUrl = Uri.tryParse(storeUrlValue);
    if (storeUrl == null || !storeUrl.hasScheme) return null;

    final title = remoteConfig.getString(UpdateRemoteConfigKeys.title).trim();
    final message = remoteConfig
        .getString(UpdateRemoteConfigKeys.message)
        .trim();
    return AppUpdateInfo(
      isRequired: isRequired,
      title: title.isEmpty ? '새로운 버전이 있어요' : title,
      message: message.isEmpty ? '문틈의 최신 버전을 사용해보세요.' : message,
      storeUrl: storeUrl,
      installedVersion: installedVersion,
      latestVersion: latestVersion,
    );
  }

  AppReleaseVersion _readVersion(
    FirebaseRemoteConfig remoteConfig,
    String versionKey,
    String buildKey,
  ) {
    return AppReleaseVersion.parse(
      remoteConfig.getString(versionKey),
      build: remoteConfig.getInt(buildKey),
    );
  }
}
