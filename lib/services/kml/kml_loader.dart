import 'package:flutter/services.dart' show rootBundle;

class KmlLoader {
  static Future<String> loadPyramidKml() async {
    return await rootBundle.loadString('assets/kml/pyramid.kml');
  }
}
