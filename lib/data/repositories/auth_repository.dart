import '../../models/user_model.dart';

abstract class IAuthRepository {
  Future<UserModel?> login(String email, String password);
  Future<UserModel?> register(String username, String email, String password);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
}

class AuthRepository implements IAuthRepository {
  // Sau này sẽ inject API Client hoặc Firebase vào đây
  
  @override
  Future<UserModel?> login(String email, String password) async {
    // Giả lập gọi API
    await Future.delayed(const Duration(seconds: 1));
    return UserModel(
      id: '1',
      username: 'thanh_hau',
      email: email,
      bio: 'Senior Backend & Flutter Developer',
      avatarUrl: 'https://i.pravatar.cc/150?u=1',
    );
  }

  @override
  Future<UserModel?> register(String username, String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    return UserModel(
      id: '2',
      username: username,
      email: email,
    );
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return null; // Giả lập chưa login
  }
}
