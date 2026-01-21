import 'package:flutter/material.dart';
import '../widgets/action_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liquid Galaxy Controller'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ActionButton(label: 'Show LG Logo', onPressed: () {}),
            const SizedBox(height: 12),
            ActionButton(label: 'Send Pyramid KML', onPressed: () {}),
            const SizedBox(height: 12),
            ActionButton(label: 'Fly To Home City', onPressed: () {}),
            const SizedBox(height: 12),
            ActionButton(label: 'Clear Logos', onPressed: () {}),
            const SizedBox(height: 12),
            ActionButton(label: 'Clear KMLs', onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
