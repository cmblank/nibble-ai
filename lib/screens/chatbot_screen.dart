import 'package:flutter/material.dart';
import '../design_tokens/color_tokens.dart';

class ChatbotScreen extends StatelessWidget {
  final String title;
  const ChatbotScreen({super.key, this.title = 'Chef AI'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.gray300,
      body: Column(
        children: [
          // Minimal in-chat header
          SafeArea(
            bottom: false,
            child: Container(
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.black12, width: 1),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // spacer to balance leading IconButton
                ],
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Chef AI Chatbot',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}