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
  Future<List<PostModel>> fetchPosts({required FilterModel filter}) async {
    try {
      if (filter.region.isEmpty) {
        throw Exception('Region filter cannot be empty');
      }

      Query query = firestore
          .collection('posts')
          .where('region', isEqualTo: filter.region);

      // Apply time filter if not "all time"
      if (filter.timeFilter != TimeFilter.allTime) {
        final duration = TimeFilter.timeFilterDurations[filter.timeFilter];
        if (duration != null && duration != Duration.zero) {
          final cutoffTime = DateTime.now().subtract(duration);
          query = query.where('createdAt', isGreaterThanOrEqualTo: cutoffTime);
        }
      }

      // Always sort by upvotes for "top" filter (which replaces "hot")
      query = query.orderBy('upvotes', descending: true);

      final snapshot = await query.limit(50).get();
      return snapshot.docs.map((doc) => PostModel.fromDoc(doc)).toList();
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

  /// Toggle upvote: if user has upvoted, remove upvote; else, add upvote.
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
          // User already upvoted, remove upvote
          tx.update(postRef, {
            'upvotes': upvotes > 0 ? upvotes - 1 : 0,
            'upvoters': FieldValue.arrayRemove([userId]),
          });
        } else {
          // User has not upvoted, add upvote
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
  Future<void> addComment({
    required String postId,
    required String userId,
    required String userName,
    required String content,
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
