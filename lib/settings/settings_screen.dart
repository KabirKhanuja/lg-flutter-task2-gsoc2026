import 'package:flutter/material.dart';
import 'lg_config_storage.dart';
import 'lg_connection_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _hostController = TextEditingController();
  final _userController = TextEditingController(text: 'lg');
  final _portController = TextEditingController(text: '22');
  final _passwordController = TextEditingController();

  LgConnectionConfig? config;

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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: 'LG Master IP / Host',
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _userController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Port'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 24),

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
                  const SnackBar(content: Text('LG configuration saved')),
                );
              },
              child: const Text('Save Configuration'),
            ),

            const SizedBox(height: 24),

            if (config != null)
              Text(
                'Status: Not connected',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
