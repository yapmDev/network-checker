import 'package:flutter/material.dart';
import 'package:network_checker/network_checker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: NetworkChecker(
        alertBuilder: (context, status) => Material(child: ColoredBox(color: Colors.blue, child: Text(status.toString()))),
          child: Center(child: Text("Online")) 
      )
    );
  }
}