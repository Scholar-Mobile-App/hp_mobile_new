// API Configuration
class ApiConfig {
  static const String baseUrl = 'https://hp.triz.co.in';
  static const String loginEndpoint = '/login';
  static const String profileEndpoint = '/api/user/profile';
  static const String menuRightsEndpoint = '/user/ajax_groupwiserights';

  // API call timeouts
  static const Duration defaultTimeout = Duration(seconds: 30);

  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}