// lib/LogingPages/signin_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SignInPage extends StatefulWidget {
  /// Called when sign-in succeeds, passing the auth token.
  final void Function(String token) onSignedIn;

  const SignInPage({
    Key? key,
    required this.onSignedIn,
  }) : super(key: key);

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  static const _baseUrl = "http://10.0.2.2:8080";

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    labelStyle: const TextStyle(color: Colors.black87),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.circular(12),
    ),
    contentPadding: const EdgeInsets.symmetric(
        vertical: 18.0, horizontal: 16.0),
  );

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final resp = await http.post(
        Uri.parse("$_baseUrl/api/auth/signin"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": pass}),
      );
      Navigator.pop(context); // close spinner

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final token = data["token"] as String?;
        if (token != null && token.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login successful!')),
          );
          widget.onSignedIn(token);
          return;
        }
      }

      // failure path
      final err = resp.statusCode != 200
          ? jsonDecode(resp.body)["message"] ?? "Invalid credentials"
          : "Login failed";
      _showError(err);
    } catch (_) {
      Navigator.pop(context);
      _showError("Network error — please try again.");
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Oops!"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade700,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    "images/signin.jpg",
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Welcome Back",
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: _inputDecoration('Email'),
                        validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter email' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: true,
                        decoration: _inputDecoration('Password'),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Enter password'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Sign In'),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushReplacementNamed(context, '/signup'),
                        child: const Text(
                          "Don’t have an account? Sign Up",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
