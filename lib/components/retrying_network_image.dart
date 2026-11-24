import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:muntum/constants/colors.dart';

/// Retries a failed poster while its route or tab is active and the app is foregrounded.
///
/// Pending requests display their result immediately. Failed requests are
/// retried without changing the URL, so signed URLs and the image cache work.
class RetryingNetworkImage extends StatefulWidget {
  /// Creates an image that recovers from temporary network and server failures.
  const RetryingNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
  });

  /// The original image URL, or null when the program has no poster.
  final String? url;

  /// How the loaded image fits its existing layout bounds.
  final BoxFit fit;

  @override
  State<RetryingNetworkImage> createState() => _RetryingNetworkImageState();
}

class _RetryingNetworkImageState extends State<RetryingNetworkImage>
    with WidgetsBindingObserver {
  static const _retryDelay = Duration(seconds: 3);
  Timer? _retryTimer;
  int _generation = 0;
  bool _failed = false;
  bool _visible = true;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (_visible == visible) return;
    _visible = visible;
    if (!visible) {
      _cancelRetry();
    } else if (_foreground && _failed) {
      // This lifecycle already triggers a build, so no setState is needed.
      _failed = false;
      _generation++;
    }
  }

  @override
  void didUpdateWidget(covariant RetryingNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _cancelRetry();
      _failed = false;
      _generation++;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _cancelRetry();
    } else if (_visible && _failed) {
      _retry();
    }
  }

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  void _scheduleRetry() {
    _failed = true;
    if (!_foreground || !_visible || _retryTimer != null) return;
    _retryTimer = Timer(_retryDelay, _retry);
  }

  void _retry() {
    _cancelRetry();
    if (!mounted || !_foreground || !_visible || !_failed) return;
    setState(() {
      _failed = false;
      // A new Image state resolves the provider again after a failed load.
      // NetworkImage already evicts failed loads; successful images stay cached.
      _generation++;
    });
  }

  @override
  void dispose() {
    _cancelRetry();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(color: AppColors.gray800);
    final url = widget.url;
    if (url == null || url.isEmpty || !_visible) return placeholder;
    return Image.network(
      url,
      key: ValueKey((url, _generation)),
      fit: widget.fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame == null) return placeholder;
        _failed = false;
        _cancelRetry();
        return child;
      },
      errorBuilder: (context, error, stackTrace) {
        _scheduleRetry();
        return placeholder;
      },
    );
  }
}
