import 'package:get_it/get_it.dart';
import 'package:mamba_fast_tracker/core/di/modules/auth_module.dart';
import 'package:mamba_fast_tracker/core/di/modules/core_module.dart';

final sl = GetIt.instance;

Future<void> setupDependencies() async {
  await registerCoreModule(sl);
  registerAuthModule(sl);
}
