import 'package:calender/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';

void main() async{
   await Hive.initFlutter();
  await Hive.openBox<Map>('events'); // Open a box for events
  runApp( Calender(title: 'Calender',));
}

class Calender extends StatelessWidget {
  const Calender({super.key, required String title});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calender',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Homepage(),
    );
  }
}
