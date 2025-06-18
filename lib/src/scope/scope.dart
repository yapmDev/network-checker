import 'package:flutter/widgets.dart';
import 'package:network_checker/network_checker.dart';

/// A notifier for connection status listeners used by [NetworkChecker].
class NetworkNotifier extends ValueNotifier<ConnectionStatus> {
  NetworkNotifier(super.value);
}

/// An inherited widget that provides [NetworkNotifier] to its descendants. Represent the context where
/// [NetworkChecker] acts.
class NetworkScope extends InheritedNotifier<NetworkNotifier> {

  /// Force a new connection check. Useful if it is possible for the connection status to change without
  /// changing the network output interfaces.
  final void Function() forceRetry;

  /// Creates a [NetworkScope] instance.
  const NetworkScope({super.key, required this.forceRetry, required super.notifier, required super.child});

  /// Retrieves the nearest [NetworkScope] up the widget tree.
  ///
  /// A [NetworkChecker] is required as an ancestor.
  static NetworkScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<NetworkScope>();
    if (scope == null) {
      throw FlutterError(
          'NetworkScope.of() called with a context that does not contain a NetworkScope.\n'
              'Ensure that your widget tree is wrapped with NetworkChecker.'
      );
    }
    return scope;
  }

  /// Retrieves the nearest [NetworkNotifier]'s value ([ConnectionStatus]) up the widget tree.
  ///
  /// A [NetworkChecker] is required as an ancestor.
  static ConnectionStatus statusOf(BuildContext context) => of(context).notifier!.value;

  /// Add a listener for connection status changes. You need to saved the returned listener and manually dispose it,
  /// normally on State.@dispose method. To do that use [removeListener].
  void Function() registerListener(void Function(ConnectionStatus) onChanged) {
    listener()=> onChanged.call(notifier!.value);
    notifier!.addListener(listener);
    return listener;
  }

  /// Remove a previously registered listener
  void removeListener(void Function() listener) {
    notifier!.removeListener(listener);
  }
}