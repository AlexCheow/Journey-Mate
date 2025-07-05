import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  Map<DateTime, double> dailyDistances = {};
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;

  @override
  void initState() {
    super.initState();
    _loadMonthlyData(focusedDay);
  }

  Future<void> _loadMonthlyData(DateTime month) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      print('No logged in user');
      return;
    }

    print('Current logged in uid: $uid');

    final snapshot = await FirebaseFirestore.instance
        .collection('sessions')
        .where('userId', isEqualTo: uid)
        .get();

    print('Loaded ${snapshot.docs.length} sessions from Firestore');

    Map<DateTime, double> distances = {};

    for (var doc in snapshot.docs) {
      final timestamp = (doc['timestamp'] as Timestamp?)?.toDate();
      final distanceStr = doc['distance']?.toString() ?? '0';
      final distance = double.tryParse(distanceStr) ?? 0.0;

      if (timestamp != null) {
        final date = DateTime(timestamp.year, timestamp.month, timestamp.day);
        distances.update(date, (prev) => prev + distance, ifAbsent: () => distance);
        print('Session on ${DateFormat('yyyy-MM-dd').format(date)}: distance=$distance');
      } else {
        print('Skipped doc with null timestamp');
      }
    }

    setState(() {
      dailyDistances = distances;
    });

    print('Finished loading. dailyDistances:');
    dailyDistances.forEach((key, value) {
      print('${DateFormat('yyyy-MM-dd').format(key)}: $value km');
    });
  }

  List<double> _getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    if (dailyDistances.containsKey(date)) {
      return [dailyDistances[date]!];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Calendar'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          TableCalendar<double>(
            focusedDay: focusedDay,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            onDaySelected: (selected, focused) {
              setState(() {
                selectedDay = selected;
                focusedDay = focused;
              });
            },
            onPageChanged: (focused) {
              focusedDay = focused;
              _loadMonthlyData(focused);
            },
            eventLoader: _getEventsForDay,
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Colors.deepPurpleAccent, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: selectedDay != null && _getEventsForDay(selectedDay!).isNotEmpty
                ? ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.directions_run),
                  title: Text(DateFormat.yMMMMd().format(selectedDay!)),
                  subtitle: Text('Total distance: ${_getEventsForDay(selectedDay!).first.toStringAsFixed(2)} km'),
                ),
              ],
            )
                : const Center(child: Text('No data for this day')),
          ),
        ],
      ),
    );
  }
}
