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