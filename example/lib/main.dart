import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:network_checker/network_checker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Demo',
      builder: (context, child) => Scaffold(
        body: NetworkChecker(
          alertBuilder: (context, status) => ColoredBox(color: Colors.blue, child: Text(status.toString())),
            child: child!
        ),
      ),
      routerConfig: routerConfig,
    );
  }
}

final routerConfig = GoRouter(
    initialLocation: Routes.pageA,
    routes: [
      GoRoute(path: Routes.pageA, builder: (context, state) => PageA()),
      GoRoute(path: Routes.pageB, builder: (context, state) => PageB())
    ]
);

class Routes {
  static const pageA = "/pageA";
  static const pageB = "/pageB";
}

class PageA extends StatelessWidget {
  const PageA({super.key});

  @override
  Widget build(BuildContext context) {
    final isConnected = NetworkScope.statusOf(context) == ConnectionStatus.online;
    return Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 8.0,
      children: [
        Text(isConnected ? "Online" : "Offline"),
        ElevatedButton(onPressed: ()=> context.push(Routes.pageB), child: Text("Navigate"))
      ],
    ));
  }
}

class PageB extends StatefulWidget {

  const PageB({super.key});

  @override
  State<PageB> createState() => _PageBState();
}

class _PageBState extends State<PageB> {

  late void Function() _listener;
  late NetworkScope _scope;
  void _printSomething(ConnectionStatus status) => print(status.toString());

  void _handleScopeAndListener(){
    _scope = NetworkScope.of(context); // save the scope (depends on context) to safely access on dispose.
    _listener = _scope.registerListener(_printSomething);
  }

  @override
  void initState() {
    super.initState();
    // safe access to context
    WidgetsBinding.instance.addPostFrameCallback((_)=>_handleScopeAndListener());
  }

  @override
  void dispose() {
    _scope.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = NetworkScope.statusOf(context) == ConnectionStatus.online;
    return ConnectionConfigScope(
      config: ConnectionConfig(pingUrl: "https://www.gstatic.com/generate_204", timeLimit: Duration(seconds: 3)),
      child: Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8.0,
        children: [
          Text(isConnected ? "Online" : "Offline"),
          ElevatedButton(onPressed: ()=> context.pop(), child: Text("Go Back")),
          ElevatedButton(
            onPressed: NetworkScope.of(context).forceRetry,
              child: Text("Retry")
          )
        ],
      )),
    );
  }
}