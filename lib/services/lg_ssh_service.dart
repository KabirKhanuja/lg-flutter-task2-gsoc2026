import 'package:dartssh2/dartssh2.dart';
import '../settings/lg_connection_config.dart';
import 'dart:convert';
import 'dart:typed_data';

bool _busy = false;

class LgSshService {
  final LgConnectionConfig config;
  SSHClient? _client;

  LgSshService(this.config);

  // connections logic

  Future<void> connect() async {
    try {
      _client?.close();
      _client = null;

      final socket = await SSHSocket.connect(
        config.host,
        config.port,
        timeout: const Duration(seconds: 5),
      );

      final client = SSHClient(
        socket,
        username: config.username,
        onPasswordRequest: () => config.password,
      );

      final session = await client.execute('echo LG_CONNECTED');
      await session.done;

      _client = client;
      print('LG SSH CONNECTED');
    } catch (e) {
      _client?.close();
      _client = null;
      print('LG SSH CONNECTION FAILED: $e');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    _client?.close();
    _client = null;
  }

  Future<void> _exec(String command) async {
    print('SSH >>> $command');

    while (_busy) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    _busy = true;

    try {
      if (_client == null) {
        await connect();
      }

      final session = await _client!.execute(command);

      final stdout = await session.stdout
          .map((Uint8List data) => utf8.decode(data))
          .join();

      final stderr = await session.stderr
          .map((Uint8List data) => utf8.decode(data))
          .join();

      await session.done;

      if (stdout.trim().isNotEmpty) {
        print('STDOUT:\n$stdout');
      }
      if (stderr.trim().isNotEmpty) {
        print('STDERR:\n$stderr');
      }
    } finally {
      _busy = false;
    }
  }

  // flying homeee

  Future<void> flyTo(double lat, double lon) async {
    await _exec("echo 'search=$lat,$lon' > /tmp/query.txt");
  }

  // pyramid logic

  // uploads dae as well
  Future<void> uploadModelFile(Uint8List modelData, String fileName) async {
    if (_client == null) throw Exception('LG not connected');

    final sftp = await _client!.sftp();

    final file = await sftp.open(
      '/var/www/html/$fileName',
      mode:
          SftpFileOpenMode.create |
          SftpFileOpenMode.truncate |
          SftpFileOpenMode.write,
    );

    await file.write(Stream.value(modelData));
    await file.close();

    print('Uploaded model file: $fileName');
  }

  Future<void> showPyramid(String kmlContent) async {
    if (_client == null) throw Exception('LG not connected');

    final random = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'pyramid_$random.kml';

    final sftp = await _client!.sftp();

    final file = await sftp.open(
      '/var/www/html/$fileName',
      mode:
          SftpFileOpenMode.create |
          SftpFileOpenMode.truncate |
          SftpFileOpenMode.write,
    );

    // write KML
    await file.write(Stream.value(Uint8List.fromList(utf8.encode(kmlContent))));
    await file.close();

    // Use query.txt to load the KML (better for placemarks)
    await _exec('echo "http://lg1:81/$fileName" > /tmp/query.txt');
  }

  Future<void> clearPyramid() async {
    if (_client == null) throw Exception('LG not connected');

    const emptyKml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
<Document>
</Document>
</kml>''';

    final fileName = 'clear_${DateTime.now().millisecondsSinceEpoch}.kml';
    final sftp = await _client!.sftp();

    final file = await sftp.open(
      '/var/www/html/$fileName',
      mode: SftpFileOpenMode.create | SftpFileOpenMode.truncate | SftpFileOpenMode.write,
    );

    await file.write(Stream.value(Uint8List.fromList(utf8.encode(emptyKml))));
    await file.close();

    await _exec('echo "http://lg1:81/$fileName" > /tmp/query.txt');
  }
  // for the logo

  Future<void> showLogo({required int screen, required String imageUrl}) async {
    final logoKml =
        '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
<Document>
  <ScreenOverlay>
    <name>LG Logo</name>
    <Icon>
      <href>$imageUrl</href>
    </Icon>
    <overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/>
    <screenXY x="0.02" y="0.95" xunits="fraction" yunits="fraction"/>
    <size x="0.25" y="0.25" xunits="fraction" yunits="fraction"/>
  </ScreenOverlay>
</Document>
</kml>
''';

    await _exec("echo '$logoKml' > /var/www/html/kml/slave_$screen.kml");
  }

  Future<void> clearLogo(int screen) async {
    const emptyKml = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
<Document></Document>
</kml>
''';

    await _exec("echo '$emptyKml' > /var/www/html/kml/slave_$screen.kml");
  }
}
