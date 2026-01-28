import 'package:flutter/material.dart';
import '../widgets/action_button.dart';
import '../settings/lg_config_storage.dart';
import '../services/lg_ssh_service.dart';
import '../settings/settings_screen.dart';
import '../services/kml/kml_loader.dart';
import 'dart:io';

enum LgStatus { connecting, connected, disconnected }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LgSshService? _lgService;
  LgStatus _status = LgStatus.connecting;

  bool get _isConnected => _status == LgStatus.connected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attemptAutoConnect());
  }

  Future<void> _attemptAutoConnect() async {
    try {
      await _ensureConnected();
    } catch (_) {}
  }

  Widget _statusWidget() {
    switch (_status) {
      case LgStatus.connecting:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Connecting to Liquid Galaxy…'),
          ],
        );

      case LgStatus.connected:
        return const Text(
          '● LG Connected',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        );

      case LgStatus.disconnected:
        return const Text(
          '● LG Not Connected',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        );
    }
  }

  Future<void> _ensureConnected() async {
    if (_status == LgStatus.connected) return;

    setState(() => _status = LgStatus.connecting);

    final attemptStart = DateTime.now();

    try {
      final config = await LgConfigStorage.load();
      if (config == null) {
        throw Exception('LG configuration not found. Please set it first.');
      }

      _lgService = LgSshService(config);

      await _lgService!.connect().timeout(const Duration(seconds: 2));

      if (!mounted) return;
      setState(() => _status = LgStatus.connected);
    } catch (e) {
      // loading
      final elapsed = DateTime.now().difference(attemptStart);
      final remaining = const Duration(seconds: 2) - elapsed;
      if (remaining > Duration.zero) {
        await Future.delayed(remaining);
      }

      if (mounted) setState(() => _status = LgStatus.disconnected);
      rethrow;
    }
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await _ensureConnected();

      if (_lgService == null) {
        throw Exception('LG service not initialized');
      }

      if (_status != LgStatus.connected) return;
      await action();
    } catch (e) {
      if (mounted) {
        setState(() => _status = LgStatus.disconnected);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liquid Galaxy Controller'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Settings',
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
        },
        child: const Icon(Icons.settings),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ActionButton(
              label: 'Show LG Logo',
              enabled: _isConnected,
              onPressed: () => _runAction(() async {
                await _lgService!.showLogo(
                  screen: 3,
                  imageUrl:
                      'https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEgXmdNgBTXup6bdWew5RzgCmC9pPb7rK487CpiscWB2S8OlhwFHmeeACHIIjx4B5-Iv-t95mNUx0JhB_oATG3-Tq1gs8Uj0-Xb9Njye6rHtKKsnJQJlzZqJxMDnj_2TXX3eA5x6VSgc8aw/s320-rw/LOGO+LIQUID+GALAXY-sq1000-+OKnoline.png',
                );
              }),
            ),
            const SizedBox(height: 12),

            ActionButton(
              label: 'Send Pyramid KML',
              enabled: _isConnected,
              onPressed: () => _runAction(() async {
                final kmlString = await KmlLoader.loadPyramidKml();

                // Send pyramid directly to slave_1 (world object)
                await _lgService!.sendKml(kmlString);
              }),
            ),
            const SizedBox(height: 12),

            ActionButton(
              label: 'Fly To Home City',
              enabled: _isConnected,
              onPressed: () => _runAction(() async {
                await _lgService!.flyTo(18.5204, 73.8567); //pune
              }),
            ),
            const SizedBox(height: 12),

            ActionButton(
              label: 'Clear Logos',
              enabled: _isConnected,
              onPressed: () => _runAction(() async {
                await _lgService!.clearLogo(3);
              }),
            ),
            const SizedBox(height: 12),

            ActionButton(
              label: 'Clear KMLs',
              enabled: _isConnected,
              onPressed: () => _runAction(() async {
                await _lgService!.clearKml();
              }),
            ),

            const SizedBox(height: 24),
            _statusWidget(),
          ],
        ),
      ),
    );
  }
}
