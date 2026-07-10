import 'dart:async';
import 'dart:math' as math;
import 'package:muntum/utils/app_toast.dart';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/components/filter_chip.dart';
import 'package:muntum/components/popup_widget.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/home/components/searchbar.dart';
import 'package:muntum/screens/map/components/findin_current_location.dart';
import 'package:muntum/screens/map/components/map_bottom_sheet.dart';
import 'package:muntum/screens/map/components/program_marker_icon.dart';
import 'package:muntum/screens/map/map_radius.dart';
import 'package:muntum/services/program_service.dart';
import 'package:muntum/services/user_service.dart';

class MapScreen extends StatefulWidget {
  final bool isActive;

  const MapScreen({super.key, this.isActive = true});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // TODO: Can't search at same time with filter chip
  final _searchbarController = TextEditingController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  List<ProgramModel> _mapPrograms = [];

  // 검색 중심에서 5km 안에 있는 동일한 프로그램 집합으로
  // 지도 마커와 바텀시트를 함께 갱신한다.
  List<ProgramModel> _visiblePrograms = [];
  Filter? _selectedFilter;
  ProgramModel? _selectedProgram;
  String _mapSearchQuery = '';
  NaverMapController? _mapController;
  NLatLng? _currentLocation;
  NLatLng? _initialMapCenter;
  Future<void> _markerRefreshQueue = Future<void>.value();

  bool _locationInitializationStarted = false;
  bool _initialLocationResolved = false;
  bool _isLocating = false;
  bool _isLocationPermissionPopupVisible = false;
  int _markerRefreshGeneration = 0;

  static const double _sheetMinSize = 0.26;
  static const double _sheetMaxSize = 0.78;
  static const double _searchRadiusMeters = 5000;
  static const double _initialZoom = 12.2;
  static const NLatLng _wonjuInitialTarget = NLatLng(37.3422, 127.9202);

  bool _showSearchHereButton = false;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _initializeCurrentLocation();
    }
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _initializeCurrentLocation();
    }
  }

  Future<void> _initializeCurrentLocation() async {
    if (_locationInitializationStarted) {
      return;
    }
    _locationInitializationStarted = true;
    _setLocating(true);

    NLatLng initialCenter = _wonjuInitialTarget;
    String? errorMessage;
    var permissionDenied = false;

    try {
      final position = await _determineCurrentPosition();
      initialCenter = NLatLng(position.latitude, position.longitude);
      _currentLocation = initialCenter;
    } on TimeoutException {
      errorMessage = '현재 위치를 확인하는 데 시간이 걸려 기본 위치로 이동했어요.';
    } on LocationServiceDisabledException {
      errorMessage = '기기의 위치 서비스를 켜주세요.';
    } on PermissionDeniedException {
      permissionDenied = true;
    } catch (_) {
      errorMessage = '현재 위치를 불러오지 못해 기본 위치로 이동했어요.';
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _initialMapCenter = initialCenter;
      _initialLocationResolved = true;
      _isLocating = false;
    });

    if (permissionDenied || errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.isActive) {
          if (permissionDenied) {
            _showLocationPermissionPopup();
          } else {
            _showLocationMessage(errorMessage!);
          }
        }
      });
    }
  }

  Future<Position> _determineCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await _syncLocationTermsConsent(false);
      throw const PermissionDeniedException('Location permission denied');
    }

    await _syncLocationTermsConsent(true);

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } on TimeoutException {
      final lastKnownPosition = await Geolocator.getLastKnownPosition();
      if (lastKnownPosition != null) {
        return lastKnownPosition;
      }
      rethrow;
    }
  }

  Future<void> _syncLocationTermsConsent(bool agreed) async {
    try {
      await UserService().updateLocationTermsConsent(agreed);
    } catch (_) {
      // 로그인 전이거나 네트워크 오류가 있어도 지도 사용 흐름은 막지 않는다.
    }
  }

  void _setLocating(bool value) {
    if (!mounted || _isLocating == value) {
      return;
    }
    setState(() {
      _isLocating = value;
    });
  }

  void _showLocationMessage(String message) {
    showAppToast(context, message);
  }

  // TODO: Add Listener to listen for permission
  Future<void> _showLocationPermissionPopup() async {
    if (!mounted || _isLocationPermissionPopupVisible) {
      return;
    }
    _isLocationPermissionPopupVisible = true;
    try {
      await showPopupWidget(
        context: context,
        title: '위치 권한이 필요해요',
        description: '주변 프로그램을 보려면 위치 접근을 허용해주세요.',
        text1: '닫기',
        text2: '설정으로 이동',
        onText1Tap: () {
          Navigator.of(context, rootNavigator: true).pop();
        },
        onText2Tap: () async {
          Navigator.of(context, rootNavigator: true).pop();
          final didOpenSettings = await Geolocator.openAppSettings();
          if (!didOpenSettings && mounted) {
            _showLocationMessage('설정 화면을 열지 못했어요.');
          }
        },
      );
    } finally {
      _isLocationPermissionPopupVisible = false;
    }
  }

  Future<List<ProgramModel>> _getProgramsWithinRadius(NLatLng center) async {
    final programs = await _fetchMapCandidatePrograms();
    _mapPrograms = programs;

    final visiblePrograms = programs.where((program) {
      final latitude = program.latitude;
      final longitude = program.longitude;
      if (latitude == null || longitude == null) return false;
      return isWithinRadius(
        centerLatitude: center.latitude,
        centerLongitude: center.longitude,
        targetLatitude: latitude,
        targetLongitude: longitude,
        radiusMeters: _searchRadiusMeters,
      );
    }).toList();

    visiblePrograms.sort((a, b) {
      final aDistance = _distanceInMeters(
        center.latitude,
        center.longitude,
        a.latitude!,
        a.longitude!,
      );
      final bDistance = _distanceInMeters(
        center.latitude,
        center.longitude,
        b.latitude!,
        b.longitude!,
      );
      return aDistance.compareTo(bDistance);
    });
    return visiblePrograms;
  }

  Future<List<ProgramModel>> _fetchMapCandidatePrograms() async {
    final service = ProgramService();
    try {
      if (_selectedFilter == Filter.nowHot) {
        return (await service.fetchHotPrograms(size: 100)).content;
      }
      return (await service.fetchPrograms(
        search: _mapSearchQuery.isEmpty ? null : _mapSearchQuery,
        chip: _selectedFilter,
        size: 100,
      )).content;
    } catch (error) {
      if (mounted) {
        showAppToast(context, '$error');
      }
      return const <ProgramModel>[];
    }
  }

  Future<void> _submitMapSearch(String value) async {
    final query = value.trim();
    setState(() {
      _mapSearchQuery = query;
      if (query.isNotEmpty) {
        _selectedFilter = null;
      }
    });

    final controller = _mapController;
    if (controller == null) {
      return;
    }

    final matchedPrograms = await _fetchMapCandidatePrograms();
    if (query.isNotEmpty && matchedPrograms.isNotEmpty) {
      final firstMatch = matchedPrograms.firstWhere(
        (program) => program.latitude != null && program.longitude != null,
        orElse: () => matchedPrograms.first,
      );
      if (firstMatch.latitude == null || firstMatch.longitude == null) {
        await _refreshAtCurrentMapCenter();
        return;
      }
      await _focusOnSearchRadiusAndRefresh(
        controller,
        NLatLng(firstMatch.latitude!, firstMatch.longitude!),
        animated: true,
      );
      return;
    }

    await _refreshAtCurrentMapCenter();
  }

  Future<void> _clearMapSearch() async {
    setState(() {
      _mapSearchQuery = '';
    });
    await _refreshAtCurrentMapCenter();
  }

  Future<void> _toggleMapFilter(Filter filter) async {
    setState(() {
      _selectedFilter = _selectedFilter == filter ? null : filter;
      _mapSearchQuery = '';
      _searchbarController.clear();
    });
    await _refreshAtCurrentMapCenter();
  }

  Future<void> _refreshAtCurrentMapCenter() async {
    final controller = _mapController;
    if (controller == null) {
      return;
    }
    final cameraPosition = await controller.getCameraPosition();
    await _refreshVisibleProgramsAndMarkers(controller, cameraPosition.target);
  }

  Widget _buildMapFilterChip(Filter filter, String text) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () => _toggleMapFilter(filter),
      child: FilterChipWidget(
        hasShadow: true,
        text: text,
        textColor: isSelected ? AppColors.white : AppColors.gray800,
        backgroundColor: isSelected ? AppColors.gray900 : AppColors.white,
        outlineColor: isSelected ? AppColors.gray900 : AppColors.lineNormal,
      ),
    );
  }

  String _markerIdFor(ProgramModel program) {
    return 'program_${_mapPrograms.indexOf(program) + 1}';
  }

  List<_ProgramCluster> _clusterPrograms(
    List<ProgramModel> programs,
    double zoom,
  ) {
    final clusters = <_ProgramCluster>[];
    final thresholdMeters = _clusterThresholdMeters(zoom);

    for (final program in programs) {
      _ProgramCluster? targetCluster;

      for (final cluster in clusters) {
        final distance = _distanceInMeters(
          program.latitude!,
          program.longitude!,
          cluster.latitude,
          cluster.longitude,
        );

        if (distance <= thresholdMeters) {
          targetCluster = cluster;
          break;
        }
      }

      if (targetCluster == null) {
        clusters.add(_ProgramCluster(programs: [program]));
      } else {
        targetCluster.programs.add(program);
      }
    }

    return clusters;
  }

  double _clusterThresholdMeters(double zoom) {
    if (zoom < 12) return 900;
    if (zoom < 13.5) return 500;
    if (zoom < 15) return 180;
    if (zoom < 16.5) return 70;
    return 25;
  }

  double _distanceInMeters(double lat1, double lng1, double lat2, double lng2) {
    return distanceBetweenMeters(
      centerLatitude: lat1,
      centerLongitude: lng1,
      targetLatitude: lat2,
      targetLongitude: lng2,
    );
  }

  double _degreeToRadian(double degree) {
    return degree * math.pi / 180;
  }

  Future<void> _searchProgramsInCurrentMapArea() async {
    final controller = _mapController;
    if (controller == null) {
      return;
    }

    final cameraPosition = await controller.getCameraPosition();
    await _focusOnSearchRadiusAndRefresh(
      controller,
      cameraPosition.target,
      animated: true,
    );
  }

  Future<void> _moveToCurrentLocation() async {
    final controller = _mapController;
    if (controller == null || _isLocating) {
      return;
    }

    _setLocating(true);
    try {
      final position = await _determineCurrentPosition();
      if (!mounted) {
        return;
      }

      final currentLocation = NLatLng(position.latitude, position.longitude);
      _currentLocation = currentLocation;
      _updateCurrentLocationOverlay(controller, currentLocation);
      await _focusOnSearchRadiusAndRefresh(
        controller,
        currentLocation,
        animated: true,
      );
    } on LocationServiceDisabledException {
      _showLocationMessage('기기의 위치 서비스를 켜주세요.');
    } on PermissionDeniedException {
      await _showLocationPermissionPopup();
    } on TimeoutException {
      _showLocationMessage('현재 위치를 확인하지 못했어요. 잠시 후 다시 시도해주세요.');
    } catch (_) {
      _showLocationMessage('현재 위치를 불러오지 못했어요.');
    } finally {
      _setLocating(false);
    }
  }

  void _updateCurrentLocationOverlay(
    NaverMapController controller,
    NLatLng location,
  ) {
    final locationOverlay = controller.getLocationOverlay();
    locationOverlay.setPosition(location);
  }

  Future<void> _focusOnSearchRadiusAndRefresh(
    NaverMapController controller,
    NLatLng center, {
    required bool animated,
  }) async {
    final cameraUpdate = NCameraUpdate.fitBounds(
      _boundsAround(center, _searchRadiusMeters),
      padding: EdgeInsets.all(24.r),
    );
    if (animated) {
      cameraUpdate.setAnimation(
        animation: NCameraAnimation.easing,
        duration: const Duration(milliseconds: 450),
      );
    }
    await controller.updateCamera(cameraUpdate);
    if (!mounted) {
      return;
    }
    await _refreshVisibleProgramsAndMarkers(controller, center);
  }

  NLatLngBounds _boundsAround(NLatLng center, double radiusMeters) {
    final latitudeDelta = radiusMeters / 111320;
    final longitudeDelta =
        radiusMeters /
        (111320 * math.cos(_degreeToRadian(center.latitude)).abs());

    return NLatLngBounds(
      southWest: NLatLng(
        center.latitude - latitudeDelta,
        center.longitude - longitudeDelta,
      ),
      northEast: NLatLng(
        center.latitude + latitudeDelta,
        center.longitude + longitudeDelta,
      ),
    );
  }

  Future<void> _refreshVisibleProgramsAndMarkers(
    NaverMapController controller,
    NLatLng center,
  ) async {
    final requestGeneration = ++_markerRefreshGeneration;
    final previousRefresh = _markerRefreshQueue;
    final refresh = () async {
      await previousRefresh;
      if (!mounted || requestGeneration != _markerRefreshGeneration) {
        return;
      }
      await _performMarkerRefresh(controller, center);
    }();

    _markerRefreshQueue = refresh.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    await refresh;
  }

  Future<void> _performMarkerRefresh(
    NaverMapController controller,
    NLatLng center,
  ) async {
    final cameraPosition = await controller.getCameraPosition();
    final visiblePrograms = await _getProgramsWithinRadius(center);
    final clusters = _clusterPrograms(visiblePrograms, cameraPosition.zoom);
    final markers = <NMarker>{};

    for (final cluster in clusters) {
      if (!mounted) {
        return;
      }
      final isCluster = cluster.programs.length > 1;
      final markerId = isCluster
          ? 'cluster_${cluster.programs.map(_markerIdFor).join('_')}'
          : _markerIdFor(cluster.programs.first);

      if (!isCluster) {
        await _precacheMarkerImage(cluster.programs.first);
        if (!mounted) {
          return;
        }
      }

      final marker = NMarker(
        id: markerId,
        position: NLatLng(cluster.latitude, cluster.longitude),
        icon: await NOverlayImage.fromWidget(
          context: context,
          size: Size(48.w, 48.w),
          widget: isCluster
              ? _ClusterMarkerIcon(count: cluster.programs.length)
              : ProgramMarkerIcon(program: cluster.programs.first),
        ),
      );

      marker.setOnTapListener((overlay) {
        if (!mounted) {
          return;
        }
        setState(() {
          _selectedProgram = isCluster ? null : cluster.programs.first;
          _visiblePrograms = cluster.programs;
          _showSearchHereButton = false;
        });

        if (_sheetController.isAttached) {
          _sheetController.animateTo(
            _sheetMinSize,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
        }
      });
      markers.add(marker);
    }

    if (!mounted) {
      return;
    }
    await controller.clearOverlays(type: NOverlayType.marker);
    if (markers.isNotEmpty) {
      await controller.addOverlayAll(markers);
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedProgram = null;
      _visiblePrograms = visiblePrograms;
      _showSearchHereButton = false;
    });

    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        _sheetMinSize,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _precacheMarkerImage(ProgramModel program) async {
    if (!mounted || program.imageUrls.isEmpty) {
      return;
    }

    try {
      await precacheImage(
        NetworkImage(program.imageUrls.first),
        context,
      ).timeout(const Duration(milliseconds: 1500));
    } catch (_) {
      // 이미지가 늦거나 실패해도 마커 자체는 fallback으로 표시한다.
    }
  }

  @override
  void dispose() {
    _searchbarController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialLocationResolved || _initialMapCenter == null) {
      return const ColoredBox(
        color: AppColors.white,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.gray900),
        ),
      );
    }

    final mapContentPadding = EdgeInsets.only(
      top: 140.h,
      bottom: MediaQuery.sizeOf(context).height * _sheetMinSize,
    );

    return Stack(
      children: [
        NaverMap(
          options: NaverMapViewOptions(
            initialCameraPosition: NCameraPosition(
              target: _initialMapCenter!,
              zoom: _initialZoom,
            ),
            contentPadding: mapContentPadding,
          ),
          onMapReady: (controller) async {
            _mapController = controller;
            final currentLocation = _currentLocation;
            if (currentLocation != null) {
              _updateCurrentLocationOverlay(controller, currentLocation);
            }
            await _focusOnSearchRadiusAndRefresh(
              controller,
              _initialMapCenter!,
              animated: false,
            );
          },
          onCameraChange: (reason, animated) {
            final isUserCameraChange =
                reason == NCameraUpdateReason.gesture ||
                reason == NCameraUpdateReason.control;
            if (isUserCameraChange && !_showSearchHereButton) {
              setState(() {
                _showSearchHereButton = true;
              });
            }
          },
        ),
        Column(
          children: [
            SizedBox(height: 50.h),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 8.h),
              child: SearchBarWidget(
                controller: _searchbarController,
                backgroundColor: AppColors.white,
                onSubmitted: _submitMapSearch,
                onClear: _clearMapSearch,
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                spacing: 8.w,
                children: [
                  _buildMapFilterChip(Filter.nowHot, '🔥지금핫한'),
                  _buildMapFilterChip(Filter.free, '무료'),
                  _buildMapFilterChip(Filter.thisWeek, '이번주'),
                  _buildMapFilterChip(Filter.noReservation, '예약없이'),
                  _buildMapFilterChip(Filter.exhibition, '전시'),
                  _buildMapFilterChip(Filter.show, '공연'),
                  _buildMapFilterChip(Filter.experience, '체험'),
                  _buildMapFilterChip(Filter.festival, '축제'),
                ],
              ),
            ),
          ],
        ),
        if (_showSearchHereButton)
          Positioned(
            left: 0,
            right: 0,
            bottom: 210.h,
            child: Center(
              child: GestureDetector(
                onTap: _searchProgramsInCurrentMapArea,
                child: FindInCurrentLocationButton(),
              ),
            ),
          ),
        Positioned(
          right: 20.w,
          bottom: 220.h,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _isLocating ? null : _moveToCurrentLocation,
            child: Container(
              width: 48.w,
              height: 48.w,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10110F).withValues(alpha: 0.1),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: _isLocating
                  ? const CircularProgressIndicator(
                      color: AppColors.gray900,
                      strokeWidth: 2,
                    )
                  : SvgPicture.asset(
                      'assets/icons/mylocation.svg',
                      width: 20.w,
                      colorFilter: const ColorFilter.mode(
                        AppColors.gray900,
                        BlendMode.srcIn,
                      ),
                    ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: _sheetMinSize,
            minChildSize: _sheetMinSize,
            maxChildSize: _sheetMaxSize,
            snap: true,
            snapSizes: const [_sheetMinSize, _sheetMaxSize],
            expand: false,
            builder: (context, scrollController) {
              final visiblePrograms = _selectedProgram == null
                  ? _visiblePrograms
                  : [_selectedProgram!];
              return MapProgramBottomPanel(
                programs: visiblePrograms,
                scrollController: scrollController,
                sheetController: _sheetController,
                minChildSize: _sheetMinSize,
                maxChildSize: _sheetMaxSize,
              );
            },
          ),
        ),
      ],
    );
  }
}

// 클러스터 마커 아이콘 위젯
class _ClusterMarkerIcon extends StatelessWidget {
  final int count;

  const _ClusterMarkerIcon({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: const BoxDecoration(
        color: AppColors.gray900,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: AppTypography.headline1.copyWith(color: AppColors.white),
      ),
    );
  }
}

class _ProgramCluster {
  final List<ProgramModel> programs;

  _ProgramCluster({required this.programs});

  double get latitude {
    final total = programs.fold<double>(
      0,
      (sum, program) => sum + (program.latitude ?? 0),
    );
    return total / programs.length;
  }

  double get longitude {
    final total = programs.fold<double>(
      0,
      (sum, program) => sum + (program.longitude ?? 0),
    );
    return total / programs.length;
  }
}

extension _ProgramMapCoordinates on ProgramModel {
  double? get latitude => double.tryParse(location['latitude'] ?? '');

  double? get longitude => double.tryParse(location['longitude'] ?? '');
}
