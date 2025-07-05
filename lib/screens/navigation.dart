//lib/screens/navigation.dart
import 'package:flutter/material.dart';
import 'PhotoTestScreen.dart';
import 'home.dart';
import 'history.dart';
import 'record.dart';
import 'clubs.dart';
import 'profile.dart';
import 'package:camera/camera.dart';


class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    HistoryScreen(),
    RecordScreen(),
    ClubsScreen(),
    ProfileScreen(),
    PhotoTestScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Route'),
          BottomNavigationBarItem(icon: Icon(Icons.fiber_manual_record), label: 'Record'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Clubs'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.photo), label: 'Test'),
        ],
      ),
    );
  }
}
