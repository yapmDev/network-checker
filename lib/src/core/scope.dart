import 'package:flutter/widgets.dart';
import 'package:network_checker/src/core/notifier.dart';

/// An inherited widget that provides [NetworkNotifier] to its descendants.
class NetworkScope extends InheritedNotifier<NetworkNotifier> {

  /// Creates a [NetworkScope] with the given [notifier] and [child].
  const NetworkScope({
    super.key,
    required super.notifier,
    required super.child
  });

  /// Retrieves the nearest [NetworkNotifier] up the widget tree.
  ///
  /// A [NetworkChecker] is required as an ancestor.
  static NetworkNotifier of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<NetworkScope>();
    if (scope == null) {
      throw FlutterError(
          'NetworkScope.of() called with a context that does not contain a NetworkScope.\n'
              'Ensure that your widget tree is wrapped with NetworkChecker or NetworkScope.'
      );
    }
    return scope.notifier!;
  }
}