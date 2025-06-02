import 'package:flutter/material.dart';
import 'package:journeymate/screens/navigation.dart';
import 'screens/login.dart';
import 'screens/signup.dart';
import 'screens/verifyemail.dart';
import 'screens/forgetpassword.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JourneyMate',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainNavigation(),
        '/signup': (context) => const SignUpScreen(),
        '/verify-email': (context) => const VerifyEmailScreen(),
        '/forget-password': (context) => const ForgetPasswordScreen(),
        '/history' : (context) => const MainNavigation(),
        '/record' : (context) => const MainNavigation(),
        '/clubs' : (context) => const MainNavigation(),
        '/profile' : (context) => const MainNavigation(),
      },
    );
  }
}
