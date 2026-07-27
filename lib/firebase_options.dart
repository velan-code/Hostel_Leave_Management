// File generated for Hostel-App (`hostel-app-65a6e`)
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] configured for your Firebase project: `hostel-app-65a6e`
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDYHM755aygLHshVY9DMz5BXupqMVf9ylM',
    appId: '1:471061584655:web:e0b8cd4152204941cebc7a',
    messagingSenderId: '471061584655',
    projectId: 'hostel-app-65a6e',
    authDomain: 'hostel-app-65a6e.firebaseapp.com',
    storageBucket: 'hostel-app-65a6e.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCUsF5PkgVvE8K7U_G61ELDRHixyzXoMnk',
    appId: '1:471061584655:android:8252b5ccd0df8895cebc7a',
    messagingSenderId: '471061584655',
    projectId: 'hostel-app-65a6e',
    storageBucket: 'hostel-app-65a6e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDYHM755aygLHshVY9DMz5BXupqMVf9ylM',
    appId: '1:471061584655:ios:3312c2a27593194ccebc7a',
    messagingSenderId: '471061584655',
    projectId: 'hostel-app-65a6e',
    storageBucket: 'hostel-app-65a6e.firebasestorage.app',
    iosBundleId: 'com.example.hostelApplication',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDYHM755aygLHshVY9DMz5BXupqMVf9ylM',
    appId: '1:471061584655:ios:3312c2a27593194ccebc7a',
    messagingSenderId: '471061584655',
    projectId: 'hostel-app-65a6e',
    storageBucket: 'hostel-app-65a6e.firebasestorage.app',
    iosBundleId: 'com.example.hostelApplication',
  );
}
