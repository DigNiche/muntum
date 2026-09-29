/// Resolves a drag target against pages that may still be loading.
/// Stops when a page request made no progress, even if the API still reports
/// another page, so an end-of-bar drag cannot spin indefinitely.
Future<int?> resolvePaginatedProgressTarget({
  required int Function() targetIndex,
  required int Function() loadedCount,
  required bool Function() hasMore,
  required Future<void> Function() loadMore,
}) async {
  var requestedIndex = targetIndex();
  while (requestedIndex >= loadedCount() && hasMore()) {
    final previousCount = loadedCount();
    await loadMore();
    requestedIndex = targetIndex();
    if (loadedCount() <= previousCount) break;
  }

  final count = loadedCount();
  if (count == 0) return null;
  return requestedIndex.clamp(0, count - 1);
}
