import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:network_checker/src/config/config.dart';
import 'package:network_checker/src/scope/scope.dart';
import 'package:network_checker/src/service/service.dart';
import 'package:network_checker/src/status/status.dart';
import 'package:network_checker/src/ui/alert.dart';

/// {@template class-signature-doc}
///
/// This is a high-level widget that provides a complete network availability checker based on plugin
/// [connectivity_plus] to optimize ping requests. Before continuing, check the requirements and support on each
/// platform for this plugin https://pub.dev/packages/connectivity_plus.
///
/// The recommended usage is once at the top level of your application, as shown below:
///
/// ```dart
/// MaterialApp.router(
///   builder: (context, child) => NetworkChecker(
///     config: ConnectionConfig(
///       pingUrl: 'http://10.0.2.2:8080/network-checker',
///       timeLimit: Duration(seconds: 3),
///     ),
///     alertBuilder: (context, status) => _buildAlert(context, status), //global alert
///     child: child!
///   ),
///   routerConfig: appRouter,
/// );
/// ```
///
/// You can specify which views below in the hierarchy of this widget take up a
/// connection change alert by leaving alertBuilder as `null` and wrapping those views in a
/// [NetworkAlertTemplate].
///
/// If your application interacts with more than one server, you can create a new configuration context using
/// [ConnectionConfigScope], which automatically updates and restores the internal service configurations used by
/// [NetworkChecker].
///
/// `WARNING`: In the current version of this API, only connections to two servers at a time are supported. This means
/// that if you continue browsing by adding new configuration contexts consecutively, you will lose the main
/// configurations passed to [NetworkChecker] upon its instantiation.
///
/// This widget provides a [NetworkScope] through which you can access the current connection status.
///
/// At any lower part of the hierarchy, the connection status can be accessed like this:
///
/// ```dart
/// final isConnected = NetworkScope.statusOf(context) == ConnectionStatus.online;
/// ```
///
/// Furthermore, this way the framework detects that widget depends on that value and, when it
/// changes, it automatically rebuilds it. If it does not depend on it, the widget will remain
/// `immutable` even if the connection status changes.
///
/// For more advanced control, also through [NetworkScope] you can register callbacks, and force manual checks.
///
/// To additionally react to status changes, consider the following basic example:
///
/// ```dart
/// class _SomePageState extends State<SomePage> {
///
///   late void Function() _listener;
///   late NetworkScope _scope;
///   void _printSomething(ConnectionStatus status) => print(status.toString());
///
///   void _handleScopeAndListener(){
///     _scope = NetworkScope.of(context); // save the scope (depends on context) to safely access on dispose.
///     _listener = _scope.registerListener(_printSomething);
///   }
///
///   @override
///   void initState() {
///     super.initState();
///     // safe access to context
///     WidgetsBinding.instance.addPostFrameCallback((_)=>_handleScopeAndListener());
///   }
///
///   @override
///   void dispose() {
///     _scope.removeListener(_listener);
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return SomeWidget();
///   }
/// }
/// ```
///
/// To force a new check of the connection status you can do this directly:
/// ```dart
/// ElevatedButton(
///    onPressed: NetworkScope.of(context).forceRetry,
///    child: Text("Retry")
///  )
/// ```
///
/// {@endtemplate}
class NetworkChecker extends StatefulWidget {

  /// Configuration for connection checking. If not provided, will use the default configuration
  /// defined in [ConnectionConfig].
  final ConnectionConfig? config;

  /// An optional custom alert widget that is displayed when the app is not fully connected. Any
  /// status other than [ConnectionStatus.online].
  final Widget Function(BuildContext, ConnectionStatus)? alertBuilder;

  /// Position of [alertBuilder]. If [null] [Alignment.bottomCenter] will be applied.
  final Alignment? alertPosition;

  /// The child of this widget. Normally your app entrypoint.
  final Widget child;

  ///{@macro class-signature-doc}
  const NetworkChecker({
    super.key,
    this.config,
    this.alertBuilder,
    this.alertPosition,
    required this.child
  });

  @override
  State<NetworkChecker> createState() => _NetworkCheckerState();
}

class _NetworkCheckerState extends State<NetworkChecker> {

  final NetworkNotifier _notifier = NetworkNotifier(ConnectionStatus.checking);
  late final ConnectionService _connectionService;

  @override
  void initState() {
    super.initState();
    // Initializing the service
    _connectionService = ConnectionService.init(
        widget.config ?? ConnectionConfig(
            pingUrl: "https://www.gstatic.com/generate_204", timeLimit: Duration(seconds: 3)
        )
    )..addStatusListener((status) {
      if(status != _notifier.value) {
        if (kDebugMode) {
          print("[NETWORK-CHECKER]: emiting new status: ${status.toString()}");
        }
        _notifier.value = status;
      } else {
        if (kDebugMode) {
          print("[NETWORK-CHECKER]: no connection status changes");
        }
      }
    });
  }

  @override
  void dispose() {
    _connectionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NetworkScope(
      forceRetry: _connectionService.checkNetworkStatus,
      notifier: _notifier,
      child: widget.alertBuilder != null 
        ? NetworkAlertTemplate(
            alertBuilder: widget.alertBuilder,
            alertPosition: widget.alertPosition,
            child: widget.child
          ) 
        : widget.child
    );
  }
}