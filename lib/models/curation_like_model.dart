/// The server-authoritative like count and current viewer's selection.
class CurationLikeModel {
  /// Creates a like snapshot; defaults support responses predating likes.
  const CurationLikeModel({this.count = 0, this.liked = false});

  /// The total number of likes, not a client-side estimate.
  final int count;

  /// Whether the authenticated viewer liked this curation.
  final bool liked;

  /// Reads either a nested `like` object or a mutation response's `data`.
  factory CurationLikeModel.fromJson(Map<String, dynamic> json) =>
      CurationLikeModel(
        count: (json['count'] as num? ?? 0).toInt(),
        liked: json['liked'] == true,
      );

  /// Serializes the API's like object.
  Map<String, dynamic> toJson() => {'count': count, 'liked': liked};
}
