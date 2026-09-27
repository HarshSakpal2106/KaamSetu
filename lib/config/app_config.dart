class AppConfig {
  /// Workers / bookings still use the local mock dataset.
  /// Auth uses Firebase when `flutterfire configure` has been run.
  static const bool useMockData = true;

  static const String appName = 'KaamSetu';
  static const String appTagline = 'Your Trusted Local Service Network';
  static const String copyright = '© 2026 KaamSetu';
}
