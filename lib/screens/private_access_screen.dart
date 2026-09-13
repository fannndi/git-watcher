import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/github_credentials.dart';
import '../services/app_settings_controller.dart';
import '../services/storage_service.dart';
import '../utils/strings.dart';
import '../widgets/chips.dart';
import '../widgets/settings_section.dart';

class PrivateAccessScreen extends StatefulWidget {
  const PrivateAccessScreen({super.key});

  @override
  State<PrivateAccessScreen> createState() => _PrivateAccessScreenState();
}

class _PrivateAccessScreenState extends State<PrivateAccessScreen> {
  final StorageService _storage = StorageService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  bool _tokenObscured = true;
  bool _hasCredentials = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _loadCredentials() async {
    final credentials = await _storage.getCredentials();
    if (!mounted) return;

    setState(() {
      _hasCredentials = credentials.isNotEmpty;
      if (credentials.isNotEmpty) {
        _usernameController.text = credentials.username;
        _tokenController.text = credentials.token;
      }
    });
  }

  Future<void> _saveCredentials(AppStrings strings) async {
    final username = _usernameController.text.trim();
    final token = _tokenController.text.trim();

    if (username.isEmpty || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.usernameTokenRequired)),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _storage.saveCredentials(
        GitHubCredentials(username: username, token: token),
      );
      if (!mounted) return;
      setState(() => _hasCredentials = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.credentialsSaved)),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _clearCredentials(AppStrings strings) async {
    await _storage.clearCredentials();
    if (!mounted) return;

    setState(() {
      _hasCredentials = false;
      _usernameController.clear();
      _tokenController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.credentialsCleared)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: appSettingsController,
      builder: (context, settings, _) {
        final strings = stringsFor(settings.languageCode);
        final colorScheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(title: Text(strings.privateAccess)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SettingsSection(
                title: strings.privateAccess,
                icon: Icons.lock_outline,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          strings.privateMode,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      InfoChip(
                        label: _hasCredentials
                            ? strings.credentialsActive
                            : strings.credentialsEmpty,
                        accent: _hasCredentials,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.privateModeSubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: strings.githubUsername,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tokenController,
                    obscureText: _tokenObscured,
                    decoration: InputDecoration(
                      labelText: strings.githubToken,
                      helperText: strings.githubTokenHelper,
                      prefixIcon: const Icon(Icons.key_outlined),
                      suffixIcon: IconButton(
                        tooltip: _tokenObscured ? strings.show : strings.hide,
                        icon: Icon(
                          _tokenObscured
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _tokenObscured = !_tokenObscured),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isSaving
                              ? null
                              : () => _saveCredentials(strings),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(strings.saveCredentials),
                        ),
                      ),
                      if (_hasCredentials) ...[
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => _clearCredentials(strings),
                          icon: const Icon(Icons.delete_outline),
                          label: Text(strings.clearCredentials),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.error,
                            side: BorderSide(color: colorScheme.error),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
