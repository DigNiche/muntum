import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/components/appbar.dart';
import 'package:muntum/components/content_skeleton.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/services/terms_service.dart';
import 'package:muntum/utils/app_toast.dart';
import 'package:url_launcher/url_launcher.dart';

/// Displays versioned service terms and the app's supplied privacy notice.
class TermsDetailScreen extends StatefulWidget {
  /// Creates the shared document reader.
  const TermsDetailScreen({
    super.key,
    required this.title,
    this.content,
    this.service,
    this.termType,
  });

  /// The reader title, also used by the existing terms menu.
  final String title;

  /// The exact versioned content; privacy uses the supplied app notice instead.
  final String? content;

  /// The injectable terms service for entries from the existing terms menu.
  final TermsService? service;

  /// Identifies documents even when the server changes their display title.
  final String? termType;

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
    if (widget.termType == 'PRIVACY_POLICY' ||
        widget.title.replaceAll(' ', '') == '개인정보처리방침') {
      // Privacy is a notice, not a submitted agreement or invented API version.
      return rootBundle.loadString('assets/documents/privacy_policy.md');
    }
    if (widget.content != null) return widget.content!;
    final documents = await (widget.service ?? TermsService()).fetchActive();
    final type =
        widget.termType ??
        (widget.title == '서비스 이용약관' ? 'TERMS_OF_SERVICE' : null);
    for (final document in documents) {
      if (document.type == type || document.title == widget.title) {
        return document.content;
      }
    }
    throw const FormatException('현재 게시된 약관이 없습니다.');
  }

  Future<void> _openLink(String text, String? href, String title) async {
    if (href == null) return;
    final uri = Uri.tryParse(href);
    if (uri == null || !{'https', 'http', 'mailto'}.contains(uri.scheme)) {
      return;
    }
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } on Exception {
      // Keep the document readable if no browser or mail app is available.
    }
    if (mounted) {
      showAppToast(context, '링크를 열지 못했어요. 다시 시도해주세요.', isError: true);
    }
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
                child: MarkdownBody(data: snapshot.data!, onTapLink: _openLink),
              );
            },
          ),
        ),
      ],
    ),
  );
}
