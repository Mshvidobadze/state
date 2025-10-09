import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();

// Send notification when someone comments on a post
export const onCommentCreated = onDocumentCreated(
  "posts/{postId}/comments/{commentId}",
  async (event) => {
    const snap = event.data;
    const params = event.params;
    if (!snap) return;

    const comment = snap.data();
    const postId = params.postId as string;
    const commentId = params.commentId as string;

    console.log("Comment created:", {postId, commentId, commentData: comment});

    // Get post details
    const postDoc = await admin.firestore()
      .collection("posts").doc(postId).get();
    if (!postDoc.exists) return;

    const post = postDoc.data();
    const postAuthorId = post?.authorId;
    const commentAuthorId = comment.authorId || comment.userId;

    console.log("Authors:", {postAuthorId, commentAuthorId});

    // Don't send notification to the commenter themselves
    if (commentAuthorId === postAuthorId) return;

    // Get commenter details
    const commenterDoc = await admin.firestore()
      .collection("users").doc(commentAuthorId).get();
    if (!commenterDoc.exists) return;

    const commenter = commenterDoc.data();
    const commenterName = commenter?.displayName || "Someone";

    // Get post author's FCM token
    const postAuthorDoc = await admin.firestore()
      .collection("users").doc(postAuthorId).get();
    if (!postAuthorDoc.exists) return;

    const postAuthor = postAuthorDoc.data();
    const fcmToken = postAuthor?.fcmToken;

    if (!fcmToken) {
      console.log("No FCM token for user:", postAuthorId);
      return;
    }

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
        postId: String(postId),
        commentId: String(commentId),
        actorName: String(commenterName),
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        notification: {
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
          channelId: "state_notifications_channel",
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
      console.log("Sending notification to:", postAuthorId);
      // Send FCM notification
      await admin.messaging().send(message);
      console.log("FCM notification sent successfully");

      // Save notification to Firestore
      await admin.firestore().collection("notifications").add({
        type: "comment",
        postId: postId,
        commentId: commentId,
        actorId: commentAuthorId,
        actorName: commenterName,
        actorPhotoUrl: commenter?.photoUrl || "",
        userId: postAuthorId,
        message: comment.content,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log("Notification saved to Firestore");
    } catch (error) {
      console.error("Error sending comment notification:", error);
    }
  },
);

// Send notification when someone upvotes a post
export const onPostUpvoted = onDocumentUpdated(
  "posts/{postId}",
  async (event) => {
    const change = event.data;
    const params = event.params;
    if (!change) return;

    const before = change.before.data();
    const after = change.after.data();
    const postId = params.postId as string;

    // Check if upvotes increased
    const beforeUpvotes = before.upvoters?.length || 0;
    const afterUpvotes = after.upvoters?.length || 0;

    if (afterUpvotes <= beforeUpvotes) return;

    // Find the new upvoter
    const newUpvoters = after.upvoters?.filter(
      (id: string) => !before.upvoters?.includes(id),
    ) || [];
    if (newUpvoters.length === 0) return;

    const newUpvoterId = newUpvoters[0];
    const postAuthorId = after.authorId;

    // Don't send notification to the upvoter themselves
    if (newUpvoterId === postAuthorId) return;

    // Get upvoter details
    const upvoterDoc = await admin.firestore()
      .collection("users").doc(newUpvoterId).get();
    if (!upvoterDoc.exists) return;

    const upvoter = upvoterDoc.data();
    const upvoterName = upvoter?.displayName || "Someone";

    // Get post author's FCM token
    const postAuthorDoc = await admin.firestore()
      .collection("users").doc(postAuthorId).get();
    if (!postAuthorDoc.exists) return;

    const postAuthor = postAuthorDoc.data();
    const fcmToken = postAuthor?.fcmToken;

    if (!fcmToken) {
      console.log("No FCM token for user:", postAuthorId);
      return;
    }

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
        postId: String(postId),
        commentId: "",
        actorName: String(upvoterName),
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        notification: {
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
          channelId: "state_notifications_channel",
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
        commentId: null,
        actorId: newUpvoterId,
        actorName: upvoterName,
        actorPhotoUrl: upvoter?.photoUrl || "",
        userId: postAuthorId,
        message: after.content,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log("Upvote notification sent successfully");
    } catch (error) {
      console.error("Error sending upvote notification:", error);
    }
  },
);

// Function to update user's FCM token
export const updateUserFCMToken = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "User must be authenticated",
    );
  }

  const {fcmToken} = request.data;
  if (!fcmToken) {
    throw new HttpsError(
      "invalid-argument",
      "FCM token is required",
    );
  }

  try {
    await admin.firestore().collection("users")
      .doc(request.auth.uid).update({
        fcmToken: fcmToken,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    return {success: true};
  } catch (error) {
    console.error("Error updating FCM token:", error);
    throw new HttpsError(
      "internal",
      "Failed to update FCM token",
    );
  }
});
