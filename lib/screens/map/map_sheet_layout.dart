import 'package:flutter/widgets.dart';

/// All overlays use the sheet's actual parent height, including SDK padding.
class MapSheetLayout {
  const MapSheetLayout({
    required this.viewportHeight,
    required this.extent,
    required this.initialExtent,
    required this.initialLocationBottom,
    required this.initialSearchBottom,
    required this.topPadding,
  });

  final double viewportHeight;
  final double extent;
  final double initialExtent;
  final double initialLocationBottom;
  final double initialSearchBottom;
  final double topPadding;

  double get sheetHeight => viewportHeight * extent;
  double get displacement => viewportHeight * (extent - initialExtent);
  double get locationBottom => initialLocationBottom + displacement;
  double get searchBottom => initialSearchBottom + displacement;
  EdgeInsets get contentPadding =>
      EdgeInsets.only(top: topPadding, bottom: sheetHeight);
}
