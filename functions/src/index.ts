import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import {onCall} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();

// Send notification when someone comments on a post
export const onCommentCreated = onDocumentCreated(
  "posts/{postId}/comments/{commentId}",
  async (event) => {
    const snap = event.data;
    const context = event.params;
    if (!snap) return;
    const comment = snap.data();
    const postId = context.postId;
    const commentId = context.commentId;

    // Get post details
    const postDoc = await admin.firestore()
      .collection("posts")
      .doc(postId)
      .get();
    if (!postDoc.exists) return;

    const post = postDoc.data();
    const postAuthorId = post?.authorId;

    // Don't send notification to the commenter themselves
    if (comment.userId === postAuthorId) return;

    // Only send notifications for top-level comments, not replies
    if (comment.parentCommentId) {
      console.log("Skipping notification for reply comment");
      return;
    }

    // Get commenter details
    const commenterDoc = await admin.firestore()
      .collection("users")
      .doc(comment.userId)
      .get();
    if (!commenterDoc.exists) return;

    const commenter = commenterDoc.data();
    const commenterName = commenter?.displayName || "Someone";

    // Get post author's FCM token
    const postAuthorDoc = await admin.firestore()
      .collection("users")
      .doc(postAuthorId)
      .get();
    if (!postAuthorDoc.exists) return;

    const postAuthor = postAuthorDoc.data();
    const fcmToken = postAuthor?.fcmToken;

    if (!fcmToken) return;

    // Create notification message
    const message = {
      token: fcmToken,
      notification: {
        title: `${commenterName} commented on your post`,
        body: comment.content.length > 100 ?
          comment.content.substring(0, 100) + "..." :
          comment.content,
      },
      data: {
        type: "comment",
        postId: postId,
        commentId: commentId, // Include commentId for deep linking
        actorName: commenterName,
        message: comment.content,
      },
      android: {
        notification: {
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: `${commenterName} commented on your post`,
              body: comment.content.length > 100 ?
                comment.content.substring(0, 100) + "..." :
                comment.content,
            },
            sound: "default",
          },
        },
      },
    };

    try {
      // Send FCM notification
      await admin.messaging().send(message);

      // Save notification to Firestore
      await admin.firestore().collection("notifications").add({
        type: "comment",
        postId: postId,
        commentId: commentId,
        actorId: comment.userId,
        actorName: commenterName,
        actorPhotoUrl: commenter?.photoUrl,
        userId: postAuthorId, // Changed from recipientId to userId
        message: comment.content,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log("Comment notification sent successfully");
    } catch (error) {
      console.error("Error sending comment notification:", error);
    }
  });

// Send notification when someone upvotes a post
export const onPostUpvoted = onDocumentUpdated(
  "posts/{postId}",
  async (event) => {
    const change = event.data;
    const context = event.params;
    if (!change) return;
    const before = change.before.data();
    const after = change.after.data();
    const postId = context.postId;

    // Check if upvotes increased
    const beforeUpvotes = before.upvoters?.length || 0;
    const afterUpvotes = after.upvoters?.length || 0;

    if (afterUpvotes <= beforeUpvotes) return;

    // Find the new upvoter
    const newUpvoters = after.upvoters?.filter((id: string) =>
      !before.upvoters?.includes(id)) || [];
    if (newUpvoters.length === 0) return;

    const newUpvoterId = newUpvoters[0];
    const postAuthorId = after.authorId;

    // Don't send notification to the upvoter themselves
    if (newUpvoterId === postAuthorId) return;

    // Get upvoter details
    const upvoterDoc = await admin.firestore()
      .collection("users")
      .doc(newUpvoterId)
      .get();
    if (!upvoterDoc.exists) return;

    const upvoter = upvoterDoc.data();
    const upvoterName = upvoter?.displayName || "Someone";

    // Get post author's FCM token
    const postAuthorDoc = await admin.firestore()
      .collection("users")
      .doc(postAuthorId)
      .get();
    if (!postAuthorDoc.exists) return;

    const postAuthor = postAuthorDoc.data();
    const fcmToken = postAuthor?.fcmToken;

    if (!fcmToken) return;

    // Create notification message
    const message = {
      token: fcmToken,
      notification: {
        title: `${upvoterName} upvoted your post`,
        body: after.content.length > 100 ?
          after.content.substring(0, 100) + "..." :
          after.content,
      },
      data: {
        type: "upvote",
        postId: postId,
        actorName: upvoterName,
        message: after.content,
      },
      android: {
        notification: {
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: `${upvoterName} upvoted your post`,
              body: after.content.length > 100 ?
                after.content.substring(0, 100) + "..." :
                after.content,
            },
            sound: "default",
          },
        },
      },
    };

    try {
      // Send FCM notification
      await admin.messaging().send(message);

      // Save notification to Firestore
      await admin.firestore().collection("notifications").add({
        type: "upvote",
        postId: postId,
        commentId: null, // No commentId for upvote notifications
        actorId: newUpvoterId,
        actorName: upvoterName,
        actorPhotoUrl: upvoter?.photoUrl,
        userId: postAuthorId, // Changed from recipientId to userId
        message: after.content,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log("Upvote notification sent successfully");
    } catch (error) {
      console.error("Error sending upvote notification:", error);
    }
  });

// Function to update user's FCM token
export const updateUserFCMToken = onCall(
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  async (request: any) => {
    const data = request.data;
    const context = request.auth;
    if (!context) {
      throw new Error("User must be authenticated");
    }

    const {fcmToken} = data;
    if (!fcmToken) {
      throw new Error("FCM token is required");
    }

    try {
      await admin.firestore()
        .collection("users")
        .doc(context.uid)
        .update({
          fcmToken: fcmToken,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      return {success: true};
    } catch (error) {
      console.error("Error updating FCM token:", error);
      throw new Error("Failed to update FCM token");
    }
  });
