import 'package:flutter/material.dart';
import '../widgets/action_button.dart';
import '../settings/lg_config_storage.dart';
import '../services/lg_ssh_service.dart';
import '../settings/settings_screen.dart';
import '../services/kml/kml_loader.dart';
import '../app/app_theme.dart';

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
        return const SizedBox();
      case LgStatus.connected:
        return const SizedBox();
      case LgStatus.disconnected:
        return const SizedBox();
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

      if (_lgService == null || _status != LgStatus.connected) return;
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
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Settings',
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(
            builder: (_) => SettingsScreen(
              connectionStatus: _status,
              onRefreshConnection: () async {
                _lgService?.disconnect();
                _lgService = null;
                setState(() => _status = LgStatus.disconnected);
                await _ensureConnected();
              },
            ),
          ));
        },
        child: const Icon(Icons.settings),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connection Status Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.lightGrey,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _status == LgStatus.connected
                        ? Colors.green
                        : _status == LgStatus.connecting
                            ? Colors.orange
                            : Colors.red,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    if (_status == LgStatus.connecting)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.orange),
                        ),
                      )
                    else
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _status == LgStatus.connected
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _status == LgStatus.connected
                            ? 'Connected to Liquid Galaxy'
                            : _status == LgStatus.connecting
                                ? 'Connecting to Liquid Galaxy…'
                                : 'Not Connected',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Actions Section
              Text(
                'Actions',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 16),
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
                  final modelData = await KmlLoader.loadPyramidModel();
                  await _lgService!.uploadModelFile(modelData, 'model_1.dae');
                  final kmlString = await KmlLoader.loadPyramidKml();
                  await _lgService!.showPyramid(kmlString);
                }),
              ),
              const SizedBox(height: 12),
              ActionButton(
                label: 'Fly To Home City',
                enabled: _isConnected,
                onPressed: () => _runAction(() async {
                  await _lgService!.flyTo(18.5204, 73.8567);
                }),
              ),
              const SizedBox(height: 32),

              // Clear Section
              Text(
                'Clear',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 16),
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
                  await _lgService!.clearPyramid();
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
