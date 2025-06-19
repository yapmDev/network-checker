import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:network_checker/src/config/config.dart';
import 'package:network_checker/src/status/status.dart';

/// A singleton service that monitors network connectivity and server availability. Used internally by NetworkChecker.
class ConnectionService {

  // Singleton instance.
  static ConnectionService? _instance;

  // Connectivity's singleton instance
  final Connectivity _connectivity = Connectivity();

  // Listeners for status changes.
  final List<void Function(ConnectionStatus)> _listeners = [];

  // Configuration
  late ConnectionConfig _previousConfig;
  ConnectionConfig _config;

  // Stream subscription for connectivity changes
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Factory constructor to return the singleton instance.
  factory ConnectionService() {
    if (_instance == null) {
      throw StateError("ConnectionService not initialized. NetworkChecker is the owner of this service, so wrap your "
          "app or specific view with it before use ConnectionConfigScope");
    }
    return _instance!;
  }

  // Private constructor.
  ConnectionService._internal(this._config) {
    _previousConfig = _config;
    _startMonitoring();
  }

  /// Initialize the service if not already initialized.
  static ConnectionService init(ConnectionConfig config) => _instance ??= ConnectionService._internal(config);

  /// Updates the configuration for this service. Useful when you need to check connectivity with a different server.
  void updateConfig(ConnectionConfig config) {
    if (kDebugMode) {
      print("[NETWORK-CHECKER-SERVICE]: updating config");
    }
    _previousConfig = _config;
    _config = config;
    checkNetworkStatus();
  }

  /// Restores previous configuration.
  void restoreConfig() {
    if (kDebugMode) {
      print("[NETWORK-CHECKER-SERVICE]: restoring previous config");
    }
    _config = _previousConfig;
    checkNetworkStatus();
  }

  /// Disposes resources used by this service.
  void dispose() {
    if (kDebugMode) {
      print("[NETWORK-CHECKER-SERVICE]: disposing resources");
    }
    _listeners.clear();
    _connectivitySubscription?.cancel();
    _instance = null;
  }

  /// Check the current network status. This method is called by [NetworkChecker] any time the network interfaces
  /// changes.
  Future<void> checkNetworkStatus() async {
    if (kDebugMode) {
      print("[NETWORK-CHECKER-SERVICE]: checking network status");
    }

    ConnectionStatus newStatus = ConnectionStatus.checking;

    try {

      final response = await http.head(Uri.parse(_config.pingUrl)).timeout(_config.timeLimit);

      if (response.statusCode == 204) {
        newStatus = ConnectionStatus.online;
      } else if (response.statusCode >= 500) {
        newStatus = ConnectionStatus.serverError;
      } else if (response.statusCode >= 400) {
        newStatus = ConnectionStatus.clientError;
      } else {
        newStatus = ConnectionStatus.unexpectedResponse;
      }

    } on TimeoutException {
      newStatus = ConnectionStatus.serverUnreachable;
    } on SocketException catch (e) {
      if (e.osError != null && _isNetworkUnavailableError(e.osError!)) {
        newStatus = ConnectionStatus.noInternet;
      } else {
        newStatus = ConnectionStatus.networkUnreachable;
      }
    } catch (e) {
      if (kDebugMode) {
        print("[NETWORK-CHECKER-SERVICE][UNEXPECTED ERROR]: $e");
      }
      newStatus = ConnectionStatus.unknownFailure;
    }

    _notifyListeners(newStatus);
  }

  bool _isNetworkUnavailableError(OSError osError) {
    return [
      7,    // No address associated with hostname
      101,  // Network is unreachable
      110,  // Connection timed out
      113,  // No route to host
    ].contains(osError.errorCode);
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
    if (kDebugMode) {
      print("[NETWORK-CHECKER-SERVICE]: start monitoring");
    }
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((_) {
      checkNetworkStatus();
    });
  }

  // Notify all registered listeners about the network status change
  void _notifyListeners(ConnectionStatus newStatus) {
    for (final listener in _listeners) {
      listener(newStatus);
    }
  }
}