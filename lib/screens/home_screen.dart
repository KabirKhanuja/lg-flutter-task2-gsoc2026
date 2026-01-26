import 'package:flutter/material.dart';
import '../widgets/action_button.dart';
import '../settings/lg_config_storage.dart';
import '../services/lg_ssh_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LgSshService? _lgService;
  bool _connected = false;

  Future<void> _ensureConnected() async {
    if (_connected) return;

    final config = await LgConfigStorage.load();
    if (config == null) {
      throw Exception('LG configuration not found. Please set it first.');
    }

    _lgService = LgSshService(config);
    await _lgService!.connect();

    setState(() {
      _connected = true;
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await _ensureConnected();
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liquid Galaxy Controller'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ActionButton(
              label: 'Show LG Logo',
              onPressed: () => _runAction(() async {
                await _lgService!.sendLogo('https://liquidgalaxy.eu/logo.png');
              }),
            ),
            const SizedBox(height: 12),

            ActionButton(
              label: 'Send Pyramid KML',
              enabled: _connected,
              onPressed: () => _runAction(() async {
                const pyramidKml = '''
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Placemark>
    <name>Pyramid</name>
    <Polygon>
      <outerBoundaryIs>
        <LinearRing>
          <coordinates>
            0,0,0
            0.01,0,0
            0.01,0.01,0
            0,0.01,0
            0,0,0
          </coordinates>
        </LinearRing>
      </outerBoundaryIs>
    </Polygon>
  </Placemark>
</kml>
''';
                await _lgService!.sendKml(pyramidKml);
              }),
            ),
            const SizedBox(height: 12),

            ActionButton(
              label: 'Fly To Home City',
              onPressed: () => _runAction(() async {
                await _lgService!.flyTo(
                  latitude: 18.5204, // Pune
                  longitude: 73.8567,
                );
              }),
            ),
            const SizedBox(height: 12),

            ActionButton(
              label: 'Clear Logos',
              onPressed: () => _runAction(() async => _lgService!.clearLogos()),
            ),
            const SizedBox(height: 12),

            ActionButton(
              label: 'Clear KMLs',
              onPressed: () => _runAction(() async => _lgService!.clearKmls()),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.circle,
                  color: _connected ? Colors.green : Colors.red,
                  size: 12,
                ),
                const SizedBox(width: 8),
                Text(
                  _connected ? 'LG Connected' : 'LG Not Connected',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
