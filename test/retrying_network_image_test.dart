import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:muntum/components/retrying_network_image.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:muntum/api/api_response.dart';
import 'package:muntum/models/program_model.dart';
import 'package:muntum/screens/home/components/explore_taste_section.dart';
import 'package:muntum/stores/auth_state.dart';

void main() {
  late _Images transport;
  void imageTest(String description, WidgetTesterCallback callback) {
    testWidgets(description, (tester) async {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      transport = _Images();
      debugNetworkImageHttpClientProvider = () => transport;
      try {
        await callback(tester);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        debugNetworkImageHttpClientProvider = null;
      }
    });
  }

  Future<void> show(WidgetTester tester, Widget image) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: SizedBox(width: 160, height: 210, child: image)),
        ),
      ),
    );
    await _flushNetwork(tester);
  }

  bool hasImage(WidgetTester tester) => tester
      .widgetList<RawImage>(find.byType(RawImage))
      .any((image) => image.image != null);

  imageTest(
    'failed request retries and displays a later image without a parent rebuild',
    (tester) async {
      await show(
        tester,
        const RetryingNetworkImage(
          url: 'https://images.test/poster?signature=unchanged',
        ),
      );
      expect(transport.urls, hasLength(1));
      expect(hasImage(tester), false);
      transport.available = true;
      await tester.pump(const Duration(seconds: 3));
      await _flushNetwork(tester);
      expect(transport.urls, hasLength(2));
      expect(transport.urls.map((url) => url.toString()).toSet(), {
        'https://images.test/poster?signature=unchanged',
      });
      expect(hasImage(tester), true);
      await tester.pump(const Duration(seconds: 30));
      expect(transport.urls, hasLength(2));
    },
  );

  imageTest(
    'an in-flight slow request updates immediately when it eventually completes',
    (tester) async {
      final pending = Completer<HttpClientResponse>();
      transport.pending = pending.future;
      await show(
        tester,
        const RetryingNetworkImage(url: 'https://images.test/slow'),
      );
      await tester.pump(const Duration(seconds: 10));
      expect(transport.urls, hasLength(1));
      expect(hasImage(tester), false);
      pending.complete(_Response.success());
      await _flushNetwork(tester);
      expect(hasImage(tester), true);
      expect(transport.urls, hasLength(1));
    },
  );

  imageTest(
    'hidden tab suspends retries and retries immediately when revisited',
    (tester) async {
      final visible = ValueNotifier(true);
      addTearDown(visible.dispose);
      await show(
        tester,
        ValueListenableBuilder<bool>(
          valueListenable: visible,
          builder: (_, enabled, child) =>
              TickerMode(enabled: enabled, child: child!),
          child: const RetryingNetworkImage(url: 'https://images.test/hidden'),
        ),
      );
      expect(transport.urls, hasLength(1));
      visible.value = false;
      await tester.pump();
      await tester.pump(const Duration(seconds: 30));
      expect(transport.urls, hasLength(1));
      transport.available = true;
      visible.value = true;
      await tester.pump();
      await _flushNetwork(tester);
      expect(transport.urls, hasLength(2));
      expect(hasImage(tester), true);
    },
  );

  imageTest('backgrounded app suspends retries and recovers on resume', (
    tester,
  ) async {
    await show(
      tester,
      const RetryingNetworkImage(url: 'https://images.test/background'),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 30));
    expect(transport.urls, hasLength(1));
    transport.available = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _flushNetwork(tester);
    expect(transport.urls, hasLength(2));
    expect(hasImage(tester), true);
  });

  imageTest(
    'missing URL makes no requests and disposal cancels pending retry',
    (tester) async {
      await show(tester, const RetryingNetworkImage(url: null));
      expect(transport.urls, isEmpty);
      await show(
        tester,
        const RetryingNetworkImage(url: 'https://images.test/disposed'),
      );
      expect(transport.urls, hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 30));
      expect(transport.urls, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  imageTest(
    'taste section updates both poster and backdrop without refetching recommendations',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      AuthState.instance.replace(accessToken: 'test');
      addTearDown(AuthState.instance.clear);
      var recommendationLoads = 0;
      await tester.pumpWidget(
        ScreenUtilPlusInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            home: Scaffold(
              body: ExploreTasteSection(
                loadPrograms: () async {
                  recommendationLoads++;
                  return PageResponse.fromList([
                    ProgramModel.fromJson({
                      'id': 'late-poster',
                      'title': '늦게 받아진 포스터',
                      'thumbnailUrl': 'https://images.test/taste',
                    }),
                  ]);
                },
              ),
            ),
          ),
        ),
      );
      await _flushNetwork(tester);
      expect(find.byType(RetryingNetworkImage), findsNWidgets(2));
      expect(hasImage(tester), false);
      transport.available = true;
      await tester.pump(const Duration(seconds: 3));
      await _flushNetwork(tester);
      expect(
        tester
            .widgetList<RawImage>(find.byType(RawImage))
            .where((image) => image.image != null),
        hasLength(2),
      );
      expect(recommendationLoads, 1);
    },
  );

  imageTest(
    'changing a failed URL abandons its retry and renders the new image',
    (tester) async {
      await show(
        tester,
        const RetryingNetworkImage(url: 'https://images.test/old'),
      );
      transport.available = true;
      await show(
        tester,
        const RetryingNetworkImage(url: 'https://images.test/new'),
      );
      expect(hasImage(tester), true);
      await tester.pump(const Duration(seconds: 6));
      expect(transport.urls.map((url) => url.path), ['/old', '/new']);
    },
  );
}

Future<void> _flushNetwork(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
}

class _Images implements HttpClient {
  bool available = false;
  Future<HttpClientResponse>? pending;
  final urls = <Uri>[];
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    urls.add(url);
    return _Request(
      () async =>
          pending ?? (available ? _Response.success() : _Response(503, [])),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Request implements HttpClientRequest {
  _Request(this.respond);
  final Future<HttpClientResponse> Function() respond;
  @override
  Future<HttpClientResponse> close() => respond();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Response extends Stream<List<int>> implements HttpClientResponse {
  _Response(this.statusCode, this.bytes);
  factory _Response.success() => _Response(
    200,
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    ),
  );
  @override
  final int statusCode;
  final List<int> bytes;
  @override
  int get contentLength => bytes.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream.value(bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
