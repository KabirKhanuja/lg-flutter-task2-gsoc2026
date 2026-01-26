import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import '../settings/lg_connection_config.dart';

class LgSshService {
  final LgConnectionConfig config;
  SSHClient? _client;

  LgSshService(this.config);

  // connecting to the lg master
  Future<void> connect() async {
    if (_client != null) return;

    final socket = await SSHSocket.connect(config.host, config.port);

    _client = SSHClient(
      socket,
      username: config.username,
      onPasswordRequest: () => config.password,
    );
  }

  // for disconnecting
  Future<void> disconnect() async {
    _client?.close();
    _client = null;
  }

  Future<void> _exec(String command) async {
    if (_client == null) {
      throw Exception('LG SSH not connected');
    }

    final session = await _client!.execute(command);
    await session.done;
  }

  // to clear all KMLs
  Future<void> clearKmls() async {
    await _exec("echo '' > /var/www/html/kmls.txt");
  }

  // to clear all logos
  Future<void> clearLogos() async {
    await _exec("echo '' > /var/www/html/logos.txt");
  }

  Future<void> sendLogo(String logoUrl) async {
    await _exec("echo \"logo=$logoUrl\" > /var/www/html/logos.txt");
  }

  // to send KML content
  Future<void> sendKml(String kmlContent) async {
    final encoded = base64Encode(utf8.encode(kmlContent));

    await _exec("echo '$encoded' | base64 --decode > /var/www/html/kmls.txt");
  }

  // flying to a location
  Future<void> flyTo({
    required double latitude,
    required double longitude,
    double altitude = 5000,
    double tilt = 45,
    double heading = 0,
    double range = 1000,
  }) async {
    final flyToKml =
        '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2"
     xmlns:gx="http://www.google.com/kml/ext/2.2">
  <gx:FlyTo>
    <gx:duration>3</gx:duration>
    <gx:flyToMode>smooth</gx:flyToMode>
    <LookAt>
      <latitude>$latitude</latitude>
      <longitude>$longitude</longitude>
      <altitude>$altitude</altitude>
      <heading>$heading</heading>
      <tilt>$tilt</tilt>
      <range>$range</range>
    </LookAt>
  </gx:FlyTo>
</kml>
''';

    await sendKml(flyToKml);
  }
}
