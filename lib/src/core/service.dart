import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:network_checker/src/core/status.dart';

/// A singleton service that monitors network connectivity and server availability. Used internally by NetworkChecker.
class ConnectionService {

  // Singleton instance.
  static ConnectionService? _instance;

  // Connectivity's singleton instance
  final Connectivity _connectivity = Connectivity();

  // Listeners for status changes.
  final List<void Function(ConnectionStatus)> _listeners = [];

  // Configuration
  ConnectionConfig _config;

  // Stream subscription for connectivity changes
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Factory constructor to return the singleton instance.
  factory ConnectionService() {
    if (_instance == null) {
      throw StateError("ConnectionService not initialized. Call initialize() first.");
    }
    return _instance!;
  }

  // Private constructor.
  ConnectionService._internal(this._config) {
    _startMonitoring();
  }

  /// Initialize the service if not already initialized.6
  static initialize(ConnectionConfig config) => _instance ??= ConnectionService._internal(config);

  /// Updates the configuration for this service. Useful when you need to check connectivity with a different server.
  void updateConfig(ConnectionConfig config) {
    _config = config;
    checkNetworkStatus();
  }

  /// Disposes resources used by this service.
  void dispose() {
    _listeners.clear();
    _connectivitySubscription?.cancel();
    _instance = null;
  }

  /// Check the current network status. This method is called by `NetworkChecker` any time the network interfaces
  /// changes. You can also call it by yourself, useful if it is possible for the connection status to change without
  /// changing the network output interfaces.
  Future<void> checkNetworkStatus() async {
    ConnectionStatus newStatus;
    try {
      final response = await http.head(Uri.parse(_config.pingUrl)).timeout(_config.timeLimit);
      newStatus = response.statusCode == 204 ? ConnectionStatus.online : ConnectionStatus.serverError;
    } on SocketException {
      newStatus = ConnectionStatus.noInternet;
    } on TimeoutException {
      newStatus = ConnectionStatus.serverNotAvailable;
    } catch (_) {
      newStatus = ConnectionStatus.serverError;
    }
    _notifyListeners(newStatus);
  }

  /// Add a listener for connection status changes
  void addStatusListener(void Function(ConnectionStatus) listener) {
    _listeners.add(listener);
  }

  /// Remove a previously registered listener
  void removeStatusListener(void Function(ConnectionStatus) listener) {
    _listeners.remove(listener);
  }

  // Start monitoring for connectivity changes
  void _startMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((_) {
      checkNetworkStatus();
    });
    checkNetworkStatus();
  }

  // Notify all registered listeners about the network status change
  void _notifyListeners(ConnectionStatus newStatus) {
    for (final listener in _listeners) {
      listener(newStatus);
    }
  }
}

/// Configuration for the connection service
class ConnectionConfig {

  /// URL to ping to verify connection status.
  final String pingUrl;

  /// Timeout for the ping request.
  final Duration timeLimit;

  const ConnectionConfig({
    required this.pingUrl,
    required this.timeLimit
  });
}