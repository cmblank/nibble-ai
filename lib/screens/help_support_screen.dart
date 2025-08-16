import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            'Need help? Send feedback to support@nibble.ai or check our FAQs in the next update.',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
