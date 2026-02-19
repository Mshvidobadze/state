import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:state/features/home/data/models/post_model.dart';
import 'package:state/features/home/data/models/filter_model.dart';
import 'package:state/features/home/domain/home_repository.dart';
import 'package:state/core/constants/regions.dart';

class HomeRepositoryImpl implements HomeRepository {
  final FirebaseFirestore firestore;

  HomeRepositoryImpl({FirebaseFirestore? firestore})
    : firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<PostModel>> fetchPosts({
    required FilterModel filter,
    int limit = 10,
    String? lastDocumentId,
  }) async {
    try {
      if (filter.region.isEmpty) {
        throw Exception('Region filter cannot be empty');
      }

      Query query = firestore
          .collection('posts')
          .where('region', isEqualTo: filter.region);

      // Apply time filter only for ranking-based filter types.
      bool hasTimeFilter = false;
      if ((filter.filterType == FilterType.top ||
              filter.filterType == FilterType.mostDownvoted) &&
          filter.timeFilter != TimeFilter.allTime &&
          filter.timeFilter.isNotEmpty) {
        final duration = TimeFilter.timeFilterDurations[filter.timeFilter];
        if (duration != null && duration != Duration.zero) {
          final cutoffTime = DateTime.now().subtract(duration);
          query = query.where('createdAt', isGreaterThanOrEqualTo: cutoffTime);
          hasTimeFilter = true;
        }
      }
      final usesInMemoryRanking =
          filter.filterType == FilterType.mostDownvoted || hasTimeFilter;

      // Sort by creation date for "new", otherwise by score field.
      if (filter.filterType == FilterType.newest) {
        query = query.orderBy('createdAt', descending: true);
      } else {
        // For time-filtered ranking, Firestore requires ordering by createdAt first.
        // We'll sort by the selected score field in memory after fetching.
        if (usesInMemoryRanking) {
          query = query.orderBy('createdAt', descending: true);
        } else {
          final scoreField =
              filter.filterType == FilterType.mostDownvoted
                  ? 'downvotes'
                  : 'upvotes';
          query = query.orderBy(scoreField, descending: true);
        }
      }

      // For time-filtered top posts, fetch a larger batch to enable proper sorting
      // Pagination will be handled in-memory
      final fetchLimit =
          ((filter.filterType == FilterType.top ||
                      filter.filterType == FilterType.mostDownvoted) &&
                  usesInMemoryRanking)
              ? 100 // Fetch all posts in time range (up to 100)
              : limit;

      // Apply pagination (only for non-time-filtered queries)
      if (lastDocumentId != null && !usesInMemoryRanking) {
        final lastDoc =
            await firestore.collection('posts').doc(lastDocumentId).get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      final snapshot = await query.limit(fetchLimit).get();
      final posts = snapshot.docs.map((doc) => PostModel.fromDoc(doc)).toList();

      // For time-filtered ranking, sort by score in memory since Firestore query
      // is ordered by createdAt for the range constraint.
      if ((filter.filterType == FilterType.top ||
              filter.filterType == FilterType.mostDownvoted) &&
          usesInMemoryRanking) {
        if (filter.filterType == FilterType.mostDownvoted) {
          posts.sort((a, b) => b.downvotes.compareTo(a.downvotes));
        } else {
          posts.sort((a, b) => b.upvotes.compareTo(a.upvotes));
        }
      }

      return posts;
    } catch (e) {
      throw Exception('Failed to fetch posts: $e');
    }
  }

  @override
  Future<void> createPost(PostModel post) async {
    try {
      final data = post.toMap();
      data['createdAt'] = post.createdAt;
      await firestore.collection('posts').add(data);
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  @override
  Future<void> upvotePost(String postId, String userId) async {
    try {
      final postRef = firestore.collection('posts').doc(postId);
      await firestore.runTransaction((tx) async {
        final doc = await tx.get(postRef);
        if (!doc.exists) throw Exception('Post not found');
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic> upvoters = data['upvoters'] ?? [];
        final int upvotes = data['upvotes'] ?? 0;

        if (upvoters.contains(userId)) {
          tx.update(postRef, {
            'upvotes': upvotes > 0 ? upvotes - 1 : 0,
            'upvoters': FieldValue.arrayRemove([userId]),
          });
        } else {
          tx.update(postRef, {
            'upvotes': upvotes + 1,
            'upvoters': FieldValue.arrayUnion([userId]),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to toggle upvote: $e');
    }
  }

  @override
  Future<void> downvotePost(String postId, String userId) async {
    try {
      final postRef = firestore.collection('posts').doc(postId);
      await firestore.runTransaction((tx) async {
        final doc = await tx.get(postRef);
        if (!doc.exists) throw Exception('Post not found');
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic> downvoters = data['downvoters'] ?? [];
        final int downvotes = data['downvotes'] ?? 0;

        if (downvoters.contains(userId)) {
          tx.update(postRef, {
            'downvotes': downvotes > 0 ? downvotes - 1 : 0,
            'downvoters': FieldValue.arrayRemove([userId]),
          });
        } else {
          tx.update(postRef, {
            'downvotes': downvotes + 1,
            'downvoters': FieldValue.arrayUnion([userId]),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to toggle downvote: $e');
    }
  }

  @override
  Future<void> followPost(String postId, String userId) async {
    try {
      final postRef = firestore.collection('posts').doc(postId);
      await postRef.update({
        'followers': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('Failed to follow post: $e');
    }
  }

  @override
  Future<void> unfollowPost(String postId, String userId) async {
    try {
      final postRef = firestore.collection('posts').doc(postId);
      await postRef.update({
        'followers': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw Exception('Failed to unfollow post: $e');
    }
  }

  @override
  Future<void> reportPost(String postId, String userId) async {
    try {
      // Use batch write for atomic operation
      final batch = firestore.batch();

      // Update post's reporters array
      final postRef = firestore.collection('posts').doc(postId);
      batch.update(postRef, {
        'reporters': FieldValue.arrayUnion([userId]),
      });

      // Store report details in a separate collection
      final reportRef = firestore.collection('reports').doc();
      batch.set(reportRef, {
        'postId': postId,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to report post: $e');
    }
  }

  @override
  Future<void> addComment({
    required String postId,
    required String userId,
    required String userName,
    required String content,
    String? userPhotoUrl,
    String? parentCommentId,
  }) async {
    try {
      final commentsRef = firestore
          .collection('posts')
          .doc(postId)
          .collection('comments');

      final commentData = {
        'userId': userId,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
        'parentCommentId': parentCommentId,
      };

      await commentsRef.add(commentData);

      // Optionally increment commentsCount in post
      final postRef = firestore.collection('posts').doc(postId);
      await postRef.update({'commentsCount': FieldValue.increment(1)});
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }
}
