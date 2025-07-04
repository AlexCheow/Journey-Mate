//lib/widgets/firebase_options.dart
// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAtaD59vItlylSC9IjgmxIL7ls8yCvPuLQ',
    appId: '1:489688680055:android:a1c5ad019429067c4e6872',
    messagingSenderId: '489688680055',
    projectId: 'journeymate-inti-3ad2d',
    storageBucket: 'journeymate-inti-3ad2d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB7Hsxf4qmi-eVZwKyx-EU4i2vwAErmXbw',
    appId: '1:489688680055:ios:aad10d99e31045f84e6872',
    messagingSenderId: '489688680055',
    projectId: 'journeymate-inti-3ad2d',
    storageBucket: 'journeymate-inti-3ad2d.firebasestorage.app',
    iosBundleId: 'com.example.journeymate',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBmgZ8te2Doc8UOG2BHA66ZmWewq6CpVXo',
    appId: '1:489688680055:web:1d6aed9de9cf682e4e6872',
    messagingSenderId: '489688680055',
    projectId: 'journeymate-inti-3ad2d',
    authDomain: 'journeymate-inti-3ad2d.firebaseapp.com',
    storageBucket: 'journeymate-inti-3ad2d.firebasestorage.app',
    measurementId: 'G-KS7VTQHBXS',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBmgZ8te2Doc8UOG2BHA66ZmWewq6CpVXo',
    appId: '1:489688680055:web:ef781825e82a2c594e6872',
    messagingSenderId: '489688680055',
    projectId: 'journeymate-inti-3ad2d',
    authDomain: 'journeymate-inti-3ad2d.firebaseapp.com',
    storageBucket: 'journeymate-inti-3ad2d.firebasestorage.app',
    measurementId: 'G-5FSH95SEFW',
  );

}