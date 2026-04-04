import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapboxConstants {
  MapboxConstants._();

  // Public token loaded from .env file
  static String get publicToken {
    return dotenv.env['MAPBOX_PUBLIC_TOKEN'] ?? '';
  }
}
