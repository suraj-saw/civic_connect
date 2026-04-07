import 'package:shared_preferences/shared_preferences.dart';

class LocationStorageService {
  static const String _latitudeKey = 'last_location_latitude';
  static const String _longitudeKey = 'last_location_longitude';

  /// Save the user's current location to local storage
  static Future<void> saveLastLocation({
    required double latitude,
    required double longitude,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latitudeKey, latitude);
    await prefs.setDouble(_longitudeKey, longitude);
  }

  /// Retrieve the last saved location
  /// Returns a map with 'latitude' and 'longitude' keys, or null if no location saved
  static Future<({double latitude, double longitude})?> getLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final latitude = prefs.getDouble(_latitudeKey);
    final longitude = prefs.getDouble(_longitudeKey);

    if (latitude == null || longitude == null) {
      return null;
    }

    return (latitude: latitude, longitude: longitude);
  }

  /// Check if a location has been previously saved
  static Future<bool> hasLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_latitudeKey) && prefs.containsKey(_longitudeKey);
  }

  /// Clear the saved location
  static Future<void> clearLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_latitudeKey);
    await prefs.remove(_longitudeKey);
  }
}
