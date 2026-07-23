import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/components/filter_chip.dart';
import 'package:muntum/components/popup_widget.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/home/components/searchbar.dart';
import 'package:muntum/screens/home/search_screen.dart';
import 'package:muntum/screens/map/components/findin_current_location.dart';
import 'package:muntum/screens/map/components/map_bottom_sheet.dart';
import 'package:muntum/screens/map/map_clustering.dart';
import 'package:muntum/screens/map/map_location_overlay_controller.dart';
import 'package:muntum/screens/map/map_location_service.dart';
import 'package:muntum/screens/map/map_marker_icon_cache.dart';
import 'package:muntum/screens/map/map_program_repository.dart';
import 'package:muntum/screens/map/map_viewport.dart';
import 'package:muntum/utils/app_toast.dart';

class MapScreen extends StatefulWidget {
  final bool isActive;

  const MapScreen({super.key, this.isActive = true});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _searchbarController = TextEditingController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  List<ProgramModel> _mapPrograms = [];
  List<ProgramModel> _visiblePrograms = [];
  Filter? _selectedFilter;
  ProgramModel? _selectedProgram;
  NaverMapController? _mapController;
  NLatLng? _currentLocation;
  NLatLng? _initialMapCenter;
  final Map<String, NMarker> _programMarkerRefs = {};
  final MapClusteringController _clusteringController =
      MapClusteringController();
  final MapLocationService _locationService = MapLocationService();
  final MapLocationOverlayController _locationOverlayController =
      MapLocationOverlayController();
  final MapMarkerIconCache _markerIconCache = MapMarkerIconCache();
  final MapProgramRepository _programRepository = MapProgramRepository();
  Future<void> _markerRefreshQueue = Future<void>.value();
  double? _renderedClusterThresholdMeters;

  bool _locationInitializationStarted = false;
  bool _initialLocationResolved = false;
  bool _isLocating = false;
  bool _isSearchingCurrentArea = false;
  bool _isLocationPermissionPopupVisible = false;
  int _markerRefreshGeneration = 0;
  int _selectionGeneration = 0;

  static const double _sheetMinSize = 0.26;
  static const double _sheetMaxSize = 0.78;
  static const double _searchRadiusMeters = 5000;
  static const double _initialZoom = 12.2;
  static const NLatLng _yongsanStationInitialTarget = NLatLng(
    37.529849,
    126.964561,
  );

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
      _locationOverlayController.startPulse(_mapController);
    } else if (oldWidget.isActive && !widget.isActive) {
      _locationOverlayController.stopPulse();
    }
  }

  Future<void> _initializeCurrentLocation() async {
    if (_locationInitializationStarted) {
      return;
    }
    _locationInitializationStarted = true;
    _setLocating(true);

    NLatLng initialCenter = _yongsanStationInitialTarget;
    String? errorMessage;
    var permissionDenied = false;

    try {
      final position = await _locationService.determineCurrentPosition();
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

  void _openSearchScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchScreen()),
    );
  }

  Future<void> _toggleMapFilter(Filter filter) async {
    setState(() {
      _selectedFilter = _selectedFilter == filter ? null : filter;
      _searchbarController.clear();
    });
    await _refreshAtCurrentMapCenter();
  }

  Future<void> _refreshAtCurrentMapCenter() async {
    final controller = _mapController;
    if (controller == null) {
      return;
    }
    await _refreshVisibleProgramsAndMarkers(controller);
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
        outlineColor: isSelected ? AppColors.gray900 : Colors.transparent,
      ),
    );
  }

  String _markerIdFor(ProgramModel program) {
    return 'program_${_mapPrograms.indexOf(program) + 1}';
  }

  String _programSelectionKey(ProgramModel program) {
    final id = program.id.trim();
    return id.isNotEmpty ? id : _markerIdFor(program);
  }

  Future<void> _searchProgramsInCurrentMapArea() async {
    final controller = _mapController;
    if (controller == null || _isSearchingCurrentArea) {
      return;
    }

    final previouslySelectedProgram = _selectedProgram;
    setState(() {
      _isSearchingCurrentArea = true;
      if (previouslySelectedProgram != null) {
        _selectedProgram = null;
        _selectionGeneration++;
      }
      _showSearchHereButton = true;
    });
    if (previouslySelectedProgram != null) {
      unawaited(
        _setProgramMarkerSelected(previouslySelectedProgram, isSelected: false),
      );
    }

    try {
      await _refreshVisibleProgramsAndMarkers(controller);
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingCurrentArea = false;
          _showSearchHereButton = false;
        });
      }
    }
  }

  Future<void> _moveToCurrentLocation() async {
    final controller = _mapController;
    if (controller == null || _isLocating) {
      return;
    }

    _setLocating(true);
    try {
      final position = await _locationService.determineCurrentPosition();
      if (!mounted) {
        return;
      }

      final currentLocation = NLatLng(position.latitude, position.longitude);
      _currentLocation = currentLocation;
      await _locationOverlayController.update(
        context: context,
        mapController: controller,
        location: currentLocation,
        isActive: widget.isActive,
      );
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

  Future<void> _focusOnSearchRadiusAndRefresh(
    NaverMapController controller,
    NLatLng center, {
    required bool animated,
  }) async {
    final cameraUpdate = NCameraUpdate.fitBounds(
      boundsAround(center, _searchRadiusMeters),
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
    await _refreshVisibleProgramsAndMarkers(
      controller,
      nearbyCenter: _selectedFilter == null ? center : null,
    );
  }

  Future<void> _refreshVisibleProgramsAndMarkers(
    NaverMapController controller, {
    NLatLng? nearbyCenter,
  }) async {
    final requestGeneration = ++_markerRefreshGeneration;
    final previousRefresh = _markerRefreshQueue;
    final refresh = () async {
      await previousRefresh;
      if (!mounted || requestGeneration != _markerRefreshGeneration) {
        return;
      }
      await _performMarkerRefresh(controller, nearbyCenter: nearbyCenter);
    }();

    _markerRefreshQueue = refresh.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    await refresh;
  }

  Future<void> _performMarkerRefresh(
    NaverMapController controller, {
    NLatLng? nearbyCenter,
  }) async {
    final visiblePrograms = nearbyCenter == null
        ? await _programRepository.fetchInBounds(
            bounds: await controller.getContentBounds(withPadding: false),
            filter: _selectedFilter,
          )
        : await _programRepository.fetchNearby(
            center: nearbyCenter,
            radiusMeters: _searchRadiusMeters,
          );
    _mapPrograms = visiblePrograms;
    _clusteringController.clearSpiderfiedPrograms();
    final cameraPosition = await controller.getCameraPosition();
    await _renderProgramMarkers(
      controller,
      visiblePrograms,
      cameraPosition.zoom,
      updateProgramList: true,
    );
  }

  Future<void> _refreshClustersFromCache({bool force = false}) async {
    final controller = _mapController;
    if (controller == null || _mapPrograms.isEmpty) {
      return;
    }

    final currentCameraPosition = await controller.getCameraPosition();
    if (!force &&
        _renderedClusterThresholdMeters ==
            _clusteringController.thresholdMetersForZoom(
              currentCameraPosition.zoom,
            )) {
      return;
    }

    final requestGeneration = ++_markerRefreshGeneration;
    final previousRefresh = _markerRefreshQueue;
    final refresh = () async {
      await previousRefresh;
      if (!mounted || requestGeneration != _markerRefreshGeneration) {
        return;
      }
      final cameraPosition = await controller.getCameraPosition();
      final nextClusterThreshold = _clusteringController.thresholdMetersForZoom(
        cameraPosition.zoom,
      );
      if (!force && _renderedClusterThresholdMeters == nextClusterThreshold) {
        return;
      }
      if (_renderedClusterThresholdMeters != null &&
          nextClusterThreshold > _renderedClusterThresholdMeters!) {
        _clusteringController.clearSpiderfiedPrograms();
      }
      await _renderProgramMarkers(
        controller,
        List<ProgramModel>.from(_mapPrograms),
        cameraPosition.zoom,
        updateProgramList: false,
      );
    }();

    _markerRefreshQueue = refresh.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    await refresh;
  }

  Future<void> _renderProgramMarkers(
    NaverMapController controller,
    List<ProgramModel> programs,
    double zoom, {
    required bool updateProgramList,
  }) async {
    final selectionGeneration = _selectionGeneration;
    final previouslySelectedProgramKey = _selectedProgram == null
        ? null
        : _programSelectionKey(_selectedProgram!);
    final clusters = _clusteringController.clusterPrograms(
      programs,
      zoom,
      keyFor: _programSelectionKey,
    );
    final spiderfiedMarkerPositions = _clusteringController
        .spiderfiedMarkerPositions(
          clusters,
          zoom,
          keyFor: _programSelectionKey,
        );
    final markers = <NMarker>{};
    final programMarkerRefs = <String, NMarker>{};
    final singleMarkerPrograms = <ProgramModel>[];

    for (final cluster in clusters) {
      if (!mounted) {
        return;
      }
      final isCluster = cluster.programs.length > 1;
      final markerId = isCluster
          ? 'cluster_${cluster.programs.map(_markerIdFor).join('_')}'
          : _markerIdFor(cluster.programs.first);

      final isSelectedSingleMarker =
          !isCluster &&
          _programSelectionKey(cluster.programs.first) ==
              previouslySelectedProgramKey;

      late final NOverlayImage markerIcon;
      if (isCluster) {
        if (!context.mounted) return;
        markerIcon = await _markerIconCache.clusterIcon(
          context: context,
          count: cluster.programs.length,
        );
      } else {
        if (!context.mounted) return;
        markerIcon = await _markerIconCache.programIcon(
          context: context,
          program: cluster.programs.first,
          programKey: _programSelectionKey(cluster.programs.first),
          isSelected: isSelectedSingleMarker,
        );
      }
      final marker = NMarker(
        id: markerId,
        position: isCluster
            ? NLatLng(cluster.latitude, cluster.longitude)
            : spiderfiedMarkerPositions[_programSelectionKey(
                    cluster.programs.first,
                  )] ??
                  NLatLng(cluster.latitude, cluster.longitude),
        icon: markerIcon,
      );
      if (!isCluster) {
        singleMarkerPrograms.add(cluster.programs.first);
        programMarkerRefs[_programSelectionKey(cluster.programs.first)] =
            marker;
        if (mounted) {
          unawaited(
            _markerIconCache.programIcon(
              context: context,
              program: cluster.programs.first,
              programKey: _programSelectionKey(cluster.programs.first),
              isSelected: !isSelectedSingleMarker,
            ),
          );
        }
      }

      marker.setOnTapListener((overlay) {
        if (!mounted) {
          return;
        }
        final previousSelectedProgram = _selectedProgram;
        final tappedProgram = isCluster ? null : cluster.programs.first;
        final shouldDeselect =
            !isCluster && tappedProgram?.id == _selectedProgram?.id;
        final shouldSpiderfy =
            isCluster && _clusteringController.shouldSpiderfy(cluster.programs);
        setState(() {
          _selectionGeneration++;
          if (isCluster) {
            _clusteringController.clearSpiderfiedPrograms();
            if (shouldSpiderfy) {
              _clusteringController.spiderfyPrograms(
                cluster.programs,
                keyFor: _programSelectionKey,
              );
            }
          }
          _selectedProgram = shouldDeselect ? null : tappedProgram;
          _visiblePrograms = shouldDeselect ? programs : cluster.programs;
          _showSearchHereButton = false;
        });
        if (!isCluster) {
          unawaited(
            _applyImmediateMarkerSelection(
              previousSelectedProgram: previousSelectedProgram,
              currentProgram: tappedProgram!,
              isCurrentSelected: !shouldDeselect,
            ),
          );
        }

        unawaited(
          _focusOnMarker(
            controller,
            NLatLng(cluster.latitude, cluster.longitude),
            zoomIn: isCluster,
            clusteredPrograms: isCluster
                ? List<ProgramModel>.from(cluster.programs)
                : const [],
            spiderfyCluster: shouldSpiderfy,
          ),
        );

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
    if (selectionGeneration != _selectionGeneration) {
      unawaited(_refreshClustersFromCache());
      return;
    }
    await controller.clearOverlays(type: NOverlayType.marker);
    if (markers.isNotEmpty) {
      await controller.addOverlayAll(markers);
    }
    if (!mounted) {
      return;
    }

    _programMarkerRefs
      ..clear()
      ..addAll(programMarkerRefs);
    _renderedClusterThresholdMeters = _clusteringController
        .thresholdMetersForZoom(zoom);
    for (final program in singleMarkerPrograms) {
      unawaited(_loadAndApplyProgramMarkerImage(program));
    }

    setState(() {
      if (updateProgramList) {
        final selectedProgram = _selectedProgram;
        if (selectedProgram != null &&
            !programs.any(
              (program) =>
                  _programSelectionKey(program) ==
                  _programSelectionKey(selectedProgram),
            )) {
          _selectedProgram = null;
        }
        _visiblePrograms = programs;
        _showSearchHereButton = _isSearchingCurrentArea;
      }
    });

    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        _sheetMinSize,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _focusOnMarker(
    NaverMapController controller,
    NLatLng target, {
    required bool zoomIn,
    required List<ProgramModel> clusteredPrograms,
    required bool spiderfyCluster,
  }) async {
    final cameraPosition = await controller.getCameraPosition();
    final cameraUpdate = zoomIn
        ? _clusteringController.cameraUpdateForCluster(
            clusteredPrograms,
            cameraPosition.zoom,
            spiderfyCluster: spiderfyCluster,
          )
        : NCameraUpdate.scrollAndZoomTo(
            target: target,
            zoom: cameraPosition.zoom,
          );
    cameraUpdate.setAnimation(
      animation: NCameraAnimation.easing,
      duration: Duration(milliseconds: zoomIn ? 650 : 350),
    );
    await controller.updateCamera(cameraUpdate);
    if (zoomIn && mounted) {
      await _refreshClustersFromCache(force: true);
    }
  }

  Future<void> _clearSelectedProgram() async {
    final selectedProgram = _selectedProgram;
    if (selectedProgram == null) {
      return;
    }

    setState(() {
      _selectionGeneration++;
      _selectedProgram = null;
      _visiblePrograms = _mapPrograms;
    });
    await _setProgramMarkerSelected(selectedProgram, isSelected: false);
  }

  Future<void> _applyImmediateMarkerSelection({
    required ProgramModel? previousSelectedProgram,
    required ProgramModel currentProgram,
    required bool isCurrentSelected,
  }) async {
    if (previousSelectedProgram != null &&
        _programSelectionKey(previousSelectedProgram) !=
            _programSelectionKey(currentProgram)) {
      await _setProgramMarkerSelected(
        previousSelectedProgram,
        isSelected: false,
      );
    }
    await _setProgramMarkerSelected(
      currentProgram,
      isSelected: isCurrentSelected,
    );
  }

  Future<void> _setProgramMarkerSelected(
    ProgramModel program, {
    required bool isSelected,
  }) async {
    final marker = _programMarkerRefs[_programSelectionKey(program)];
    if (marker == null || !mounted) {
      return;
    }
    final icon = await _markerIconCache.programIcon(
      context: context,
      program: program,
      programKey: _programSelectionKey(program),
      isSelected: isSelected,
    );
    if (!mounted) {
      return;
    }
    final selectedProgram = _selectedProgram;
    final isActuallySelected =
        selectedProgram != null &&
        _programSelectionKey(selectedProgram) == _programSelectionKey(program);
    if (isSelected != isActuallySelected) {
      return;
    }
    marker.setIcon(icon);
  }

  Future<void> _loadAndApplyProgramMarkerImage(ProgramModel program) async {
    if (!mounted || program.imageUrls.isEmpty) {
      return;
    }
    final didLoad = await _markerIconCache.loadProgramImage(
      context: context,
      program: program,
      isActive: () => mounted,
    );
    if (!mounted || !didLoad) {
      return;
    }
    final selectedProgram = _selectedProgram;
    final isSelected =
        selectedProgram != null &&
        _programSelectionKey(selectedProgram) == _programSelectionKey(program);
    await _setProgramMarkerSelected(program, isSelected: isSelected);
  }

  @override
  void dispose() {
    _locationOverlayController.dispose();
    _markerIconCache.dispose();
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
              await _locationOverlayController.update(
                context: context,
                mapController: controller,
                location: currentLocation,
                isActive: widget.isActive,
              );
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
          onCameraIdle: () {
            unawaited(_refreshClustersFromCache());
          },
          onMapTapped: (point, latLng) {
            unawaited(_clearSelectedProgram());
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
                readOnly: true,
                onTap: _openSearchScreen,
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                spacing: 6.w,
                children: [
                  _buildMapFilterChip(Filter.nowHot, '🔥지금핫한'),
                  _buildMapFilterChip(Filter.free, '무료'),
                  _buildMapFilterChip(Filter.thisWeek, '이번주'),
                  _buildMapFilterChip(Filter.noReservation, '예약없이'),
                  ...ProgramType.values.map(
                    (type) => _buildMapFilterChip(type.filter, type.label),
                  ),
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
                onTap: _isSearchingCurrentArea
                    ? null
                    : _searchProgramsInCurrentMapArea,
                child: FindInCurrentLocationButton(
                  isLoading: _isSearchingCurrentArea,
                ),
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
                      width: 20.r,
                      height: 20.r,
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
