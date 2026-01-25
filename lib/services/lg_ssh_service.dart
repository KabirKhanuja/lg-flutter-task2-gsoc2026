import 'package:ssh2/ssh2.dart';
import '../settings/lg_connection_config.dart';

class LgService {
  final LgConnectionConfig config;
  SSHClient? _client;

  LgService(this.config);

  Future<void> connect() async {
    _client = SSHClient(
      host: config.host,
      port: config.port,
      username: config.username,
      passwordOrKey: config.password,
    );

    await _client!.connect();
  }

  Future<void> disconnect() async {
    _client?.disconnect();
  }

  Future<void> sendCommand(String command) async {
    if (_client == null) {
      throw Exception('LG not connected');
    }
    await _client!.execute(command);
  }

  //to clear all KMLs
  Future<void> clearKmls() async {
    await sendCommand('echo "" > /var/www/html/kmls.txt');
  }

  //to clear all logos
  Future<void> clearLogos() async {
    await sendCommand('echo "" > /var/www/html/logos.txt');
  }

  // sending a KML file content directly
  Future<void> sendKml(String kmlContent) async {
    final escaped = kmlContent.replaceAll("'", r"'\''");

    await sendCommand("echo '$escaped' > /var/www/html/kmls.txt");
  }

  // flying to my home cityyyy
  Future<void> flyTo({
    required double lat,
    required double lon,
    double altitude = 5000,
  }) async {
    final flyToKml =
        '''
<kml xmlns="http://www.opengis.net/kml/2.2">
  <FlyTo>
    <duration>3</duration>
    <LookAt>
      <latitude>$lat</latitude>
      <longitude>$lon</longitude>
      <altitude>$altitude</altitude>
      <heading>0</heading>
      <tilt>45</tilt>
      <range>1000</range>
    </LookAt>
  </FlyTo>
</kml>
''';

    await sendKml(flyToKml);
  }
}
