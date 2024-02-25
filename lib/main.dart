import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myapp1/screens/MainScreen.dart';

void main() {
  runApp(const MyApp());git
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: Colors.black));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "sample1",
      theme: ThemeData.light(useMaterial3: true),
      home: const MainScreen(),
    );
  }
}


