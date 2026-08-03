enum ProgramReaction { like, dislike }

extension ProgramReactionApi on ProgramReaction {
  String get apiValue => switch (this) {
    ProgramReaction.like => 'LIKE',
    ProgramReaction.dislike => 'DISLIKE',
  };
}

ProgramReaction? programReactionFromJson(Object? value) {
  return switch (value?.toString().toUpperCase()) {
    'LIKE' => ProgramReaction.like,
    'DISLIKE' => ProgramReaction.dislike,
    _ => null,
  };
}

class ProgramReactionSummary {
  final ProgramReaction? myReaction;
  final int likeCount;
  final int dislikeCount;

  const ProgramReactionSummary({
    this.myReaction,
    this.likeCount = 0,
    this.dislikeCount = 0,
  });

  factory ProgramReactionSummary.fromJson(Object? json) {
    if (json is! Map) return const ProgramReactionSummary();
    final map = Map<String, dynamic>.from(json);
    return ProgramReactionSummary(
      myReaction: programReactionFromJson(map['myReaction']),
      likeCount: (map['likeCount'] as num? ?? 0).toInt(),
      dislikeCount: (map['dislikeCount'] as num? ?? 0).toInt(),
    );
  }
}
