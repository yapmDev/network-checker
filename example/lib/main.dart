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
          child: const MyHomePage()
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {

    final isConnected = NetworkProvider.of(context).value == ConnectionStatus.online;

    return Scaffold(body: Center(child: Text(isConnected ? "Online":"Offline")));
  }
}