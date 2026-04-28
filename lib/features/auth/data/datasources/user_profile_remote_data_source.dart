abstract class UserProfileRemoteDataSource {
  Future<Map<String, dynamic>?> getProfile({required String uid});
  Future<void> createProfile({
    required String uid,
    required String name,
    required String email,
  });
}
