import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard.dart';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  final Function(Brightness brightness) changeTheme;

  const SplashScreen({super.key, required this.changeTheme});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startApp();
  }

  void _startApp() async {
    await Future.delayed(const Duration(seconds: 5));

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                userId != null
                    ? DashboardPage(changeTheme: widget.changeTheme)
                    : LoginPage(changeTheme: widget.changeTheme),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: Lottie.asset('assets/animations/splash.json')),
    );
  }
}
