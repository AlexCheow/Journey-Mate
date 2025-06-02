import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'provider/record_session_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyBmgZ8te2Doc8UOG2BHA66ZmWewq6CpVXo',
        authDomain: 'journeymate-inti-3ad2d.firebaseapp.com',
        projectId: 'journeymate-inti-3ad2d',
        storageBucket: 'journeymate-inti-3ad2d.appspot.com',
        messagingSenderId: '489688680055',
        appId: '1:489688680055:web:1d6aed9de9cf682e4e6872',
        measurementId: 'G-KS7VTQHBXS',
      ),
    );
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Wrap app with Provider for recording session state
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecordSessionProvider()),
      ],
      child: const App(),
    ),
  );
}
