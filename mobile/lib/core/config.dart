/// Конфигурация клиента: адрес бэкенда.
///
/// Как выбрать baseUrl под своё окружение:
///  - Android-эмулятор  -> http://10.0.2.2:8000  (это «localhost» хост-машины)
///  - iOS-симулятор     -> http://127.0.0.1:8000
///  - Реальный телефон  -> http://<IP-компьютера-в-той-же-сети>:8000
///                         (бэкенд запускается с --host 0.0.0.0)
class AppConfig {
  /// По умолчанию — Android-эмулятор. Меняется под устройство (см. выше)
  /// или через --dart-define=API_BASE_URL=http://192.168.x.x:8000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
}
