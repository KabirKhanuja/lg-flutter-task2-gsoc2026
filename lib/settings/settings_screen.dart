import 'package:flutter/material.dart';
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

  void _saveConfig() {
    final newConfig = LgConnectionConfig(
      host: _hostController.text.trim(),
      username: _userController.text.trim(),
      port: int.tryParse(_portController.text) ?? 22,
      password: _passwordController.text,
    );

    setState(() {
      config = newConfig;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('LG configuration saved')));
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
              onPressed: _saveConfig,
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
