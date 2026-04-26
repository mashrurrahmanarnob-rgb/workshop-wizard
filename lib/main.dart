import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const WorkshopWizardApp());
}

class WorkshopWizardApp extends StatelessWidget {
  const WorkshopWizardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workshop Wizard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF76C279),
        scaffoldBackgroundColor: const Color(0xFF76C279),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.login,
      routes: AppRoutes.getRoutes(),
    );
  }
}