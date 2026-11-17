import 'package:flutter_test/flutter_test.dart';
import 'package:thread_app/data/repositories/auth_repository.dart';
import 'package:thread_app/providers/auth_provider.dart';

class MockAuthRepoForReset extends AuthRepository {
  MockAuthRepoForReset() : super('http://mock');

  bool shouldThrow = false;
  String? errorToThrow;
  String? lastEmailSent;
  String? lastOtpSent;
  String? lastNewPassword;
  int sendCalls = 0;
  int sendOtpCalls = 0;
  int verifyOtpCalls = 0;
  int resetOtpCalls = 0;
  int changePasswordCalls = 0;

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    sendCalls++;
    lastEmailSent = email;
    if (shouldThrow) {
      throw Exception(errorToThrow ?? 'GENERIC_ERROR');
    }
  }

  @override
  Future<Map<String, dynamic>> sendForgotPasswordOtp(String email) async {
    sendOtpCalls++;
    lastEmailSent = email;
    if (shouldThrow) {
      throw Exception(errorToThrow ?? 'GENERIC_ERROR');
    }
    return {'success': true, 'message': 'Mã OTP đã gửi'};
  }

  @override
  Future<Map<String, dynamic>> verifyForgotPasswordOtp(String email, String otp) async {
    verifyOtpCalls++;
    lastEmailSent = email;
    lastOtpSent = otp;
    if (shouldThrow) {
      throw Exception(errorToThrow ?? 'Mã OTP không chính xác');
    }
    return {'success': true, 'message': 'Xác thực thành công'};
  }

  @override
  Future<Map<String, dynamic>> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    resetOtpCalls++;
    lastEmailSent = email;
    lastOtpSent = otp;
    lastNewPassword = newPassword;
    if (shouldThrow) {
      throw Exception(errorToThrow ?? 'Lỗi đặt lại mật khẩu');
    }
    return {'success': true, 'message': 'Thành công'};
  }

  @override
  Future<void> changePasswordLoggedIn({
    required String currentPassword,
    required String newPassword,
  }) async {
    changePasswordCalls++;
    lastNewPassword = newPassword;
    if (shouldThrow) {
      throw Exception(errorToThrow ?? 'Mật khẩu hiện tại không chính xác');
    }
  }
}

void main() {
  group('AuthProvider Forgot Password Tests', () {
    late MockAuthRepoForReset mockRepo;
    late AuthProvider authProvider;

    setUp(() {
      mockRepo = MockAuthRepoForReset();
      authProvider = AuthProvider(mockRepo);
    });

    test('forgotPassword succeeds when repository succeeds', () async {
      final result = await authProvider.forgotPassword('user@example.com');

      expect(result, isTrue);
      expect(mockRepo.sendCalls, equals(1));
      expect(mockRepo.lastEmailSent, equals('user@example.com'));
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.errorMessage, isNull);
    });

    test('forgotPassword maps EMAIL_NOT_FOUND to Vietnamese message', () async {
      mockRepo.shouldThrow = true;
      mockRepo.errorToThrow = 'EMAIL_NOT_FOUND';

      final result = await authProvider.forgotPassword('notfound@example.com');

      expect(result, isFalse);
      expect(mockRepo.sendCalls, equals(1));
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.errorMessage, equals('Không tìm thấy tài khoản với email này'));
    });

    test('forgotPassword maps USER_NOT_FOUND to Vietnamese message', () async {
      mockRepo.shouldThrow = true;
      mockRepo.errorToThrow = 'USER_NOT_FOUND: The user was not found';

      final result = await authProvider.forgotPassword('unknown@example.com');

      expect(result, isFalse);
      expect(authProvider.errorMessage, equals('Không tìm thấy tài khoản với email này'));
    });

    test('forgotPassword maps INVALID_EMAIL to Vietnamese message', () async {
      mockRepo.shouldThrow = true;
      mockRepo.errorToThrow = 'INVALID_EMAIL';

      final result = await authProvider.forgotPassword('bad-email');

      expect(result, isFalse);
      expect(authProvider.errorMessage, equals('Địa chỉ email không hợp lệ'));
    });

    test('forgotPassword maps TOO_MANY_REQUESTS to Vietnamese message', () async {
      mockRepo.shouldThrow = true;
      mockRepo.errorToThrow = 'TOO_MANY_REQUESTS';

      final result = await authProvider.forgotPassword('busy@example.com');

      expect(result, isFalse);
      expect(authProvider.errorMessage, equals('Yêu cầu quá nhiều lần. Vui lòng thử lại sau'));
    });

    test('forgotPassword handles generic error cleanly', () async {
      mockRepo.shouldThrow = true;
      mockRepo.errorToThrow = 'Network timeout occurred';

      final result = await authProvider.forgotPassword('test@example.com');

      expect(result, isFalse);
      expect(authProvider.errorMessage, equals('Network timeout occurred'));
    });

    // ── In-App OTP Tests ──────────────────────────────────────────────────
    test('sendForgotPasswordOtp thành công và set state đúng', () async {
      final success = await authProvider.sendForgotPasswordOtp('user@test.com');

      expect(success, isTrue);
      expect(mockRepo.sendOtpCalls, equals(1));
      expect(mockRepo.lastEmailSent, equals('user@test.com'));
      expect(authProvider.errorMessage, isNull);
    });

    test('verifyForgotPasswordOtp xác thực mã thành công', () async {
      final success = await authProvider.verifyForgotPasswordOtp('user@test.com', '123456');

      expect(success, isTrue);
      expect(mockRepo.verifyOtpCalls, equals(1));
      expect(mockRepo.lastOtpSent, equals('123456'));
    });

    test('resetPasswordWithOtp từ chối nếu mật khẩu mới vi phạm 7 quy tắc', () async {
      // Mật khẩu yếu (thiếu chữ hoa, ký tự đặc biệt, quá ngắn)
      final success = await authProvider.resetPasswordWithOtp(
        email: 'user@test.com',
        otp: '123456',
        newPassword: 'weak',
      );

      expect(success, isFalse);
      expect(mockRepo.resetOtpCalls, equals(0)); // Không gọi repo
      expect(authProvider.errorMessage, contains('Password must be at least 8 characters'));
    });

    test('resetPasswordWithOtp thành công khi mật khẩu thỏa mãn đủ 7 quy tắc', () async {
      // Mật khẩu hợp lệ: 8+ ký tự, HOA, thường, số, ký tự đặc biệt, không whitespace, không common
      const validPassword = 'StrongPass123!@#';

      final success = await authProvider.resetPasswordWithOtp(
        email: 'user@test.com',
        otp: '123456',
        newPassword: validPassword,
      );

      expect(success, isTrue);
      expect(mockRepo.resetOtpCalls, equals(1));
      expect(mockRepo.lastNewPassword, equals(validPassword));
      expect(authProvider.errorMessage, isNull);
    });

    // ── Logged-In Change Password Tests ───────────────────────────────────
    test('changePassword từ chối nếu mật khẩu mới trùng mật khẩu cũ', () async {
      final success = await authProvider.changePassword(
        currentPassword: 'StrongPass123!@#',
        newPassword: 'StrongPass123!@#',
      );

      expect(success, isFalse);
      expect(mockRepo.changePasswordCalls, equals(0));
      expect(authProvider.errorMessage, equals('Mật khẩu mới phải khác mật khẩu hiện tại'));
    });

    test('changePassword từ chối nếu mật khẩu mới không thỏa 7 quy tắc', () async {
      final success = await authProvider.changePassword(
        currentPassword: 'CurrentPass123!@#',
        newPassword: '123', // Quá ngắn
      );

      expect(success, isFalse);
      expect(mockRepo.changePasswordCalls, equals(0));
      expect(authProvider.errorMessage, contains('Password must be at least 8 characters'));
    });

    test('changePassword thành công khi mật khẩu mới hợp lệ và khác mật khẩu cũ', () async {
      const currentPwd = 'CurrentPass123!@#';
      const newPwd = 'NewSuperStrongPass456\$%^';

      final success = await authProvider.changePassword(
        currentPassword: currentPwd,
        newPassword: newPwd,
      );

      expect(success, isTrue);
      expect(mockRepo.changePasswordCalls, equals(1));
      expect(mockRepo.lastNewPassword, equals(newPwd));
      expect(authProvider.errorMessage, isNull);
    });
  });
}
