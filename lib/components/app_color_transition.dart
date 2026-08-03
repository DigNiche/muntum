import 'package:flutter/material.dart';

typedef AppColorTransitionBuilder =
    Widget Function(BuildContext context, Color color, Widget? child);

class AppColorTransition extends StatelessWidget {
  static const duration = Duration(milliseconds: 300);
  static const curve = Curves.easeInOut;

  final Color color;
  final AppColorTransitionBuilder builder;
  final Widget? child;

  const AppColorTransition({
    super.key,
    required this.color,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      duration: duration,
      curve: curve,
      tween: ColorTween(end: color),
      child: child,
      builder: (context, animatedColor, child) {
        return builder(context, animatedColor ?? color, child);
      },
    );
  }
}
