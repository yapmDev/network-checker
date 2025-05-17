import 'package:flutter/material.dart';
import 'package:network_checker/src/core/notifier.dart';
import 'package:network_checker/src/core/scope.dart';
import 'package:network_checker/src/core/service.dart';
import 'package:network_checker/src/core/status.dart';
import 'package:network_checker/src/ui/alert.dart';

/// Provides a complete network availability checker based on plugin [connectivity_plus] to
/// optimize network requests. Before continuing, check the requirements and support on each
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
/// Or if your app interacts with more than one server through the app or needs different alerts or
/// specific timeouts, you can use it wherever you need it. A scope will automatically be created
/// to reference the closest instance.
///
/// Either way you can specify which views below in the hierarchy of this widget take up a
/// connection change alert by leaving alertBuilder as `null` and wrapping those views in a
/// [NetworkAlertTemplate].
///
/// At any lower part of the hierarchy, the connection status can be accessed like this:
///
/// ```dart
/// final isConnected = NetworkProvider.of(context).value == ConnectionStatus.online;
/// ```
///
/// Furthermore, this way the framework detects that widget depends on that value and, when it
/// changes, it automatically rebuilds it. If it does not depend on it, the widget will remain
/// `immutable` even if the connection status changes.
///
/// For more advanced and personalized control:
///
/// @See [NetworkChecker.addStatusListener] and [NetworkChecker.forceRetry].
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

  /// Creates a [NetworkChecker] wrapping your app to monitor a real connection status.
  ///
  /// If you don't have a server of your own to worry about, leave [config] as [null], which will
  /// use the default configuration. If [alertBuilder] is provided this will
  /// act as a global alert when a connection to the server cannot be established for whatever
  /// reason. If your application only uses the internet in some views, leave this field as [null]
  /// and wrap those views in a [NetworkAlertTemplate]. The default value for [alertPosition] is
  /// [Alignment.bottomCenter].
  ///
  /// @See the full documentation on the fields signature and the class itself.
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
    ConnectionService.initialize(widget.config ?? ConnectionConfig(
        pingUrl: "https://www.gstatic.com/generate_204",
        timeLimit: Duration(seconds: 3)
    ));
    _connectionService = ConnectionService();
    _connectionService.addStatusListener((status) => _notifier.updateStatus(status));
  }

  @override
  void dispose() {
    _connectionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NetworkScope(
      notifier: _notifier,
      child: widget.alertBuilder != null 
        ? NetworkAlertTemplate(
            alertBuilder: widget.alertBuilder,
            alertPosition: widget.alertPosition,
            child: widget.child,
          ) 
        : widget.child
    );
  }
}