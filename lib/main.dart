import 'package:flutter/material.dart';
import 'LogingPages/signin_page.dart';
import 'welcome_page.dart';
import 'LogingPages/signup_page.dart';

void main() async {
  // ⚠️ Ensure plugin bindings are ready before runApp()
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Community App',
      routes: {
        '/': (context) => const WelcomePage(),
        '/signin': (context) => const SignInPage(),
        '/signup': (context) => const SignUpPage(),
      },
      initialRoute: '/',
    );
  }
}
