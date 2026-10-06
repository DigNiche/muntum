import 'package:flutter/services.dart';

final _introductionLineBreaks = RegExp(
  r'[ \t]*[\r\n\u2028\u2029][\r\n\u2028\u2029 \t]*',
);

final singleLineIntroductionFormatter = FilteringTextInputFormatter(
  _introductionLineBreaks,
  allow: false,
  replacementString: ' ',
);

/// Keep words separated when a multiline introduction is sent as one line.
String singleLineIntroduction(String text) =>
    text.replaceAll(_introductionLineBreaks, ' ').trim();
