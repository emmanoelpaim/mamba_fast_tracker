import 'package:mamba_fast_tracker/features/auth/domain/entities/app_user.dart';

abstract class UserProfileLocalDataSource {
  Future<void> cacheProfile(AppUser user);
  Future<AppUser?> getCachedProfile();
}
