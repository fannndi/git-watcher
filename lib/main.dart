import 'package:flutter/material.dart';

import 'app.dart';
import 'services/startup_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await StartupService.init();

  runApp(const GitHubWatcherApp());
}
