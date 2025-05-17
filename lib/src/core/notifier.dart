import 'package:flutter/widgets.dart';
import 'package:network_checker/src/core/status.dart';

/// A notifier for connection status listeners used by [NetworkChecker].
class NetworkNotifier extends ValueNotifier<ConnectionStatus> {

  NetworkNotifier(super.value);

  /// Notify the listeners with a new connection status.
  void updateStatus(ConnectionStatus newValue) => value = newValue;
}