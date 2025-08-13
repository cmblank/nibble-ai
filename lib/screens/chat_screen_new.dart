import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../widgets/nibble_app_bar.dart';

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final VoidCallback? onActionPressed;

  const MessageBubble({
    super.key,
    required this.message,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUser = message['isUser'] ?? false;
    final bool showAction = message['showAction'] ?? false;

    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isUser ? AppColors.gardenHerb : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message['message'] as String,
              style: TextStyle(
                color: isUser ? Colors.white : AppColors.deepRoast,
                fontSize: 16,
                fontFamily: 'Manrope',
                height: 1.4,
              ),
            ),
          ),
        ),
        if (showAction && !isUser)
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 8),
            child: ElevatedButton(
              onPressed: onActionPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.flameOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Cook with Nibble',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _addMessage({
      'message': 'Good evening, Chef!\nReady to create something delicious?',
      'isUser': false,
      'showAction': true,
    });
  }

  void _addMessage(Map<String, dynamic> message) {
    setState(() {
      _messages.add({
        ...message,
        'timestamp': DateTime.now(),
      });
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage(String text) async {
    if (text.isEmpty) return;

    _addMessage({
      'message': text,
      'isUser': true,
    });

    _messageController.clear();
    setState(() => _isTyping = true);

    try {
      final response = await _processMessage(text);
      _addMessage({
        'message': response,
        'isUser': false,
        'showAction': false,
      });
    } catch (e) {
      _addMessage({
        'message': "Sorry, I'm having trouble right now. Please try again!",
        'isUser': false,
        'showAction': false,
      });
    } finally {
      setState(() => _isTyping = false);
    }
  }

  Future<String> _processMessage(String text) async {
    await Future.delayed(const Duration(seconds: 1));
    if (text.toLowerCase().contains('recipe')) {
      return "I'd love to help you find a recipe! What ingredients do you have?";
    }
    return "Let me help you cook something delicious! What ingredients would you like to use?";
  }

  void _startCookingFlow() {
    _handleSendMessage("I'd like to find a recipe!");
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamWhisk,
      appBar: NibbleAppBar(
        title: null,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Image.asset(
            'assets/images/chef_mascot.png',
            width: 32,
            height: 32,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Text(
              'Nibble',
              style: TextStyle(
                color: AppColors.deepRoast,
                fontFamily: 'Manrope',
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return MessageBubble(
                    message: _messages[index],
                    onActionPressed: _messages[index]['showAction'] == true
                        ? _startCookingFlow
                        : null,
                  );
                },
              ),
            ),
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(left: 16),
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.gardenHerb),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Chef is thinking...',
                      style: TextStyle(
                        color: AppColors.deepRoast,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ask me about cooking anything...',
                        hintStyle: TextStyle(
                          color: AppColors.deepRoast.withOpacity(0.5),
                          fontFamily: 'Manrope',
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.creamWhisk.withOpacity(0.5),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: TextStyle(
                        color: AppColors.deepRoast,
                        fontFamily: 'Manrope',
                      ),
                      onSubmitted: _handleSendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.send_rounded,
                      color: AppColors.flameOrange,
                    ),
                    onPressed: () => _handleSendMessage(_messageController.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
