import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class PostModel extends Equatable {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String region;
  final String title;
  final String content;
  final String? imageUrl;
  final int upvotes;
  final int commentsCount;
  final DateTime createdAt;
  final List<String> followers;
  final List<String> upvoters;
  final List<String> reporters;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.region,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.upvotes,
    required this.commentsCount,
    required this.createdAt,
    required this.followers,
    required this.upvoters,
    required this.reporters,
  });

  factory PostModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorPhotoUrl: data['authorPhotoUrl'],
      region: data['region'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      upvotes: data['upvotes'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      followers: List<String>.from(data['followers'] ?? []),
      upvoters: List<String>.from(data['upvoters'] ?? []),
      reporters: List<String>.from(data['reporters'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'authorId': authorId,
    'authorName': authorName,
    'authorPhotoUrl': authorPhotoUrl,
    'region': region,
    'title': title,
    'content': content,
    'imageUrl': imageUrl,
    'upvotes': upvotes,
    'commentsCount': commentsCount,
    'createdAt': createdAt,
    'followers': followers,
    'upvoters': upvoters,
    'reporters': reporters,
  };

  PostModel copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorPhotoUrl,
    String? region,
    String? title,
    String? content,
    String? imageUrl,
    int? upvotes,
    int? commentsCount,
    DateTime? createdAt,
    List<String>? followers,
    List<String>? upvoters,
    List<String>? reporters,
  }) {
    return PostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      region: region ?? this.region,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      upvotes: upvotes ?? this.upvotes,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt ?? this.createdAt,
      followers: followers ?? this.followers,
      upvoters: upvoters ?? this.upvoters,
      reporters: reporters ?? this.reporters,
    );
  }

  @override
  List<Object?> get props => [
    id,
    authorId,
    authorName,
    authorPhotoUrl,
    region,
    title,
    content,
    imageUrl,
    upvotes,
    commentsCount,
    createdAt,
    followers,
    upvoters,
    reporters,
  ];
}
