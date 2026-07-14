import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/admin_user_model.dart';
import 'package:muntum/services/admin_user_service.dart';

class UserManageScreen extends StatefulWidget {
  const UserManageScreen({super.key});

  @override
  State<UserManageScreen> createState() => _UserManageScreenState();
}

class _UserManageScreenState extends State<UserManageScreen> {
  static const _pageSize = 20;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _service = AdminUserService();

  final List<AdminUserModel> _users = [];
  Timer? _searchDebounce;
  int _nextPage = 0;
  int _totalElements = 0;
  bool _hasNext = true;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _loadUsers(reset: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _loadUsers(reset: true);
    });
    setState(() {});
  }

  void _onScroll() {
    if (!_scrollController.hasClients || !_hasNext || _isLoadingMore) return;
    if (_scrollController.position.extentAfter < 240.h) {
      _loadUsers();
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
        size: _pageSize,
      );
      if (!mounted || requestId != _requestId) return;

      setState(() {
        if (reset) _users.clear();
        _users.addAll(response.content);
        _totalElements = response.totalElements;
        _nextPage = response.page + 1;
        _hasNext = response.hasNext || !response.last;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          SizedBox(height: 50.h),
          AppBarWidget(
            centerType: AppBarCenterType.text,
            leadingIcon: 'arrow_left.svg',
            center: '사용자 관리',
            onLeadingTap: () => Navigator.pop(context),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
            child: _SearchField(
              controller: _searchController,
              onClear: () => _searchController.clear(),
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
        onTap: () => _loadUsers(reset: true),
      );
    }

    if (_users.isEmpty) {
      return const _MessageState(message: '검색된 사용자가 없어요.');
    }

    return RefreshIndicator(
      color: AppColors.gray900,
      onRefresh: () => _loadUsers(reset: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 40.h),
        itemCount: _users.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Text(
              '$_totalElements명',
              style: AppTypography.headline2.copyWith(color: AppColors.gray500),
            );
          }
          if (index == _users.length + 1) {
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
          return _UserListItem(user: _users[index - 1]);
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onClear});

  final TextEditingController controller;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52.h,
      child: TextField(
        controller: controller,
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
  const _UserListItem({required this.user});

  final AdminUserModel user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.lineNormal, width: 1.h),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 39.r,
                height: 39.r,
                child: SvgPicture.asset('assets/profile_image.svg'),
              ),
              SizedBox(width: 11.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headline1.copyWith(
                        color: AppColors.gray900,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      user.accountLabel,
                      style: AppTypography.caption2.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Text(
                '가입일   ${user.formattedJoinedAt}',
                style: AppTypography.caption2.copyWith(
                  color: AppColors.gray700,
                ),
              ),
              const Spacer(),
              Text(
                '제보 ${user.suggestionCount}   스크랩 ${user.scrapCount}',
                style: AppTypography.caption2.copyWith(
                  color: AppColors.gray700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
