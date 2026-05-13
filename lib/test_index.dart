import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  try {
    await FirebaseFirestore.instance
      .collection('proposals')
      .where('createdBy', isEqualTo: 'test')
      .orderBy('createdAt', descending: true)
      .get();
    debugPrint("SUCCESS: Query ran without error.");
  } catch (e) {
    debugPrint("ERROR CAUGHT:");
    debugPrint('$e');
  }
  
  // Also get the profile screen query to check for its index
  try {
    await FirebaseFirestore.instance.collection('registrations').where('userId', isEqualTo: 'test').count().get();
  } catch(e) {
    debugPrint("ERROR CAUGHT registrations:");
    debugPrint('$e');
  }
}
