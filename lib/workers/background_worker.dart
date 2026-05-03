import 'package:workmanager/workmanager.dart';

import '../services/notification_service.dart';
import '../services/sync_service.dart';
import '../utils/constants.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == githubSyncTask) {
      await NotificationService.init();
      await SyncService.checkUpdates();
    }
    return Future.value(true);
  });
}
