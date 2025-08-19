class CommentModel {
  final String id;
  final String userId;
  final String userName;
  final String content;
  final DateTime createdAt;
  final String? parentCommentId;
  final List<CommentModel> replies;

  CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
    this.parentCommentId,
    this.replies = const [],
  });

  factory CommentModel.fromMap(Map<String, dynamic> map, String id) {
    return CommentModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as DateTime?) ?? DateTime.now(),
      parentCommentId: map['parentCommentId'],
      replies: const [],
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userName': userName,
    'content': content,
    'createdAt': createdAt,
    'parentCommentId': parentCommentId,
  };
}
