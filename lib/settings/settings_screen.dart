import 'package:flutter/material.dart';
import 'lg_config_storage.dart';
import 'lg_connection_config.dart';
import '../screens/home_screen.dart';
import '../app/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final LgStatus connectionStatus;
  final Future<void> Function() onRefreshConnection;
  
  const SettingsScreen({
    super.key,
    required this.connectionStatus,
    required this.onRefreshConnection,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _hostController = TextEditingController();
  final _userController = TextEditingController(text: 'lg');
  final _portController = TextEditingController(text: '22');
  final _passwordController = TextEditingController();

  LgConnectionConfig? config;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _hostController.dispose();
    _userController.dispose();
    _portController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final loaded = await LgConfigStorage.load();
    if (!mounted || loaded == null) return;

    _hostController.text = loaded.host;
    _userController.text = loaded.username;
    _portController.text = loaded.port.toString();
    _passwordController.text = loaded.password;

    setState(() {
      config = loaded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Liquid Galaxy Settings')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Configuration Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.lightGrey,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Settings',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _hostController,
                      decoration: const InputDecoration(
                        labelText: 'LG Master IP / Host',
                        prefixIcon: Icon(Icons.router),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _userController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _portController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Port',
                        prefixIcon: Icon(Icons.vpn_lock),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: () async {
                  final port = int.tryParse(_portController.text) ?? 22;

                  final newConfig = LgConnectionConfig(
                    host: _hostController.text.trim(),
                    username: _userController.text.trim(),
                    port: port,
                    password: _passwordController.text,
                  );

                  await LgConfigStorage.save(newConfig);

                  if (!context.mounted) return;

                  setState(() {
                    config = newConfig;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Configuration saved successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Save Configuration'),
              ),
              const SizedBox(height: 32),

              // Connection Status Card
              if (config != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: widget.connectionStatus == LgStatus.connected
                        ? Colors.green.shade50
                        : widget.connectionStatus == LgStatus.connecting
                            ? Colors.orange.shade50
                            : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.connectionStatus == LgStatus.connected
                          ? Colors.green
                          : widget.connectionStatus == LgStatus.connecting
                              ? Colors.orange
                              : Colors.red,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (widget.connectionStatus == LgStatus.connecting)
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          else
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.connectionStatus ==
                                        LgStatus.connected
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.connectionStatus == LgStatus.connected
                                  ? 'Status: Connected'
                                  : widget.connectionStatus ==
                                          LgStatus.connecting
                                      ? 'Status: Connecting...'
                                      : 'Status: Not connected',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: widget.connectionStatus ==
                                        LgStatus.connected
                                    ? Colors.green.shade700
                                    : widget.connectionStatus ==
                                            LgStatus.connecting
                                        ? Colors.orange.shade700
                                        : Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _isRefreshing
                            ? null
                            : () async {
                                setState(() => _isRefreshing = true);
                                try {
                                  await widget.onRefreshConnection();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Connection refreshed successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text('Connection failed: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isRefreshing = false);
                                  }
                                }
                              },
                        icon: _isRefreshing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh),
                        label: Text(
                          _isRefreshing ? 'Testing...' : 'Test Connection',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
