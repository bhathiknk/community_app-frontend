import 'package:community_app/LogingPages/signin_page.dart';
import 'package:community_app/welcome_page.dart';
import 'package:flutter/material.dart';

import 'LogingPages/signup_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Community App',
      // Set up named routes
      routes: {
        '/': (context) => const WelcomePage(),
        '/signin': (context) => const SignInPage(),
        '/signup': (context) => const SignUpPage(),
      },
      // Initial route is the welcome page
      initialRoute: '/',
    );
  }
}
