import 'package:flutter/widgets.dart';
import 'package:network_checker/src/core/scope.dart';
import 'package:network_checker/src/core/status.dart';

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

    final networkNotifier = NetworkScope.of(context);

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