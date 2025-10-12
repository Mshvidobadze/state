class CommentModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final String? parentCommentId;
  final List<CommentModel> replies;
  final int upvotes;
  final List<String> upvoters;

  CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.parentCommentId,
    this.replies = const [],
    this.upvotes = 0,
    this.upvoters = const [],
  });

  factory CommentModel.fromMap(Map<String, dynamic> map, String id) {
    return CommentModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhotoUrl: map['userPhotoUrl'],
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'],
      createdAt: (map['createdAt'] as DateTime?) ?? DateTime.now(),
      parentCommentId: map['parentCommentId'],
      replies: const [],
      upvotes: map['upvotes'] ?? 0,
      upvoters: List<String>.from(map['upvoters'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userName': userName,
    'userPhotoUrl': userPhotoUrl,
    'content': content,
    'imageUrl': imageUrl,
    'createdAt': createdAt,
    'parentCommentId': parentCommentId,
    'upvotes': upvotes,
    'upvoters': upvoters,
  };

  CommentModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? content,
    String? imageUrl,
    DateTime? createdAt,
    String? parentCommentId,
    List<CommentModel>? replies,
    int? upvotes,
    List<String>? upvoters,
  }) {
    return CommentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replies: replies ?? this.replies,
      upvotes: upvotes ?? this.upvotes,
      upvoters: upvoters ?? this.upvoters,
    );
  }
}
