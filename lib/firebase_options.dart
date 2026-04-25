import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAGMIFp7jpO8xkZ8EArWXDE87cHdF6nOyU',
    appId: '1:596925173469:web:5e18878d7f893e56dad534',
    messagingSenderId: '596925173469',
    projectId: 'overflow-society',
    authDomain: 'overflow-society.firebaseapp.com',
    storageBucket: 'overflow-society.firebasestorage.app',
    measurementId: 'G-Z1TXM513F7',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBP3QKca_znQ3WtLvAumf73YRTzeQXQSsk',
    appId: '1:596925173469:android:edd37d189819663ddad534',
    messagingSenderId: '596925173469',
    projectId: 'overflow-society',
    storageBucket: 'overflow-society.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA9DtpuEO45p7nEJf9sLv7Ugn3RExJdUgw',
    appId: '1:596925173469:ios:61197384dfae64b7dad534',
    messagingSenderId: '596925173469',
    projectId: 'overflow-society',
    storageBucket: 'overflow-society.firebasestorage.app',
    iosBundleId: 'com.VW.workshopWizard',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA9DtpuEO45p7nEJf9sLv7Ugn3RExJdUgw',
    appId: '1:596925173469:ios:61197384dfae64b7dad534',
    messagingSenderId: '596925173469',
    projectId: 'overflow-society',
    storageBucket: 'overflow-society.firebasestorage.app',
    iosBundleId: 'com.VW.workshopWizard',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAGMIFp7jpO8xkZ8EArWXDE87cHdF6nOyU',
    appId: '1:596925173469:web:d861c5fbef0f485bdad534',
    messagingSenderId: '596925173469',
    projectId: 'overflow-society',
    authDomain: 'overflow-society.firebaseapp.com',
    storageBucket: 'overflow-society.firebasestorage.app',
    measurementId: 'G-K5D0PK78QD',
  );

}
