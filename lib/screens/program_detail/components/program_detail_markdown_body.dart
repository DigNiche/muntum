import 'package:flutter/cupertino.dart' as legacy_cupertino;
import 'package:flutter/material.dart' as legacy_material;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/constants/colors.dart';
import 'package:muntum/constants/typography.dart';

class ProgramDetailMarkdownBody extends StatelessWidget {
  final String markdown;
  final ValueChanged<String> onTapLink;

  const ProgramDetailMarkdownBody({
    super.key,
    required this.markdown,
    required this.onTapLink,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedMarkdown = markdown.replaceAll(
      RegExp(r'\n\s*---\s*\n'),
      '\n\n',
    );
    final fixedMarkdown = _fixCjkEmphasis(normalizedMarkdown);
    final pointTitleMatch = RegExp(
      r'(^|\n).*프로그램 포인트.*',
      multiLine: true,
    ).firstMatch(fixedMarkdown);
    final markdownTheme = _markdownTheme(context);
    final styleSheet = _styleSheet(markdownTheme);
    final Widget content;

    if (pointTitleMatch == null || pointTitleMatch.start <= 0) {
      content = _buildMarkdown(fixedMarkdown, styleSheet);
    } else {
      final afterStart = fixedMarkdown.codeUnitAt(pointTitleMatch.start) == 10
          ? pointTitleMatch.start + 1
          : pointTitleMatch.start;
      final before = fixedMarkdown.substring(0, afterStart).trimRight();
      final after = fixedMarkdown.substring(afterStart).trimLeft();

      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (before.isNotEmpty) _buildMarkdown(before, styleSheet),
          SizedBox(height: 28.h),
          _buildMarkdown(after, styleSheet),
        ],
      );
    }

    // flutter_markdown still uses Flutter's built-in design widgets. Keep this
    // compatibility boundary local until the package migrates to material_ui.
    return legacy_material.Theme(
      data: markdownTheme,
      child: legacy_cupertino.CupertinoTheme(
        data: legacy_cupertino.CupertinoTheme.of(
          context,
        ).copyWith(primaryColor: AppColors.black),
        child: legacy_material.TextSelectionTheme(
          data: legacy_material.TextSelectionThemeData(
            cursorColor: AppColors.black,
            selectionColor: AppColors.black.withValues(alpha: 0.18),
            selectionHandleColor: AppColors.black,
          ),
          child: content,
        ),
      ),
    );
  }

  MarkdownBody _buildMarkdown(String data, MarkdownStyleSheet styleSheet) {
    return MarkdownBody(
      data: data,
      selectable: true,
      onTapLink: (text, href, title) => onTapLink(href ?? ''),
      styleSheet: styleSheet,
    );
  }

  legacy_material.ThemeData _markdownTheme(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    return legacy_material.ThemeData(
      brightness: theme.brightness,
      useMaterial3: theme.useMaterial3,
      primaryColor: theme.primaryColor,
      dividerColor: theme.dividerColor,
      cardColor: theme.cardColor,
      cardTheme: legacy_material.CardThemeData(color: theme.cardTheme.color),
      textTheme: legacy_material.TextTheme(
        bodyMedium: text.bodyMedium,
        bodyLarge: text.bodyLarge,
        headlineSmall: text.headlineSmall,
        titleLarge: text.titleLarge,
        titleMedium: text.titleMedium,
      ),
    );
  }

  MarkdownStyleSheet _styleSheet(legacy_material.ThemeData theme) {
    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: AppTypography.body1.copyWith(color: AppColors.gray900),
      strong: AppTypography.body1.copyWith(
        color: AppColors.gray900,
        fontWeight: FontWeight.w700,
      ),
      listBullet: AppTypography.body1.copyWith(color: AppColors.gray900),
      h1: AppTypography.title1.copyWith(color: AppColors.gray900),
      h2: AppTypography.title3.copyWith(color: AppColors.gray900),
      h3: AppTypography.title4.copyWith(color: AppColors.gray900),
      a: AppTypography.body1.copyWith(decoration: TextDecoration.underline),
    );
  }

  String _fixCjkEmphasis(String markdown) {
    return markdown
        .replaceAllMapped(
          RegExp(r'([\p{P}\p{S}])\*\*(?=[가-힣])', unicode: true),
          (match) => '${match.group(1)}**\u200B',
        )
        .replaceAllMapped(
          RegExp(r'([가-힣])\*\*([\p{P}\p{S}])', unicode: true),
          (match) => '${match.group(1)}\u200B**${match.group(2)}',
        );
  }
}
