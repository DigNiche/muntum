import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/border_radius.dart';
import 'package:muntum/constants/colors.dart';

class ProgramPosterCarousel extends StatefulWidget {
  final List<Image> images;

  const ProgramPosterCarousel({super.key, required this.images});

  @override
  State<ProgramPosterCarousel> createState() => _ProgramPosterCarouselState();
}

class _ProgramPosterCarouselState extends State<ProgramPosterCarousel> {
  final PageController _controller = PageController(initialPage: 1);
  int _currentIndex = 0;
  int? _pendingJumpPage;

  @override
  void didUpdateWidget(covariant ProgramPosterCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images.length == widget.images.length) return;

    _currentIndex = 0;
    _pendingJumpPage = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.hasClients) {
        _controller.jumpToPage(1);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppBorderRadius.radius_10),
          child: SizedBox(
            width: 350.w,
            height: 467.h,
            child: NotificationListener<ScrollEndNotification>(
              onNotification: (_) {
                final jumpPage = _pendingJumpPage;
                if (jumpPage == null) return false;
                _pendingJumpPage = null;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_controller.hasClients) {
                    _controller.jumpToPage(jumpPage);
                  }
                });
                return false;
              },
              child: PageView.builder(
                controller: _controller,
                physics: widget.images.length <= 1
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                itemCount: widget.images.length > 1
                    ? widget.images.length + 2
                    : 3,
                onPageChanged: _onPageChanged,
                itemBuilder: _buildPoster,
              ),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            widget.images.isEmpty ? 1 : widget.images.length,
            (index) {
              final isSelected = _currentIndex == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                width: 7.w,
                height: 7.w,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.black : AppColors.gray300,
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _onPageChanged(int index) {
    final imageCount = widget.images.length;
    final actualIndex = imageCount <= 1
        ? 0
        : index == 0
        ? imageCount - 1
        : index == imageCount + 1
        ? 0
        : index - 1;

    setState(() {
      _currentIndex = actualIndex;
    });
    _pendingJumpPage = imageCount > 1
        ? index == 0
              ? imageCount
              : index == imageCount + 1
              ? 1
              : null
        : null;
  }

  Widget _buildPoster(BuildContext context, int index) {
    if (widget.images.isEmpty) {
      return const ColoredBox(color: Color(0xff9DB6BE));
    }
    if (widget.images.length == 1) {
      return widget.images.first;
    }
    final imageIndex = index == 0
        ? widget.images.length - 1
        : index == widget.images.length + 1
        ? 0
        : index - 1;
    return widget.images[imageIndex];
  }
}
