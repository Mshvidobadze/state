import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:state/features/home/data/models/post_model.dart';
import 'package:state/features/postDetails/data/models/comment_model.dart';
import 'package:state/features/postDetails/domain/post_details_repository.dart';

class PostDetailsRepositoryImpl implements PostDetailsRepository {
  final FirebaseFirestore firestore;

  PostDetailsRepositoryImpl({FirebaseFirestore? firestore})
    : firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<PostModel> fetchPostById(String postId) async {
    try {
      final doc = await firestore.collection('posts').doc(postId).get();
      if (!doc.exists) {
        throw Exception('Post not found');
      }
      return PostModel.fromDoc(doc);
    } catch (e) {
      throw Exception('Failed to fetch post: $e');
    }
  }

  @override
  Future<List<CommentModel>> fetchComments(String postId) async {
    try {
      final snapshot =
          await firestore
              .collection('posts')
              .doc(postId)
              .collection('comments')
              .orderBy('createdAt', descending: true)
              .get();

      final comments =
          snapshot.docs.map((doc) {
            final data = doc.data();
            data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
            return CommentModel.fromMap(data, doc.id);
          }).toList();

      // Group comments by parent to build the reply tree
      final Map<String?, List<CommentModel>> commentsByParent = {};
      for (final comment in comments) {
        final parentId = comment.parentCommentId;
        commentsByParent.putIfAbsent(parentId, () => []).add(comment);
      }

      // Root comments are those with no parent
      final rootComments = commentsByParent[null] ?? [];

      // Recursively add replies to each comment
      List<CommentModel> addReplies(CommentModel comment) {
        final replies = commentsByParent[comment.id] ?? [];
        return replies.map((reply) {
          return CommentModel(
            id: reply.id,
            userId: reply.userId,
            userName: reply.userName,
            content: reply.content,
            createdAt: reply.createdAt,
            parentCommentId: reply.parentCommentId,
            replies: addReplies(reply),
          );
        }).toList();
      }

      // Build the final tree structure
      return rootComments.map((comment) {
        return CommentModel(
          id: comment.id,
          userId: comment.userId,
          userName: comment.userName,
          content: comment.content,
          createdAt: comment.createdAt,
          parentCommentId: comment.parentCommentId,
          replies: addReplies(comment),
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch comments: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> fetchCommentsWithPagination({
    required String postId,
    required int limit,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      // First, get only parent comments (no replies) with pagination
      Query parentQuery = firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .where('parentCommentId', isNull: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        parentQuery = parentQuery.startAfterDocument(lastDocument);
      }

      final parentSnapshot = await parentQuery.get();

      // If no parent comments, return empty
      if (parentSnapshot.docs.isEmpty) {
        return {'comments': <CommentModel>[], 'lastDocument': null};
      }

      // Get all comment IDs we need (parent comments from this page)
      final parentCommentIds =
          parentSnapshot.docs.map((doc) => doc.id).toList();

      // Now fetch ALL comments (including replies) for the entire post
      final allCommentsSnapshot =
          await firestore
              .collection('posts')
              .doc(postId)
              .collection('comments')
              .orderBy('createdAt', descending: true)
              .get();

      final List<CommentModel> allComments = [];
      for (final doc in allCommentsSnapshot.docs) {
        final data = doc.data();
        if (data['createdAt'] != null) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
        }
        allComments.add(CommentModel.fromMap(data, doc.id));
      }

      // Group comments by parent to build the reply tree
      final Map<String?, List<CommentModel>> commentsByParent = {};
      for (final comment in allComments) {
        final parentId = comment.parentCommentId;
        commentsByParent.putIfAbsent(parentId, () => []).add(comment);
      }

      // Get only the root comments that are in our paginated set
      final paginatedRootComments =
          (commentsByParent[null] ?? [])
              .where((comment) => parentCommentIds.contains(comment.id))
              .toList();

      // Recursively add replies to each comment
      List<CommentModel> addReplies(CommentModel comment) {
        final replies = commentsByParent[comment.id] ?? [];
        return replies.map((reply) {
          return CommentModel(
            id: reply.id,
            userId: reply.userId,
            userName: reply.userName,
            content: reply.content,
            createdAt: reply.createdAt,
            parentCommentId: reply.parentCommentId,
            replies: addReplies(reply),
          );
        }).toList();
      }

      // Build the final tree structure with all replies included
      final structuredComments =
          paginatedRootComments.map((comment) {
            return CommentModel(
              id: comment.id,
              userId: comment.userId,
              userName: comment.userName,
              content: comment.content,
              createdAt: comment.createdAt,
              parentCommentId: comment.parentCommentId,
              replies: addReplies(comment),
            );
          }).toList();

      // Return both structured comments and the last document for next pagination
      return {
        'comments': structuredComments,
        'lastDocument':
            parentSnapshot.docs.isNotEmpty ? parentSnapshot.docs.last : null,
      };
    } catch (e) {
      throw Exception('Failed to fetch comments with pagination: $e');
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
      final batch = firestore.batch();
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

      batch.set(commentsRef.doc(), commentData);

      final postRef = firestore.collection('posts').doc(postId);
      batch.update(postRef, {'commentsCount': FieldValue.increment(1)});

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  @override
  Future<void> toggleUpvote(String postId, String userId) async {
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
  Future<void> toggleFollow(String postId, String userId) async {
    try {
      final postRef = firestore.collection('posts').doc(postId);
      final doc = await postRef.get();
      if (!doc.exists) throw Exception('Post not found');

      final data = doc.data() as Map<String, dynamic>;
      final List<dynamic> followers = data['followers'] ?? [];

      if (followers.contains(userId)) {
        await postRef.update({
          'followers': FieldValue.arrayRemove([userId]),
        });
      } else {
        await postRef.update({
          'followers': FieldValue.arrayUnion([userId]),
        });
      }
    } catch (e) {
      throw Exception('Failed to toggle follow: $e');
    }
  }
}
