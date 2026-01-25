import 'dart:convert';
import 'package:http/http.dart' as http;
import '../settings/lg_config_storage.dart';
import '../settings/lg_connection_config.dart';

class LgService {
  static const String _basePath = '/lg';

  static Future<LgConnectionConfig> _getConfig() async {
    final config = await LgConfigStorage.load();
    if (config == null) {
      throw Exception('LG configuration not found');
    }
    return config;
  }

  static Uri _buildUri(LgConnectionConfig config, String endpoint) {
    return Uri(
      scheme: 'http',
      host: config.host,
      port: config.port,
      path: endpoint,
    );
  }

  static Future<void> _post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final config = await _getConfig();
    final uri = _buildUri(config, endpoint);

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    );

    if (response.statusCode >= 300) {
      throw Exception(
        'LG request failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  // for task 2

  // LG logo on left screen
  static Future<void> sendLogo(String logoUrl) async {
    await _post('$_basePath/logo', body: {'url': logoUrl, 'screen': 'left'});
  }

  // showing pyramid KML
  static Future<void> sendKml(String kmlContent) async {
    await _post('$_basePath/kml', body: {'kml': kmlContent});
  }

  // fly to home city
  static Future<void> flyTo({
    required double lat,
    required double lng,
    double altitude = 1000,
    double heading = 0,
    double tilt = 45,
    double range = 1000,
  }) async {
    await _post(
      '$_basePath/flyto',
      body: {
        'latitude': lat,
        'longitude': lng,
        'altitude': altitude,
        'heading': heading,
        'tilt': tilt,
        'range': range,
      },
    );
  }

  // clearing all logos
  static Future<void> clearLogos() async {
    await _post('$_basePath/logo/clear');
  }

  // clearing all KMLs
  static Future<void> clearKmls() async {
    await _post('$_basePath/kml/clear');
  }
}
