//App version
// V4.4.1
class AppSettings {
  ///
  /// Basic setup details
  ///

  // The name of the application
  static const String appName = 'Qatrat Kheir| قطرة خير';

  // The package name for the Android app
  static const String packageName = 'com.customersingle.customer';

  // The package name for the iOS app
  static const String iosPackage = 'com.customersingle.customer';

  // The URL link to the iOS app on the App Store (to be replaced with the actual link)
  static const String iosLink = 'https://apps.apple.com/qa/app/qatrat-kheir-%D9%82%D8%B7%D8%B1%D8%A9-%D8%AE%D9%8A%D8%B1/id6743666276';

  // App Store ID for the iOS app
  static const String appStoreId = '6743666276';

// API configuration: Update with your server URL and client-specific details
static const String baseUrl =
    'https://www.qatratkheir.com/app/v1/api/'; // Base API endpoint
static const String chatBaseUrl =
    "https://www.qatratkheir.com/app/v1/Chat_Api/"; // Chat-specific API endpoint
    static const String clientName = 'app'; // Name of the client
  static const String jwtSecret = '65c9cd19cd138f19ddf2f6320c7a802ee936c548'; 


  // Deep linking configuration
  static const String deepLinkUrlPrefix =
      'https://qatratkheir.page.link'; // Prefix for dynamic links
  static const String deepLinkName = 'customer.com'; // Hostname for deep links
  static const String shareNavigationWebUrl =
      "qatratkheir.com"; // Web URL for sharing navigation

  // Toggle to disable dark mode across the app (set `true` to disable)
  static const bool disableDarkTheme = false;

  // Default localization settings
  static const String defaultLanguageCode = "en"; // Default language (English)
  static const String defaultCountryCode = 'QA'; // Default country (India)

  // Formatting settings
  static const int decimalPoints =
      2; // Number of decimal points for numeric values

  // Network request configuration
  static const int timeOut = 50; // Timeout duration in seconds for API calls
  static const int perPage = 10; // Default pagination size for API results

  // Chat feature settings
  static const String messagesLoadLimit =
      '30'; // Limit for the number of chat messages to load
  static const double allowableTotalFileSizesInChatMediaInMB =
      15.0; // Maximum allowable size for chat media uploads in MB
}
