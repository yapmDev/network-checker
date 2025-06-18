import 'package:flutter/material.dart';
import 'package:network_checker/network_checker.dart';
import 'package:network_checker/src/service/service.dart';

/// Allows to switch automatically between [ConnectionConfig] used by [NetworkChecker].
class ConnectionConfigScope extends StatefulWidget {

  /// The new config for this scope.
  final ConnectionConfig config;

  /// The child passed to hierarchy.
  final Widget child;

  /// Create an [ConnectionConfigScope] instance with the given config and child.
  const ConnectionConfigScope({super.key, required this.config, required this.child});

  @override
  State<ConnectionConfigScope> createState() => _ConnectionConfigScopeState();
}

class _ConnectionConfigScopeState extends State<ConnectionConfigScope> {

  @override
  void initState() {
    super.initState();
    final connService = ConnectionService();
    connService.updateConfig(widget.config);
  }

  @override
  void dispose() {
    final connService = ConnectionService();
    connService.restoreConfig();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
