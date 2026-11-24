import 'package:material_ui/material_ui.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/content_skeleton.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/services/terms_service.dart';

/// Displays the server's terms, or the exact document shown during consent.
class TermsDetailScreen extends StatefulWidget {
  /// Creates the shared document reader.
  const TermsDetailScreen({
    super.key,
    required this.title,
    this.content,
    this.service,
  });

  /// The reader title, also used by the existing terms menu.
  final String title;

  /// The exact published content retained while deciding on its version.
  final String? content;

  /// The injectable terms service for entries from the existing terms menu.
  final TermsService? service;

  @override
  State<TermsDetailScreen> createState() => _TermsDetailScreenState();
}

class _TermsDetailScreenState extends State<TermsDetailScreen> {
  late Future<String> _content;

  @override
  void initState() {
    super.initState();
    _content = _loadContent();
  }

  Future<String> _loadContent() async {
    if (widget.content != null) return widget.content!;
    final documents = await (widget.service ?? TermsService()).fetchActive();
    final type = widget.title == '서비스 이용약관'
        ? 'TERMS_OF_SERVICE'
        : widget.title == '개인정보 처리방침'
        ? 'PRIVACY_POLICY'
        : null;
    for (final document in documents) {
      if (document.type == type || document.title == widget.title) {
        return document.content;
      }
    }
    throw const FormatException('현재 게시된 약관이 없습니다.');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.white,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 50.h),
        AppBarWidget(
          centerType: AppBarCenterType.text,
          leadingIcon: 'arrow_left.svg',
          center: widget.title,
          onLeadingTap: () => Navigator.pop(context),
        ),
        Expanded(
          child: FutureBuilder<String>(
            future: _content,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const PageLoadingSkeleton.detail();
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('게시된 약관을 불러오지 못했어요.'),
                      TextButton(
                        onPressed: () =>
                            setState(() => _content = _loadContent()),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                );
              }
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20.w,
                  10.h,
                  20.w,
                  48.h + MediaQuery.paddingOf(context).bottom,
                ),
                child: MarkdownBody(data: snapshot.data!),
              );
            },
          ),
        ),
      ],
    ),
  );
}
