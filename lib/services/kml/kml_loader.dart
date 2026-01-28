import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';

class KmlLoader {
  static Future<String> loadPyramidKml() async {
    return await rootBundle.loadString('assets/kml/pyramid.kml');
  }

  static Future<Uint8List> loadPyramidModel() async {
    final data = await rootBundle.load('assets/kml/model_1.dae');
    return data.buffer.asUint8List();
  }
}
