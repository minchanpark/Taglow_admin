class AdminQuestion {
  const AdminQuestion({
    required this.id,
    required this.voteId,
    required this.title,
    required this.detail,
    required this.imageUrl,
    required this.imageRatio,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String voteId;
  final String title;
  final String detail;
  final String imageUrl;
  final double imageRatio;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdminQuestion copyWith({
    String? id,
    String? voteId,
    String? title,
    String? detail,
    String? imageUrl,
    double? imageRatio,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminQuestion(
      id: id ?? this.id,
      voteId: voteId ?? this.voteId,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      imageUrl: imageUrl ?? this.imageUrl,
      imageRatio: imageRatio ?? this.imageRatio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
