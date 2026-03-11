/// Environment variables injected at build time via:
///   flutter run --dart-define-from-file=dart_defines.env
///
/// Never hardcode API keys in source files — add them to dart_defines.env instead.
/// If this is empty the Maps/Directions/Places APIs will return REQUEST_DENIED.
const googleMapsMobileKey = String.fromEnvironment('GOOGLE_MAPS_MOBILE_KEY');
