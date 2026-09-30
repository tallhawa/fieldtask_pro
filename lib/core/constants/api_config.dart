class ApiConfig {
  /// Émulateur Android :
  /// 10.0.2.2 correspond au PC hôte.
  ///
  /// Téléphone réel :
  /// flutter run --dart-define=API_BASE_URL=http://IP_DU_PC:3000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static const Duration connectTimeout = Duration(seconds: 5);
  static const Duration receiveTimeout = Duration(seconds: 8);
}