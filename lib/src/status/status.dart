/// Represents the possible network connection statuses detected by [NetworkChecker].
enum ConnectionStatus {

  /// The application has internet access and can successfully reach the server.
  ///
  /// This means the server responded with a valid `204` No Content status.
  ///
  /// **Example cases:**
  /// - The device is online and the server is healthy.
  online,

  /// The device is completely disconnected from any network.
  ///
  /// This typically indicates:
  /// - Airplane mode
  /// - No Wi-Fi or mobile data
  /// - A total network block
  noInternet,

  /// The device has local network access but cannot reach any external network.
  ///
  /// **Example cases:**
  /// - DNS resolution fails
  /// - ISP or router blocks outbound traffic
  /// - Misconfigured VPN or proxy
  networkUnreachable,

  /// The device is online, but the target server did not respond in time.
  ///
  /// **Example cases:**
  /// - Server is down or very slow
  /// - Load balancer timeout
  serverUnreachable,

  /// The server responded with a 5xx status code, indicating backend failure.
  ///
  /// **Example cases:**
  /// - 500 Internal Server Error
  /// - 502 Bad Gateway
  /// - 503 Service Unavailable
  /// - 504 Gateway Timeout
  serverError,

  /// The server responded with a 4xx status code, indicating a client-side problem.
  ///
  /// **Example cases:**
  /// - 401 Unauthorized
  /// - 403 Forbidden
  /// - 404 Not Found
  /// - 429 Too Many Requests
  clientError,

  /// The server responded with a status code that is neither 204 nor an error,
  /// indicating a misconfiguration or unexpected behavior.
  ///
  /// **Example cases:**
  /// - 200 OK (with unexpected content due to captive portal)
  /// - 302 Redirect
  unexpectedResponse,

  /// The connection status is currently being checked or is unknown.
  ///
  /// Use this status to indicate a transient state.
  checking,

  /// An unexpected failure occurred that doesn't fit known categories.
  ///
  /// Useful as a fallback to handle unknown exceptions.
  unknownFailure,
}