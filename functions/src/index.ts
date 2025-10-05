import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import {onCall} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// Interface for notification data
interface NotificationData {
  type: "comment" | "upvote";
  postId: string;
  commentId?: string;
  actorId: string;
  actorName: string;
  actorPhotoUrl?: string;
  recipientId: string;
  postTitle?: string;
  commentContent?: string;
}

/**
 * Sends a push notification to a user
 * @param {NotificationData} notificationData The notification data
 */
async function sendPushNotification(
  notificationData: NotificationData,
): Promise<void> {
  try {
    // Get recipient's FCM token
    const userDoc = await db.collection("users")
      .doc(notificationData.recipientId).get();

    if (!userDoc.exists) {
      console.log(`User ${notificationData.recipientId} not found`);
      return;
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
      console.log(`No FCM token found for user ${
        notificationData.recipientId}`);
      return;
    }

    // Create notification message
    const message: admin.messaging.Message = {
      token: fcmToken,
      notification: {
        title: getNotificationTitle(notificationData),
        body: getNotificationBody(notificationData),
      },
      data: {
        type: notificationData.type,
        postId: notificationData.postId,
        commentId: notificationData.commentId || "",
        actorId: notificationData.actorId,
        actorName: notificationData.actorName,
      },
      android: {
        notification: {
          icon: "ic_stat_name",
          color: "#2196F3",
          channelId: "state_notifications_channel",
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: getNotificationTitle(notificationData),
              body: getNotificationBody(notificationData),
            },
            badge: 1,
            sound: "default",
          },
        },
      },
    };

    // Send the message
    const response = await messaging.send(message);
    console.log("Successfully sent message:", response);

    // Save notification to Firestore
    await saveNotificationToFirestore(notificationData);
    console.log("Notification saved to Firestore successfully");
  } catch (error) {
    console.error("Error sending push notification:", error);
  }
}

/**
 * Creates a notification document in Firestore
 * @param {NotificationData} notificationData The notification data
 */
async function saveNotificationToFirestore(
  notificationData: NotificationData,
): Promise<void> {
  try {
    const notification = {
      userId: notificationData.recipientId,
      actorId: notificationData.actorId,
      actorName: notificationData.actorName,
      actorPhotoUrl: notificationData.actorPhotoUrl || "",
      type: notificationData.type,
      postId: notificationData.postId,
      commentId: notificationData.commentId || null,
      message: getNotificationBody(notificationData),
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection("notifications").add(notification);
    console.log("Notification saved to Firestore");
  } catch (error) {
    console.error("Error saving notification to Firestore:", error);
  }
}

/**
 * Generates notification title based on type
 * @param {NotificationData} notificationData The notification data
 * @return {string} The notification title
 */
function getNotificationTitle(notificationData: NotificationData): string {
  switch (notificationData.type) {
  case "comment":
    return "New Comment";
  case "upvote":
    return "New Upvote";
  default:
    return "New Notification";
  }
}

/**
 * Generates notification body based on type
 * @param {NotificationData} notificationData The notification data
 * @return {string} The notification body
 */
function getNotificationBody(notificationData: NotificationData): string {
  switch (notificationData.type) {
  case "comment":
    return `${notificationData.actorName} commented on your post`;
  case "upvote":
    return `${notificationData.actorName} upvoted your post`;
  default:
    return "You have a new notification";
  }
}

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

    console.log("Comment created:", {
      postId,
      commentId,
      commentData: comment,
    });

    // Get post details
    const postDoc = await db.collection("posts").doc(postId).get();
    if (!postDoc.exists) {
      console.log("Post not found:", postId);
      return;
    }

    const post = postDoc.data();
    const postAuthorId = post?.authorId;
    const commentAuthorId = comment?.authorId || comment?.userId;

    console.log("Post and comment authors:", {
      postAuthorId,
      commentAuthorId,
      parentCommentId: comment.parentCommentId,
    });

    // Don't send notification if the comment author is the same as post author
    if (postAuthorId === commentAuthorId) {
      console.log("Comment author is the same as post author, " +
        "skipping notification");
      return;
    }

    // Only send notifications for top-level comments, not replies
    if (comment.parentCommentId) {
      console.log("Skipping notification for reply comment");
      return;
    }

    // Get commenter details
    const commenterDoc = await db.collection("users")
      .doc(commentAuthorId).get();
    if (!commenterDoc.exists) return;

    const commenter = commenterDoc.data();
    const commenterName = commenter?.displayName || commenter?.email ||
      "Unknown User";

    const notificationData: NotificationData = {
      type: "comment",
      postId: postId,
      commentId: commentId,
      actorId: commentAuthorId,
      actorName: commenterName,
      actorPhotoUrl: commenter?.photoURL,
      recipientId: postAuthorId,
      commentContent: comment?.content,
    };

    console.log("Sending notification:", notificationData);
    await sendPushNotification(notificationData);
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
    const beforeUpvoters = before?.upvoters || [];
    const afterUpvoters = after?.upvoters || [];

    // Find new upvoters
    const newUpvoters = afterUpvoters.filter((upvoter: string) =>
      !beforeUpvoters.includes(upvoter));
    const postAuthorId = after?.authorId;

    if (newUpvoters.length === 0 || !postAuthorId) {
      return;
    }

    // Send notification for each new upvote
    for (const upvoterId of newUpvoters) {
      // Don't send notification if the upvoter is the same as post author
      if (upvoterId === postAuthorId) {
        continue;
      }

      // Get upvoter details
      const upvoterDoc = await db.collection("users")
        .doc(upvoterId).get();
      if (!upvoterDoc.exists) continue;

      const upvoter = upvoterDoc.data();
      const upvoterName = upvoter?.displayName || upvoter?.email ||
        "Unknown User";

      const notificationData: NotificationData = {
        type: "upvote",
        postId: postId,
        actorId: upvoterId,
        actorName: upvoterName,
        actorPhotoUrl: upvoter?.photoURL,
        recipientId: postAuthorId,
      };

      await sendPushNotification(notificationData);
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
      await db.collection("users").doc(context.uid).update({
        fcmToken: fcmToken,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {success: true};
    } catch (error) {
      console.error("Error updating FCM token:", error);
      throw new Error("Failed to update FCM token");
    }
  });

// Function to send test notification (for development)
export const sendTestNotification = onCall(
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  async (request: any) => {
    const data = request.data;
    const context = request.auth;
    if (!context) {
      throw new Error("User must be authenticated");
    }

    const {recipientId, type, postId, commentId} = data;

    const notificationData: NotificationData = {
      type: type || "comment",
      postId: postId || "test-post-id",
      commentId: commentId,
      actorId: context.uid,
      actorName: "Test User",
      recipientId: recipientId || context.uid,
    };

    await sendPushNotification(notificationData);

    return {success: true};
  });
