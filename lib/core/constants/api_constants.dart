class ApiConstants {
  // Production SSL Domain URL
  static const String baseUrl = 'https://app.lobsens-unpad.web.id/api/v2';
  
  // Auth Endpoints
  static const String login = '$baseUrl/auth/login';
  static const String profile = '$baseUrl/profile';
  static const String logout = '$baseUrl/auth/logout';

  // Mobile Dedicated Endpoints
  static const String mobileSummary = '$baseUrl/mobile/summary';
  static const String mobileTelemetry = '$baseUrl/mobile/telemetry'; // + /{serial_number}
  static const String mobileFeedingSchedules = '$baseUrl/mobile/feeding/schedules';
  static const String mobileFeedingScheduleStore = '$baseUrl/mobile/feeding/schedule';
  static const String mobileFeedingInstantTrigger = '$baseUrl/mobile/feeding/trigger';
}
