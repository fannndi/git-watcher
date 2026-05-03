import 'package:flutter/material.dart';

import '../services/storage_service.dart';

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  final StorageService _storage = StorageService();
  Map<String, int> _updates = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUpdates();
  }

  Future<void> _loadUpdates() async {
    final updates = await _storage.getUpdateSummary();
    if (!mounted) return;
    setState(() {
      _updates = updates;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update GitHub')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _updates.isEmpty
                ? const Center(child: Text('Belum ada update baru'))
                : ListView(
                    children: _updates.entries.map((entry) {
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.new_releases_outlined),
                          title: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text('+${entry.value} commit'),
                        ),
                      );
                    }).toList(),
                  ),
      ),
    );
  }
}
