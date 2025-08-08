import 'package:flutter/material.dart';

class PantryScreen extends StatelessWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Pantry Screen',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
