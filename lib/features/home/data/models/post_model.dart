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
  final List<String> imageUrls;
  final int upvotes;
  final int downvotes;
  final int commentsCount;
  final DateTime createdAt;
  final List<String> followers;
  final List<String> upvoters;
  final List<String> downvoters;
  final List<String> reporters;

  const PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.region,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.imageUrls,
    required this.upvotes,
    required this.downvotes,
    required this.commentsCount,
    required this.createdAt,
    required this.followers,
    required this.upvoters,
    required this.downvoters,
    required this.reporters,
  });

  factory PostModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final parsedImageUrls = List<String>.from(data['imageUrls'] ?? []);
    final legacyImageUrl = data['imageUrl'] as String?;
    final normalizedImageUrls =
        parsedImageUrls.isNotEmpty
            ? parsedImageUrls
            : (legacyImageUrl != null && legacyImageUrl.isNotEmpty)
            ? [legacyImageUrl]
            : <String>[];
    return PostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorPhotoUrl: data['authorPhotoUrl'],
      region: data['region'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrl:
          normalizedImageUrls.isNotEmpty ? normalizedImageUrls.first : null,
      imageUrls: normalizedImageUrls,
      upvotes: data['upvotes'] ?? 0,
      downvotes: data['downvotes'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      followers: List<String>.from(data['followers'] ?? []),
      upvoters: List<String>.from(data['upvoters'] ?? []),
      downvoters: List<String>.from(data['downvoters'] ?? []),
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
    'imageUrl': imageUrls.isNotEmpty ? imageUrls.first : imageUrl,
    'imageUrls': imageUrls,
    'upvotes': upvotes,
    'downvotes': downvotes,
    'commentsCount': commentsCount,
    'createdAt': createdAt,
    'followers': followers,
    'upvoters': upvoters,
    'downvoters': downvoters,
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
    List<String>? imageUrls,
    int? upvotes,
    int? downvotes,
    int? commentsCount,
    DateTime? createdAt,
    List<String>? followers,
    List<String>? upvoters,
    List<String>? downvoters,
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
      imageUrls: imageUrls ?? this.imageUrls,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt ?? this.createdAt,
      followers: followers ?? this.followers,
      upvoters: upvoters ?? this.upvoters,
      downvoters: downvoters ?? this.downvoters,
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
    imageUrls,
    upvotes,
    downvotes,
    commentsCount,
    createdAt,
    followers,
    upvoters,
    downvoters,
    reporters,
  ];

  List<String> get resolvedImageUrls {
    if (imageUrls.isNotEmpty) return imageUrls;
    if (imageUrl != null && imageUrl!.isNotEmpty) return [imageUrl!];
    return const <String>[];
  }
}
