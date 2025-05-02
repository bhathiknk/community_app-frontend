import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../MainScreens/HomePage.dart';
import '../MainScreens/TradeItemPage.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  static const String BASE_URL = "http://10.0.2.2:8080";

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
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
      contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
    );
  }

  Future<void> _signIn() async {
    // 1) Validate form fields
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // 2) Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 3) Make POST request
      final response = await http.post(
        Uri.parse("$BASE_URL/api/auth/signin"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      // 4) Close loading dialog
      Navigator.pop(context);

      // 5) Check response status
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Token logic: Must be non-null & non-empty to succeed
        final token = data["token"];
        if (token != null && token is String && token.isNotEmpty) {
          // Show success & proceed
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login successful!')),
          );

          // Navigate to TradeItemPage instead of HomePage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TradeItemPage(token: token),
            ),
          );
          return; // ensure we don't show any error after success
        } else {
          // If token is empty or null, treat it as login failure
          _showError("Login failed. Please try again.");
          return;
        }
      } else {
        // Non-200 => use message from server if available
        final error = jsonDecode(response.body);
        _showError(error["message"] ?? "Invalid credentials.");
        return;
      }
    } catch (e) {
      // 6) Catch network/JSON errors
      Navigator.pop(context);
      _showError("Something went wrong. Please check your connection.");
      return;
    }
  }

  void _showError(String message) {
    // We show an AlertDialog for errors
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Oops!"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Try Again"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade700,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Top image
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    "images/signin.jpg",
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                const Text(
                  "Welcome Back",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,color: Colors.white)
                ),
                const SizedBox(height: 20),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: _inputDecoration('Email'),
                        validator: (value) =>
                        (value == null || value.isEmpty) ? 'Enter your email' : null,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: _inputDecoration('Password'),
                        validator: (value) =>
                        (value == null || value.isEmpty) ? 'Enter your password' : null,
                      ),
                      const SizedBox(height: 24),

                      // Sign In button
                      ElevatedButton(
                        onPressed: _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Sign In'),
                      ),
                      const SizedBox(height: 16),

                      // Link to Sign Up
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(context, '/signup'),
                        child: const Text(
                          "Don’t have an account? Sign Up",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
