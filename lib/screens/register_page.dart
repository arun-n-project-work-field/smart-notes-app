import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/login_layout.dart';
import '../data/user_model.dart';
import '../services/user_database.dart';
import '../utils/route_transitions.dart';
import 'dashboard.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  final Function(Brightness brightness) changeTheme;

  const RegisterPage({super.key, required this.changeTheme});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _register() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showError("Please fill in all fields.");
      return;
    }

    if (password != confirmPassword) {
      _showError("Passwords do not match.");
      return;
    }

    if (await UserDatabase.instance.usernameExists(username)) {
      _showError("Username already taken.");
      return;
    }

    final user = UserModel(username: username, password: password);
    int newId = await UserDatabase.instance.insertUser(user);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', newId);
    await prefs.setString('username', user.username);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardPage(changeTheme: widget.changeTheme),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade100,
      labelStyle: const TextStyle(color: Colors.black),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.black),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoginLayout(
      title: 'Sign Up',
      icon: Icons.person_add_alt_1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            style: TextStyle(color: Colors.black),
            cursorColor: Colors.black,
            controller: _usernameController,
            decoration: _inputDecoration("Username"),
          ),
          const SizedBox(height: 20),
          TextField(
            style: TextStyle(color: Colors.black),
            cursorColor: Colors.black,
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: _inputDecoration("Password").copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.black,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            style: TextStyle(color: Colors.black),
            cursorColor: Colors.black,
            controller: _confirmPasswordController,
            obscureText: _obscurePassword,
            decoration: _inputDecoration("Confirm Password"),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Register',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  createSlideRoute(LoginPage(changeTheme: widget.changeTheme)),
                );
              },
              child: const Text(
                "Already have an account? Sign In",
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
