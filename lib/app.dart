import 'package:flutter/material.dart';
import 'package:journeymate/screens/navigation.dart';
import 'screens/login.dart';
import 'screens/signup.dart';
import 'screens/verifyemail.dart';
import 'screens/forgetpassword.dart';
import 'screens/upcoming_events.dart';
import 'screens/calendar_page.dart';
import 'screens/media_gallery.dart';
import 'screens/admin_dashboard.dart';

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
        '/signup': (context) => const SignUpScreen(),
        '/verify-email': (context) => const VerifyEmailScreen(),
        '/forget-password': (context) => const ForgetPasswordScreen(),
        '/home': (context) => const MainNavigation(),
        '/upcoming-events': (context) => const UpcomingEventsPage(),
        '/calendar': (context) => const CalendarPage(),
        '/media-gallery': (context) => const MediaGalleryPage(),
        '/admin-dashboard': (context) => const AdminDashboardPage(),
      },
    );
  }
}
