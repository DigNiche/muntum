import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/utils/paginated_progress_target.dart';

void main() {
  test(
    'waits for an in-flight page before resolving an end-of-bar drag',
    () async {
      var loaded = 20;
      final pageFinished = Completer<void>();
      var calls = 0;

      final result = resolvePaginatedProgressTarget(
        targetIndex: () => 24,
        loadedCount: () => loaded,
        hasMore: () => true,
        loadMore: () async {
          calls++;
          await pageFinished.future;
          loaded = 25;
        },
      );

      await Future<void>.delayed(Duration.zero);
      expect(calls, 1);
      pageFinished.complete();
      expect(await result, 24);
      expect(calls, 1);
    },
  );

  test('stops after a page request that did not add programs', () async {
    var calls = 0;
    final result = await resolvePaginatedProgressTarget(
      targetIndex: () => 99,
      loadedCount: () => 20,
      hasMore: () => true,
      loadMore: () async => calls++,
    );

    expect(result, 19);
    expect(calls, 1);
  });
}
