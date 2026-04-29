import 'package:get_it/get_it.dart';
import 'package:mamba_fast_tracker/core/di/modules/auth_module.dart';
import 'package:mamba_fast_tracker/core/di/modules/core_module.dart';
import 'package:mamba_fast_tracker/core/di/modules/fasting_module.dart';
import 'package:mamba_fast_tracker/core/di/modules/goals_module.dart';
import 'package:mamba_fast_tracker/core/di/modules/meal_module.dart';
import 'package:mamba_fast_tracker/core/notifications/fasting_end_notification_scheduler.dart';

final sl = GetIt.instance;

Future<void> setupDependencies() async {
  await registerCoreModule(sl);
  await FastingEndNotificationScheduler.ensureLocalTimeZone();
  await sl<FastingEndNotificationScheduler>().initialize();
  registerAuthModule(sl);
  registerGoalsModule(sl);
  registerFastingModule(sl);
  registerMealModule(sl);
}
