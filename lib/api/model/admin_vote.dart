import 'vote_status.dart';

class AdminVote {
  const AdminVote({
    required this.id,
    required this.name,
    required this.status,
    required this.createdByUserId,
    this.isMine = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final VoteStatus status;
  final String createdByUserId;
  final bool isMine;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdminVote copyWith({
    String? id,
    String? name,
    VoteStatus? status,
    String? createdByUserId,
    bool? isMine,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminVote(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      isMine: isMine ?? this.isMine,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
