import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authService = AuthService();

  // Controllers
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regConfirmCtrl = TextEditingController();

  bool _loginPassHidden = true;
  bool _regPassHidden = true;
  bool _loading = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() => _errorMsg = null));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _regConfirmCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) => setState(() => _errorMsg = msg);

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Email chưa được đăng ký.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Sai email hoặc mật khẩu.';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng.';
      case 'weak-password':
        return 'Mật khẩu quá yếu (tối thiểu 6 ký tự).';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'too-many-requests':
        return 'Quá nhiều lần thử. Vui lòng thử lại sau.';
      default:
        return e.message ?? 'Đã có lỗi xảy ra.';
    }
  }

  Future<void> _login() async {
    final email = _loginEmailCtrl.text.trim();
    final pass = _loginPassCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      _showError('Vui lòng nhập đầy đủ email và mật khẩu.');
      return;
    }
    setState(() { _loading = true; _errorMsg = null; });
    try {
      await _authService.login(email, pass);
      // AuthWrapper sẽ tự chuyển màn hình khi user thay đổi
    } on FirebaseAuthException catch (e) {
      _showError(_friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    final email = _regEmailCtrl.text.trim();
    final pass = _regPassCtrl.text.trim();
    final confirm = _regConfirmCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      _showError('Vui lòng nhập đầy đủ thông tin.');
      return;
    }
    if (pass != confirm) {
      _showError('Mật khẩu xác nhận không khớp.');
      return;
    }
    if (pass.length < 6) {
      _showError('Mật khẩu tối thiểu 6 ký tự.');
      return;
    }
    setState(() { _loading = true; _errorMsg = null; });
    try {
      await _authService.register(email, pass);
    } on FirebaseAuthException catch (e) {
      _showError(_friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _loginEmailCtrl.text.trim();
    if (email.isEmpty) {
      _showError('Nhập email vào ô trên rồi bấm "Quên mật khẩu".');
      return;
    }
    try {
      await _authService.sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi link đặt lại mật khẩu vào email.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(_friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              children: [
                // ── Logo / tiêu đề ──
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.blue.shade200,
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.account_balance_wallet,
                      color: Colors.white, size: 44),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Smart Expense',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent),
                ),
                const Text(
                  'Quản lý tài chính thông minh',
                  style: TextStyle(color: Colors.blueGrey, fontSize: 13),
                ),
                const SizedBox(height: 28),

                // ── Card chứa form ──
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Tab
                        TabBar(
                          controller: _tabController,
                          labelColor: Colors.blueAccent,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Colors.blueAccent,
                          tabs: const [
                            Tab(text: 'ĐĂNG NHẬP'),
                            Tab(text: 'ĐĂNG KÝ'),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Form
                        SizedBox(
                          height: 260,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildLoginForm(),
                              _buildRegisterForm(),
                            ],
                          ),
                        ),

                        // Error message
                        if (_errorMsg != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_errorMsg!,
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 13)),
                              ),
                            ]),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Button
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _loading
                                ? null
                                : () {
                              if (_tabController.index == 0) {
                                _login();
                              } else {
                                _register();
                              }
                            },
                            child: _loading
                                ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                                : Text(
                              _tabController.index == 0
                                  ? 'ĐĂNG NHẬP'
                                  : 'ĐĂNG KÝ',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        TextField(
          controller: _loginEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDeco('Email', Icons.email_outlined),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _loginPassCtrl,
          obscureText: _loginPassHidden,
          decoration: _inputDeco('Mật khẩu', Icons.lock_outline).copyWith(
            suffixIcon: IconButton(
              icon: Icon(_loginPassHidden
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              onPressed: () =>
                  setState(() => _loginPassHidden = !_loginPassHidden),
            ),
          ),
          onSubmitted: (_) => _login(),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _forgotPassword,
            child: const Text('Quên mật khẩu?',
                style: TextStyle(fontSize: 12, color: Colors.blueAccent)),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      children: [
        TextField(
          controller: _regEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDeco('Email', Icons.email_outlined),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _regPassCtrl,
          obscureText: _regPassHidden,
          decoration: _inputDeco('Mật khẩu (tối thiểu 6 ký tự)', Icons.lock_outline)
              .copyWith(
            suffixIcon: IconButton(
              icon: Icon(_regPassHidden
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              onPressed: () =>
                  setState(() => _regPassHidden = !_regPassHidden),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _regConfirmCtrl,
          obscureText: true,
          decoration: _inputDeco('Xác nhận mật khẩu', Icons.lock_outline),
          onSubmitted: (_) => _register(),
        ),
      ],
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 20, color: Colors.blueGrey),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    isDense: true,
  );
}
