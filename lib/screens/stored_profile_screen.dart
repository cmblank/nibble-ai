import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/profile_storage.dart';

class StoredProfileScreen extends StatefulWidget {
  const StoredProfileScreen({super.key});

  @override
  State<StoredProfileScreen> createState() => _StoredProfileScreenState();
}

class _StoredProfileScreenState extends State<StoredProfileScreen> {
  Map<String, dynamic> _data = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ProfileStorage.loadProfile();
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pretty = const JsonEncoder.withIndent('  ').convert(_data);
    return Scaffold(
      appBar: AppBar(title: const Text('Stored Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: SelectableText(pretty),
              ),
            ),
    );
  }
}
