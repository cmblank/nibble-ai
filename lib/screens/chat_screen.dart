import 'package:flutter/material.dart';
import '../utils/nibble_functions.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _addMessage("Hello! I'm your cooking companion. How can I help you today?", false);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _addMessage(String message, bool isUser) {
    setState(() {
      _messages.add({
        'message': message,
        'isUser': isUser,
        'timestamp': DateTime.now(),
      });
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _addMessage(message, true);
    _messageController.clear();

    setState(() {
      _isTyping = true;
    });

    try {
      // Simple response logic
      String response = await _generateResponse(message);
      _addMessage(response, false);
    } catch (e) {
      _addMessage("Sorry, I'm having trouble right now. Please try again!", false);
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }

  Future<String> _generateResponse(String message) async {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('pantry')) {
      return await _handlePantryRequest();
    } else if (lowerMessage.contains('recipe') || lowerMessage.contains('cook')) {
      return await _suggestRecipes();
    } else if (lowerMessage.contains('mood') || lowerMessage.contains('feel')) {
      return _handleMoodMessage(message);
    } else {
      return "I can help you with your pantry, suggest recipes, or log your mood. What would you like to do?";
    }
  }

  Future<String> _handlePantryRequest() async {
    final pantryItems = await NibbleFunctions.getPantry();
    if (pantryItems.isEmpty) {
      return "Your pantry is empty! Try adding some items like 'tomatoes', 'pasta', or 'cheese'.";
    } else {
      return "Here's what's in your pantry: ${pantryItems.join(', ')}. What would you like to cook?";
    }
  }

  Future<String> _suggestRecipes() async {
    final recipes = await NibbleFunctions.suggestMeals();
    if (recipes.isEmpty) {
      return "I don't have any recipes to suggest right now. Try adding some ingredients to your pantry first!";
    } else {
      final recipeNames = recipes.map((r) => r['name']).toList();
      return "Here are some recipes you might like: ${recipeNames.join(', ')}. Which one sounds good?";
    }
  }

  String _handleMoodMessage(String message) {
    if (message.toLowerCase().contains('happy')) {
      NibbleFunctions.logMood(mood: 'happy');
      return "That's wonderful! When you're happy, how about trying a fun recipe like pancakes or tacos? 🎉";
    } else if (message.toLowerCase().contains('tired')) {
      NibbleFunctions.logMood(mood: 'tired');
      return "I understand. Let me suggest some quick and easy meals that won't take much energy. 💤";
    } else {
      return "Thanks for sharing how you're feeling! I can suggest recipes based on your mood.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          if (_isTyping) _buildTypingIndicator(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['isUser'] as bool;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser 
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message['message'],
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text("Typing..."),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
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
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send),
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
