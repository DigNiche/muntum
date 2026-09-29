import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/filter_chip.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/admin_user_model.dart';
import 'package:muntum/screens/home/components/filter_list.dart';
import 'package:muntum/services/admin_user_service.dart';

enum _UserRoleFilter { all, audience, curator, manager }

enum _JoinedSort { newest, oldest }

class UserManageScreen extends StatefulWidget {
  const UserManageScreen({super.key, this.service});

  final AdminUserService? service;

  @override
  State<UserManageScreen> createState() => _UserManageScreenState();
}

class _UserManageScreenState extends State<UserManageScreen> {
  static const _pageSize = 20;

  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _scrollController = ScrollController();
  late final AdminUserService _service;

  final List<AdminUserModel> _users = [];
  Timer? _searchDebounce;
  int _nextPage = 0;
  int _totalElements = 0;
  bool _hasNext = true;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _requestId = 0;
  bool _searchMode = false;
  _UserRoleFilter _roleFilter = _UserRoleFilter.all;
  _JoinedSort _joinedSort = _JoinedSort.newest;

  bool get _needsAllPages =>
      _roleFilter != _UserRoleFilter.all || _joinedSort == _JoinedSort.oldest;

  List<AdminUserModel> get _visibleUsers {
    final matching = _users
        .where(
          (user) => switch (_roleFilter) {
            _UserRoleFilter.all => true,
            _UserRoleFilter.audience => !user.isCurator && !user.isManager,
            _UserRoleFilter.curator => user.isCurator,
            _UserRoleFilter.manager => user.isManager,
          },
        )
        .toList();
    matching.sort((a, b) => _compareJoined(a.joinedAt, b.joinedAt));
    return matching;
  }

  int _compareJoined(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return _joinedSort == _JoinedSort.oldest ? a.compareTo(b) : b.compareTo(a);
  }

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AdminUserService();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _refreshUsers();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _refreshUsers();
    });
    setState(() {});
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        !_hasNext ||
        _isLoadingMore ||
        _isLoading) {
      return;
    }
    if (_scrollController.position.extentAfter < 240.h) {
      _loadUsers();
    }
  }

  Future<void> _refreshUsers() async {
    await _loadUsers(reset: true);
    if (_needsAllPages) await _loadRemainingUsers();
  }

  Future<void> _loadRemainingUsers() async {
    while (mounted &&
        _hasNext &&
        !_isLoading &&
        !_isLoadingMore &&
        _errorMessage == null) {
      final previousPage = _nextPage;
      await _loadUsers();
      if (_nextPage == previousPage) break;
    }
  }

  Future<void> _loadUsers({bool reset = false}) async {
    if (reset) {
      _requestId += 1;
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _nextPage = 0;
        _hasNext = true;
        _users.clear();
      });
    } else {
      if (_isLoading || _isLoadingMore || !_hasNext) return;
      setState(() => _isLoadingMore = true);
    }

    final requestId = _requestId;

    try {
      final response = await _service.fetchUsers(
        search: _searchController.text,
        page: reset ? 0 : _nextPage,
        size: _needsAllPages ? 100 : _pageSize,
      );
      if (!mounted || requestId != _requestId) return;

      setState(() {
        if (reset) _users.clear();
        _users.addAll(response.content);
        _totalElements = response.totalElements;
        _nextPage = response.page + 1;
        _hasNext = response.hasMore;
        _errorMessage = null;
      });
    } on ApiException catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _errorMessage = '사용자 목록을 불러오지 못했어요.');
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<int?> _showFilterSheet({
    required String title,
    required List<String> labels,
    required int selected,
  }) => showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.dimMedium,
    builder: (sheetContext) => Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.headline1),
          SizedBox(height: 18.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (var i = 0; i < labels.length; i++)
                GestureDetector(
                  onTap: () => Navigator.pop(sheetContext, i),
                  child: FilterChipWidget(
                    text: labels[i],
                    textColor: AppColors.gray900,
                    backgroundColor: AppColors.white,
                    outlineColor: selected == i
                        ? AppColors.gray900
                        : AppColors.lineStrong,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 9.h,
                    ),
                    textStyle: AppTypography.button4,
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _selectRole() async {
    final selected = await _showFilterSheet(
      title: '사용자 유형',
      labels: const ['전체', '일반 사용자', '큐레이터', '관리자'],
      selected: _roleFilter.index,
    );
    if (!mounted || selected == null) return;
    setState(() => _roleFilter = _UserRoleFilter.values[selected]);
    if (_needsAllPages) await _refreshUsers();
  }

  Future<void> _selectSort() async {
    final selected = await _showFilterSheet(
      title: '가입일',
      labels: const ['최신순', '오래된순'],
      selected: _joinedSort.index,
    );
    if (!mounted || selected == null) return;
    setState(() => _joinedSort = _JoinedSort.values[selected]);
    if (_needsAllPages) await _refreshUsers();
  }

  void _openSearch() {
    setState(() => _searchMode = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    _searchFocus.unfocus();
    _searchController.clear();
    _searchDebounce?.cancel();
    setState(() => _searchMode = false);
    _refreshUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNormal,
      body: Column(
        children: [
          ColoredBox(
            color: AppColors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 50.h),
                if (!_searchMode)
                  AppBarWidget(
                    centerType: AppBarCenterType.text,
                    leadingIcon: 'arrow_left.svg',
                    center: '사용자 관리',
                    onLeadingTap: () => Navigator.pop(context),
                    trailing: GestureDetector(
                      key: const ValueKey('user-manage-search-open'),
                      behavior: HitTestBehavior.opaque,
                      onTap: _openSearch,
                      child: SizedBox(
                        width: 24.r,
                        height: 24.r,
                        child: SvgPicture.asset('assets/icons/search.svg'),
                      ),
                    ),
                  ),
                if (_searchMode)
                  Padding(
                    padding: EdgeInsets.fromLTRB(12.w, 6.h, 20.w, 6.h),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _closeSearch,
                          icon: const Icon(Icons.arrow_back_ios_new),
                        ),
                        Expanded(
                          child: _SearchField(
                            controller: _searchController,
                            focusNode: _searchFocus,
                            onClear: () => _searchController.clear(),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!_searchMode)
                  FilterList(
                    verticalPadding: 8,
                    listOfChip: [
                      _FilterButton(
                        label: [
                          '전체',
                          '일반 사용자',
                          '큐레이터',
                          '관리자',
                        ][_roleFilter.index],
                        onTap: _selectRole,
                      ),
                      _FilterButton(
                        label: ['최신 가입순', '오래된순'][_joinedSort.index],
                        onTap: _selectSort,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _users.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gray900),
      );
    }

    if (_errorMessage != null && _users.isEmpty) {
      return _MessageState(
        message: _errorMessage!,
        buttonText: '다시 시도',
        onTap: _refreshUsers,
      );
    }

    if (_users.isEmpty) {
      return const _MessageState(message: '검색된 사용자가 없어요.');
    }

    final visibleUsers = _visibleUsers;
    if (visibleUsers.isEmpty && !_hasNext && !_isLoadingMore) {
      return const _MessageState(message: '해당하는 사용자가 없어요.');
    }

    return RefreshIndicator(
      color: AppColors.gray900,
      onRefresh: _refreshUsers,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 40.h),
        itemCount: visibleUsers.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Text(
                '${_roleFilter == _UserRoleFilter.all ? _totalElements : visibleUsers.length}명',
                style: AppTypography.caption1.copyWith(
                  color: AppColors.gray600,
                ),
              ),
            );
          }
          if (index == visibleUsers.length + 1) {
            return _isLoadingMore
                ? Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.gray900,
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          }
          final user = visibleUsers[index - 1];
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _UserListItem(
              user: user,
              onTap: () => showModalBottomSheet<void>(
                context: context,
                barrierColor: AppColors.dimMedium,
                backgroundColor: Colors.transparent,
                builder: (_) => _UserProfileSheet(user: user),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52.h,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.search,
        cursorColor: AppColors.gray900,
        style: AppTypography.body1.copyWith(color: AppColors.gray900),
        decoration: InputDecoration(
          hintText: '닉네임 또는 이메일로 검색하기',
          hintStyle: AppTypography.body1.copyWith(color: AppColors.gray400),
          prefixIcon: Padding(
            padding: EdgeInsets.all(15.r),
            child: SvgPicture.asset(
              'assets/icons/search.svg',
              width: 22.r,
              height: 22.r,
              colorFilter: const ColorFilter.mode(
                AppColors.gray900,
                BlendMode.srcIn,
              ),
            ),
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : GestureDetector(
                  onTap: onClear,
                  child: Padding(
                    padding: EdgeInsets.all(16.r),
                    child: SvgPicture.asset(
                      'assets/icons/circle_close.svg',
                      width: 20.r,
                      height: 20.r,
                    ),
                  ),
                ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(color: AppColors.lineStrong, width: 1.w),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(color: AppColors.gray400, width: 1.w),
          ),
        ),
      ),
    );
  }
}

class _UserListItem extends StatelessWidget {
  const _UserListItem({required this.user, required this.onTap});

  final AdminUserModel user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        key: ValueKey('user-card-${user.userId}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: SizedBox(
          height: 82.h,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                _UserAvatar(user: user, size: 40.r),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headline3.copyWith(
                          color: AppColors.gray900,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        user.email.isEmpty ? user.accountLabel : user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption2.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user, required this.size});

  final AdminUserModel user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(
      'assets/default_profile_img.jpg',
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
    return SizedBox(
      width: size + 2.r,
      height: size + 2.r,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: user.profileImageUrl == null
                ? fallback
                : Image.network(
                    user.profileImageUrl!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => fallback,
                  ),
          ),
          if (user.isCurator || user.isManager)
            Positioned(
              right: 0,
              bottom: 0,
              child: SvgPicture.asset(
                user.isManager
                    ? 'assets/icons/manager_badge.svg'
                    : 'assets/icons/curator_badge.svg',
                key: ValueKey('user-role-badge-${user.userId}'),
                width: 16.r,
                height: 16.r,
              ),
            ),
        ],
      ),
    );
  }
}

class _UserProfileSheet extends StatelessWidget {
  const _UserProfileSheet({required this.user});

  final AdminUserModel user;

  @override
  Widget build(BuildContext context) {
    final stats = <(String, String)>[
      ('스크랩', '${user.scrapCount}'),
      ('제보', '${user.suggestionCount}'),
      if (user.isCurator || user.isManager) ('작성글', '-'),
    ];
    return Container(
      key: const ValueKey('user-profile-sheet'),
      width: double.infinity,
      height: 330.h,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 28.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '가입일: ${user.formattedJoinedAt}',
                style: AppTypography.caption2.copyWith(
                  color: AppColors.gray500,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            _UserAvatar(user: user, size: 56.r),
            SizedBox(height: 16.h),
            Text(
              user.displayName,
              style: AppTypography.title4.copyWith(color: AppColors.gray900),
            ),
            SizedBox(height: 4.h),
            Text(
              user.accountLabel,
              style: AppTypography.body3.copyWith(color: AppColors.gray600),
            ),
            SizedBox(height: 24.h),
            Container(
              height: 56.h,
              decoration: BoxDecoration(
                color: AppColors.backgroundNormal,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    if (i > 0)
                      SizedBox(
                        height: 20.h,
                        child: VerticalDivider(
                          width: 1.w,
                          thickness: 1.w,
                          color: AppColors.lineStrong,
                        ),
                      ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '${stats[i].$1} ${stats[i].$2}',
                          style: AppTypography.caption1.copyWith(
                            color: AppColors.gray900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: FilterChipWidget(
      text: label,
      textColor: AppColors.gray900,
      backgroundColor: AppColors.white,
      outlineColor: AppColors.lineStrong,
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 8.h),
      textStyle: AppTypography.button4,
      trailing: Icon(
        Icons.keyboard_arrow_down,
        size: 15.r,
        color: AppColors.gray500,
      ),
    ),
  );
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message, this.buttonText, this.onTap});

  final String message;
  final String? buttonText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body2.copyWith(color: AppColors.gray500),
          ),
          if (buttonText != null && onTap != null) ...[
            SizedBox(height: 16.h),
            TextButton(
              onPressed: onTap,
              child: Text(
                buttonText!,
                style: AppTypography.button2.copyWith(color: AppColors.gray900),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
