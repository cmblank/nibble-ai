import 'package:flutter/material.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Kitchen Community',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          // Recipe sharing section
          Card(
            child: ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share Your Recipes'),
              subtitle: const Text('Inspire others with your culinary creations'),
              onTap: () {
                // TODO: Implement recipe sharing
              },
            ),
          ),
          const SizedBox(height: 8),
          // Cooking challenges section
          Card(
            child: ListTile(
              leading: const Icon(Icons.emoji_events_outlined),
              title: const Text('Cooking Challenges'),
              subtitle: const Text('Join weekly cooking challenges'),
              onTap: () {
                // TODO: Implement challenges
              },
            ),
          ),
          const SizedBox(height: 8),
          // Tips & tricks section
          Card(
            child: ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: const Text('Tips & Tricks'),
              subtitle: const Text('Share and discover cooking tips'),
              onTap: () {
                // TODO: Implement tips section
              },
            ),
          ),
          const SizedBox(height: 8),
          // Community feed
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // TODO: Implement activity feed
                const ListTile(
                  leading: CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                  title: Text('Coming Soon'),
                  subtitle: Text('Community features are on their way!'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
