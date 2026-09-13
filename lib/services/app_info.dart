import 'package:package_info_plus/package_info_plus.dart';

import '../utils/constants.dart';

class AppInfo {
  AppInfo._();

  static String version = appVersionName;
  static String build = appBuildNumber;

  static Future<void> load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) {
        version = info.version;
      }
      if (info.buildNumber.isNotEmpty) {
        build = info.buildNumber;
      }
    } catch (_) {}
  }
}
