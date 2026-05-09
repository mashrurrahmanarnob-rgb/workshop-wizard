import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    print("SUCCESS: Query ran without error.");
  } catch (e) {
    print("ERROR CAUGHT:");
    print(e);
  }
  
  // Also get the profile screen query to check for its index
  try {
    await FirebaseFirestore.instance.collection('registrations').where('userId', isEqualTo: 'test').count().get();
  } catch(e) {
    print("ERROR CAUGHT registrations:");
    print(e);
  }
}
