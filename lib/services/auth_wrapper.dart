import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../screens/login_screen.dart';
import '../main.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  User? _previousUser;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final provider =
        Provider.of<TransactionProvider>(context, listen: false);

        // Phát hiện thay đổi đăng nhập / đăng xuất
        if (user?.uid != _previousUser?.uid) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (user != null) {
              await provider.onUserLogin();
            } else if (_previousUser != null) {
              await provider.onUserLogout();
            }
            _previousUser = user;
          });
          _previousUser = user;
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (user == null) {
          return const LoginScreen();
        }

        return const HomeScreen();
      },
    );
  }
}