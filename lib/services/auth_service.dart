import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Đăng ký tài khoản mới
  Future<UserCredential> register(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password.trim());
  }

  /// Đăng nhập
  Future<UserCredential> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password.trim());
  }

  /// Đăng xuất
  Future<void> logout() async => await _auth.signOut();

  /// Gửi email reset mật khẩu
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}