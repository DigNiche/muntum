import 'package:material_ui/material_ui.dart';

/// Uses the same non-bouncing, non-accelerating scroll rules on every screen.
///
/// Normal fling inertia remains. Explicit page snapping, refresh gestures and
/// disabled scrolling continue to be composed by their owning widgets.
class AppScrollBehavior extends MaterialScrollBehavior {
  /// Creates the app-wide scroll configuration.
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics(parent: RangeMaintainingScrollPhysics());
}
