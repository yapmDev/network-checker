library;

/*
  author: yapmDev
  lastModifiedDate: 23/02/25
  repository: https://github.com/yapmDev/network_checker
 */

import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Provides a complete network availability checker based on plugin [connectivity_plus 5.0.2] to
/// optimize [pingUrl] requests. So before continuing, check the requirements and support on each
/// platform for this plugin https://pub.dev/packages/connectivity_plus.
///
/// The recommended usage is once at the top level of your application, as shown below:
///
/// ```dart
/// MaterialApp.router(
///   builder: (context, child) => NetworkChecker(
///     pingUrl: 'http://10.0.2.2:8080/network-checker',
///     alertBuilder: (context, status) => _buildAlert(context, status), //global alert
///     child: child!
///   ),
///   routerConfig: appRouter,
/// );
/// ```
///
/// Or if your app interact with more than one server through the app or need different alerts or
/// specific timeouts, you can use it wherever you need it. A scope will automatically be created
/// to reference the closest instance.
///
/// Either way you can specify which views below in the hierarchy of this widget take up a
/// connection change alert by leaving alertBuilder as `null` and wrapping those views in a
/// [NetworkAlertTemplate].
///
/// At any lower part of the hierarchy the connection status can be accessed like this:
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

  /// Points to some endpoint that is responsible for returning a [204 No Content] to validate a
  /// completed connection. The default value is [https://www.gstatic.com/generate_204].
  final String pingUrl;

  /// Specifies the time limit before the [pingUrl] request returns a `timeout` in case there is an
  /// Internet connection, but the server is unavailable or busy. Default set to
  /// [Duration(seconds: 3)], it should not be high so that the wait does not affect the user
  /// experience, nor should it be low so that it does not give false negatives.
  final Duration timeLimit;

  /// An optional custom alert widget that is displayed when the app is not fully connected. Any
  /// status other than [ConnectionStatus.online].
  final Widget Function(BuildContext, ConnectionStatus)? alertBuilder;

  /// Position of [alertBuilder]. If [null] [Alignment.bottomCenter] will be apply.
  final Alignment? alertPosition;

  /// The child of this widget. Normally your app entrypoint.
  final Widget child;

  /// Creates a [NetworkChecker] wrapping your app to monitor a real connection status.
  ///
  /// If you don't have a server of your own to worry about, leave [pingUrl] as [null], which will
  /// point to [https://www.gstatic.com/generate_204], Otherwise make sure it returns a [204 No
  /// Content] and doesn't have any additional logic. If [alertBuilder] is provided this will
  /// act as a global alert when a connection to the server cannot be established for whatever
  /// reason. If your application only uses the internet in some views, leave this field as [null]
  /// and wrap those views in a [NetworkAlertTemplate]. The default value for [alertPosition] is
  /// [Alignment.bottomCenter].
  ///
  /// @See the full documentation on the fields signature and the class itself.
  const NetworkChecker({
    super.key,
    this.alertBuilder,
    this.alertPosition,
    this.pingUrl = "https://www.gstatic.com/generate_204",
    this.timeLimit = const Duration(seconds: 3),
    required this.child
  });

  static _NetworkCheckerState? _instance;

  static final List<void Function(ConnectionStatus)> _statusListeners = [];

  /// Forces a new check on the nearest [NetworkChecker] instance. Useful if it is possible for the
  /// connection status to change without changing the network output interfaces.
  ///
  /// A [NetworkChecker] is required as an ancestor.
  static void forceRetry() {
    assert(_instance != null,
    "NetworkChecker.retryCheck() requires a NetworkChecker ancestor in the widget tree."
    );
    _instance!._checkNetworkStatus();
  }

  /// Registers a new listener for connection state changes detected by the nearest instance of
  /// [NetworkChecker].
  ///
  /// This listener must be removed on `dispose` using [NetworkChecker.removeStatusListener].
  static void addStatusListener(void Function(ConnectionStatus) listener) {
    _statusListeners.add(listener);
  }

  /// Removes a previously registered listener for connection status changes.
  static void removeStatusListener(void Function(ConnectionStatus) listener) {
    _statusListeners.remove(listener);
  }

  @override
  State<NetworkChecker> createState() => _NetworkCheckerState();
}

class _NetworkCheckerState extends State<NetworkChecker>{

  final Connectivity _connectivity = Connectivity();
  final NetworkNotifier _notifier = NetworkNotifier(ConnectionStatus.checking);

  @override
  void initState() {
    NetworkChecker._instance = this;
    _checkNetworkStatus();
    _startMonitoring();
    super.initState();
  }

  @override
  void dispose() {
    NetworkChecker._instance = null;
    super.dispose();
  }

  void _startMonitoring() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> result) {
      _notifier._updateStatus(ConnectionStatus.checking);
      _checkNetworkStatus();
    });
  }

  Future<void> _checkNetworkStatus() async {
    ConnectionStatus newStatus;
    try {
      final response = await http
          .head(Uri.parse(widget.pingUrl)).timeout(widget.timeLimit);

      newStatus = response.statusCode == 204 ?
      ConnectionStatus.online : ConnectionStatus.serverError;

    } on SocketException {
      newStatus = ConnectionStatus.noInternet;
    } on TimeoutException {
      newStatus = ConnectionStatus.serverNotAvailable;
    }

    if(newStatus != _notifier.value) {
      _notifier._updateStatus(newStatus);
      for (final listener in NetworkChecker._statusListeners) {
        listener(newStatus);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NetworkProvider(
        notifier: _notifier,
        child: widget.alertBuilder != null ? NetworkAlertTemplate(
          alertBuilder: widget.alertBuilder,
          alertPosition: widget.alertPosition,
          child: widget.child,
        ) : widget.child
    );
  }
}

/// Create a template for a particular view where a network alert will appear if the current
/// connection status detected by [NetworkChecker] is different from [ConnectionStatus.online].
class NetworkAlertTemplate extends StatelessWidget {

  /// It is assumed that [NetworkChecker.alertBuilder] of the nearest [NetworkChecker] is [null].
  /// Default value for [alertPosition] is [Alignment.bottomCenter]. The child is not rendered
  /// unnecessarily if its state does not depend on [NetworkProvider.of(context).value].
  const NetworkAlertTemplate({
    super.key,
    required this.alertBuilder,
    this.alertPosition,
    required this.child,
  });

  /// An optional custom alert widget that is displayed when the app is not fully connected. It
  /// means, any status other than [ConnectionStatus.online].
  final Widget Function(BuildContext, ConnectionStatus)? alertBuilder;

  /// Position of [alertBuilder]. If [null] [Alignment.bottomCenter] will be apply.
  final Alignment? alertPosition;

  /// The child of this widget bellow in the hierarchy.
  final Widget child;

  @override
  Widget build(BuildContext context) {

    final networkNotifier = NetworkProvider.of(context);

    return ValueListenableBuilder(
      valueListenable: networkNotifier,
      child: child,
      builder: (context, connectionStatus, child) {
        return Stack(fit: StackFit.expand ,children: [
          child!,
          if(connectionStatus != ConnectionStatus.online)
            Align(alignment: alertPosition ?? Alignment.bottomCenter,
              child: alertBuilder?.call(context, connectionStatus),
            )
        ]);
      },
    );
  }
}

/// A notifier for connection status listeners used by [NetworkChecker].
class NetworkNotifier extends ValueNotifier<ConnectionStatus> {

  NetworkNotifier(super.value);

  /// Notify the listeners with a new connection status.
  void _updateStatus(ConnectionStatus newValue) => value = newValue;
}

/// An inherited widget that provides [NetworkNotifier] to its descendants.
class NetworkProvider extends InheritedNotifier<NetworkNotifier> {

  /// Creates a [NetworkProvider] with the given [notifier] and [child].
  const NetworkProvider({
    super.key,
    required super.notifier,
    required super.child
  });

  /// Retrieves the nearest [NetworkNotifier] up the widget tree.
  ///
  /// A [NetworkChecker] is required as an ancestor.
  static NetworkNotifier of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<NetworkProvider>();
    assert(provider != null,
    "No NetworkChecker ancestor found. Wrap your app (or the necessary widgets) first."
    );
    return provider!.notifier!;
  }
}

/// Represents the possible connection statuses detected by [NetworkChecker].
enum ConnectionStatus {

  /// The application has internet access and can successfully connect to a server.
  ///
  /// This state is only used when none of the other possible values apply.
  ///
  /// **Example cases:**
  /// - The device has an active internet connection.
  /// - The server is reachable and responds with a successful status code (**204**).
  online,

  /// The application has no internet access.
  ///
  /// This means the device is completely disconnected from the internet.
  ///
  /// **Example cases:**
  /// - The device is in airplane mode.
  /// - There is no Wi-Fi or mobile data connection available.
  /// - A firewall, VPN, or network policy is blocking all outgoing traffic.
  noInternet,

  /// The application has internet access, but the server is not available.
  ///
  /// This means the device can access the internet, but the target server is unreachable.
  ///
  /// **Example cases:**
  /// - The server is down for maintenance and returns a `503 Service Unavailable`.
  /// - The server does not respond within the timeout period.
  /// - A VPN, firewall, or ISP restriction is blocking access to the specific server.
  serverNotAvailable,

  /// The application has internet access and the server is reachable, but it returned a
  /// status code other than [204].
  ///
  /// This indicates that the server responded, but with an error or unexpected status.
  ///
  /// **Example cases:**
  /// - The server returns a `500 Internal Server Error` due to an issue on the backend.
  /// - The request is unauthorized (`401 Unauthorized`) or forbidden (`403 Forbidden`).
  /// - The requested resource was not found (`404 Not Found`).
  /// - The server is overloaded and returns `429 Too Many Requests`.
  serverError,

  /// The application is in a transient state where network availability is being checked, so its
  /// true state is undetermined.
  checking
}