import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/map/components/cluster_marker_icon.dart';
import 'package:muntum/screens/map/components/program_marker_icon.dart';

class MapMarkerIconCache {
  final Map<String, Future<NOverlayImage>> _programIcons = {};
  final Map<int, Future<NOverlayImage>> _clusterIcons = {};
  final Map<String, Future<ui.Image?>> _imageLoads = {};
  final Map<String, ui.Image> _decodedImages = {};

  Future<NOverlayImage> programIcon({
    required BuildContext context,
    required ProgramModel program,
    required String programKey,
    required bool isSelected,
  }) {
    final imageUrl = program.imageUrls.isEmpty ? '' : program.imageUrls.first;
    final decodedImage = _decodedImages[imageUrl];
    final cacheKey =
        '${programKey}_${imageUrl}_${decodedImage != null}_$isSelected';
    return _programIcons.putIfAbsent(
      cacheKey,
      () => NOverlayImage.fromWidget(
        context: context,
        size: Size(64.w, 64.w),
        widget: ProgramMarkerIcon(
          program: program,
          isSelected: isSelected,
          decodedNetworkImage: decodedImage,
        ),
      ),
    );
  }

  Future<NOverlayImage> clusterIcon({
    required BuildContext context,
    required int count,
  }) {
    return _clusterIcons.putIfAbsent(
      count,
      () => NOverlayImage.fromWidget(
        context: context,
        size: Size(48.w, 48.w),
        widget: ClusterMarkerIcon(count: count),
      ),
    );
  }

  Future<bool> loadProgramImage({
    required BuildContext context,
    required ProgramModel program,
    required bool Function() isActive,
  }) async {
    if (program.imageUrls.isEmpty) {
      return false;
    }

    final imageUrl = program.imageUrls.first;
    if (_decodedImages.containsKey(imageUrl)) {
      return true;
    }

    final imageConfiguration = createLocalImageConfiguration(context);
    final loadFuture = _imageLoads.putIfAbsent(
      imageUrl,
      () => _decodeWithRetry(imageConfiguration, imageUrl, isActive),
    );
    final decodedImage = await loadFuture;
    if (decodedImage == null) {
      if (identical(_imageLoads[imageUrl], loadFuture)) {
        _imageLoads.remove(imageUrl);
      }
      return false;
    }
    _decodedImages[imageUrl] = decodedImage;
    return true;
  }

  Future<ui.Image?> _decodeWithRetry(
    ImageConfiguration imageConfiguration,
    String imageUrl,
    bool Function() isActive,
  ) async {
    const retryDelays = [
      Duration.zero,
      Duration(seconds: 1),
      Duration(seconds: 3),
    ];
    for (final delay in retryDelays) {
      if (delay != Duration.zero) {
        await Future<void>.delayed(delay);
      }
      if (!isActive()) {
        return null;
      }
      final image = await _decode(imageConfiguration, imageUrl);
      if (image != null) {
        return image;
      }
    }
    return null;
  }

  Future<ui.Image?> _decode(
    ImageConfiguration imageConfiguration,
    String imageUrl,
  ) async {
    final completer = Completer<ui.Image?>();
    final stream = NetworkImage(imageUrl).resolve(imageConfiguration);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (imageInfo, synchronousCall) {
        stream.removeListener(listener);
        if (!completer.isCompleted) {
          completer.complete(imageInfo.image.clone());
        }
      },
      onError: (Object error, StackTrace? stackTrace) {
        stream.removeListener(listener);
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  void dispose() {
    for (final image in _decodedImages.values) {
      image.dispose();
    }
    _decodedImages.clear();
    _imageLoads.clear();
    _programIcons.clear();
    _clusterIcons.clear();
  }
}
