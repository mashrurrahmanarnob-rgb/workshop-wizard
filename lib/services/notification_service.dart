import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Notification types — used to pick icons and colors on the notification screen
class NotifType {
  static const String taskAssigned      = 'task_assigned';
  static const String taskUpdated       = 'task_updated';
  static const String proposalApproved  = 'proposal_approved';
  static const String proposalRejected  = 'proposal_rejected';
  static const String proposalSubmitted = 'proposal_submitted';
  static const String general           = 'general';
}

/// Writes a notification document for a specific user.
/// Silent — never throws, never crashes the caller.
Future<void> sendNotification({
  required String userId,
  required String title,
  required String body,
  String type = NotifType.general,
  Map<String, dynamic>? extra,
}) async {
  try {
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId':    userId,
      'title':     title,
      'body':      body,
      'type':      type,
      'read':      false,
      'createdAt': FieldValue.serverTimestamp(),
      if (extra != null) ...extra,
    });
  } catch (e) {
    debugPrint('sendNotification error: $e');
  }
}

/// Returns a stream of unread notification count for the given user.
Stream<int> unreadCountStream(String userId) {
  return FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: userId)
      .where('read', isEqualTo: false)
      .snapshots()
      .map((snap) => snap.docs.length);
}

/// Marks a single notification as read.
Future<void> markRead(String notifId) async {
  try {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notifId)
        .update({'read': true});
  } catch (e) {
    debugPrint('markRead error: $e');
  }
}

/// Marks ALL notifications for a user as read.
Future<void> markAllRead(String userId) async {
  try {
    final snap = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  } catch (e) {
    debugPrint('markAllRead error: $e');
  }
}