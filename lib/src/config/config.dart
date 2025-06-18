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