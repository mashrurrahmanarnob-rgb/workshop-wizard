import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

Future<void> logActivity(String title, String subtitle) async {
  try {
    await FirebaseFirestore.instance.collection('activity_logs').add({
      'title': title,
      'subtitle': subtitle,
      'createdAt': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    // Silently handle errors for activity logging so it doesn't crash the main flow
    debugPrint('Error logging activity: $e');
  }
}
