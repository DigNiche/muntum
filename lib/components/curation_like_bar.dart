import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muntum/api/api_exception.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';
import 'package:muntum/models/curation_like_model.dart';
import 'package:muntum/services/curation_service.dart';
import 'package:muntum/stores/auth_state.dart';
import 'package:muntum/utils/app_toast.dart';

/// A fixed-footer like control; place outside the page's scrolling content.
class CurationLikeBar extends StatefulWidget {
  /// Creates a footer from a query response, with optional read-only display.
  const CurationLikeBar({
    super.key,
    required this.curationId,
    required this.initialLike,
    required this.service,
    required this.reload,
    this.available = true,
  });

  /// The curation being liked.
  final String curationId;

  /// The latest query response, including the viewer's authenticated state.
  final CurationLikeModel initialLike;

  /// The API dependency shared with the owning page.
  final CurationService service;

  /// Requeries the curation before retrying a CUL004 state conflict.
  final Future<CurationLikeModel> Function() reload;

  /// Whether the query succeeded and the curation is publicly accessible.
  final bool available;

  @override
  State<CurationLikeBar> createState() => _CurationLikeBarState();
}

class _CurationLikeBarState extends State<CurationLikeBar> {
  late CurationLikeModel _like = widget.initialLike;
  bool _busy = false;
  bool _unavailable = false;

  @override
  void didUpdateWidget(CurationLikeBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.curationId != widget.curationId ||
        oldWidget.initialLike != widget.initialLike) {
      _like = widget.initialLike;
      _unavailable = false;
    }
  }

  Future<void> _submit() async {
    if (_busy || _unavailable || !widget.available) return;
    final auth = AuthState.instance;
    if (!auth.isLoggedIn) {
      showAppToast(context, '로그인 후 좋아요를 누를 수 있어요.');
      return;
    }
    if (auth.isAdmin) return;
    // Token refresh keeps the viewer; switching accounts must discard old results.
    final viewerId = auth.userId;
    final desiredLike = !_like.liked;
    setState(() => _busy = true);
    try {
      CurationLikeModel result;
      try {
        result = await widget.service.setLiked(
          widget.curationId,
          liked: desiredLike,
        );
      } on ApiException catch (error) {
        // Retry at most once and keep the original intent (PUT or DELETE).
        if (error.code == 'CUL004') {
          final fresh = await widget.reload();
          if (!mounted || !auth.isLoggedIn || auth.userId != viewerId) return;
          setState(() => _like = fresh);
        } else if (error.code != 'G004') {
          rethrow;
        }
        if (!mounted || !auth.isLoggedIn || auth.userId != viewerId) return;
        result = await widget.service.setLiked(
          widget.curationId,
          liked: desiredLike,
        );
      }
      if (mounted && auth.isLoggedIn && auth.userId == viewerId) {
        setState(() => _like = result);
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      if (['CU001', 'CUL001', 'CUL002', 'CUL003'].contains(error.code)) {
        setState(() => _unavailable = true);
      }
      showAppToast(context, switch (error.code) {
        'CU001' => '삭제되었거나 조회할 수 없는 큐레이션입니다.',
        'CUL001' => '비공개 큐레이션에는 좋아요를 사용할 수 없어요.',
        'CUL002' => '삭제된 프로그램의 큐레이션입니다.',
        'CUL003' => '숨김 처리된 프로그램의 큐레이션입니다.',
        'CUL004' => '글 상태가 변경되었어요. 잠시 후 다시 시도해주세요.',
        'G004' => '요청이 많아요. 잠시 후 다시 시도해주세요.',
        'A005' => '관리자는 좋아요를 누를 수 없어요.',
        _ =>
          error.statusCode == 401
              ? '로그인 후 다시 시도해주세요.'
              : '좋아요를 변경하지 못했어요. 다시 시도해주세요.',
      }, isError: true);
    } catch (_) {
      if (mounted) {
        showAppToast(context, '좋아요를 변경하지 못했어요. 다시 시도해주세요.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AuthState.instance,
    builder: (context, _) {
      final isAdmin = AuthState.instance.isAdmin;
      final liked = AuthState.instance.isLoggedIn && !isAdmin && _like.liked;
      final enabled = widget.available && !_busy && !_unavailable && !isAdmin;
      return Container(
        key: const ValueKey('curation-like-bar'),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.lineNormal)),
        ),
        child: SafeArea(
          top: false,
          minimum: EdgeInsets.only(bottom: 34.h),
          child: SizedBox(
            height: 50.h,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Semantics(
                  button: true,
                  enabled: enabled,
                  toggled: liked,
                  label: '큐레이션 좋아요',
                  child: GestureDetector(
                    key: const ValueKey('curation-like-button'),
                    behavior: HitTestBehavior.opaque,
                    onTap: enabled ? _submit : null,
                    child: SizedBox(
                      height: 48.h,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/heart_${liked ? 'filled' : 'unfilled'}.svg',
                            width: 24.r,
                            height: 24.r,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '${_like.count}',
                            key: const ValueKey('curation-like-count'),
                            style: AppTypography.headline3.copyWith(
                              color: AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
