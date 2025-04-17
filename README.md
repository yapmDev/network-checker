# Network Checker

A lightweight and customizable network connectivity checker for Flutter apps.  
It provides real-time detection of internet availability and server reachability, with flexible UI alert customization.

---

## 📦 Installation

Add this to your `pubspec.yaml` under dependencies:

```yaml
dependencies:
  network_checker:
    git:
      url: https://github.com/yapmDev/network_checker.git
```

(Replace with the pub.dev version once published.)

Then run:

```bash
flutter pub get
```

---

## 🚀 Features

- Detects actual internet availability, not just network interfaces.
- Pings a customizable URL to verify server reachability.
- Easily integrates into your app’s top level or specific views.
- Provides global or per-screen alert templates for connection issues.
- Exposes real-time connection status updates via `ValueNotifier`.
- Lightweight, with full platform support through `connectivity_plus`.

---

## 🎯 Getting Started

Wrap your app with `NetworkChecker` at the top level:

```dart
MaterialApp.router(
  builder: (context, child) => NetworkChecker(
    pingUrl: 'http://10.0.2.2:8080/network-checker', // optional
    alertBuilder: (context, status) => YourAlertWidget(status),
    child: child!,
  ),
  routerConfig: appRouter,
);
```

Or for more granular control, use it in specific parts of the widget tree.

---

## 🧩 API Overview

### `NetworkChecker`

| Property         | Description |
| ---------------- | ----------- |
| `pingUrl`         | URL to check for server connectivity. Defaults to [https://www.gstatic.com/generate_204](https://www.gstatic.com/generate_204). |
| `timeLimit`       | Timeout duration for ping requests. Defaults to 3 seconds. |
| `alertBuilder`    | Optional widget builder to show alerts when offline or server unavailable. |
| `alertPosition`   | Optional alignment for alert widget. Defaults to bottom center. |
| `child`           | Your app’s widget tree. |

---

### `NetworkAlertTemplate`

Used to create alerts for specific screens if a global alert is not set at the top level.

```dart
NetworkAlertTemplate(
  alertBuilder: (context, status) => YourAlertWidget(status),
  child: YourScreen(),
)
```

---

## 📡 Connection Statuses

| Status                | Meaning |
| ---------------------- | ------- |
| `online`               | Internet and server reachable |
| `noInternet`           | No network connection |
| `serverNotAvailable`   | Internet available but server unreachable (timeout) |
| `serverError`          | Server reachable but responded with an error |
| `checking`             | Currently verifying connection |

---

## 🔥 Advanced Usage

- Force a recheck manually:

```dart
NetworkChecker.forceRetry();
```

- Listen to connection status changes:

```dart
NetworkChecker.addStatusListener((status) {
  // handle changes
});
```

Remember to remove listeners on dispose:

```dart
NetworkChecker.removeStatusListener(myListener);
```

- Access current status anywhere:

```dart
final isConnected = NetworkProvider.of(context).value == ConnectionStatus.online;
```

---

## 📖 Requirements

- Flutter 3.10.0 or higher
- Dart 3.0.0 or higher
- connectivity_plus 5.0.2

---

## 📃 License

MIT License. See the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

Created and maintained by [yapmDev](https://github.com/yapmDev).
