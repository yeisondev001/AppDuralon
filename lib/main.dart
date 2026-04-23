import 'package:flutter/material.dart';
import 'package:app_duralon/pages/login_screen.dart';

void main() {
  runApp(const AppDuralon());
}

class AppDuralon extends StatelessWidget {
  const AppDuralon({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Plasticos Duralon',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
