import 'package:flutter/material.dart';

class CookScreen extends StatelessWidget {
  const CookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Cook Screen',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
