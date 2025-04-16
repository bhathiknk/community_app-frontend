import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  final List<String> _provinceList = [
    'Western',
    'Central',
    'Southern',
    'North-Western',
    'Sabaragamuva',
    'Northern',
    'Eastern',
    'Uva',
    'North-Central',
  ];
  String _selectedProvince = 'Western';

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

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final address = _addressController.text.trim();
    final city = _cityController.text.trim();
    final province = _selectedProvince;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.post(
        Uri.parse("$BASE_URL/api/auth/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fullName": fullName,
          "email": email,
          "phone": phone,
          "address": address,
          "password": password,
          "city": city,
          "province": province,
        }),
      );

      Navigator.pop(context);

      if (response.statusCode == 200) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Success!"),
            content: const Text("Account created successfully."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              )
            ],
          ),
        );
        Navigator.pushReplacementNamed(context, '/signin');
      } else {
        final error = jsonDecode(response.body);
        _showError(error["message"] ?? "Signup failed. Try again.");
      }
    } catch (e) {
      Navigator.pop(context);
      _showError("Network error. Please try again.");
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    "images/signup.jpg",
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),

                const SizedBox(height: 12),
                const Text(
                  "Create Account",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration('Full Name'),
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Enter your name'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        decoration: _inputDecoration('Email'),
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Enter your email'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: _inputDecoration('Phone Number'),
                              validator: (value) =>
                              (value == null || value.isEmpty)
                                  ? 'Enter your phone'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: _inputDecoration('City'),
                              validator: (value) =>
                              (value == null || value.isEmpty)
                                  ? 'Enter your city'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedProvince,
                              decoration: _inputDecoration('Province'),
                              items: _provinceList.map((p) {
                                return DropdownMenuItem<String>(
                                  value: p,
                                  child: Text(p),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedProvince = val ?? 'Western';
                                });
                              },
                              validator: (value) =>
                              (value == null || value.isEmpty)
                                  ? 'Select a province'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: _inputDecoration('Password'),
                              validator: (value) =>
                              (value == null || value.isEmpty)
                                  ? 'Enter a password'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _addressController,
                        decoration: _inputDecoration('Address'),
                        validator: (value) =>
                        (value == null || value.isEmpty)
                            ? 'Enter your address'
                            : null,
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Sign Up'),
                      ),
                      const SizedBox(height: 16),

                      GestureDetector(
                        onTap: () =>
                            Navigator.pushReplacementNamed(context, '/signin'),
                        child: const Text(
                          "Already have an account? Sign In",
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
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
