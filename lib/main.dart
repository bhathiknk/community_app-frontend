// lib/main.dart

import 'package:flutter/material.dart';
import 'services/websocket_service.dart';
import 'LogingPages/signin_page.dart';
import 'LogingPages/signup_page.dart';
import 'MainScreens/TradeItemPage.dart';
import 'welcome_page.dart';

/// 1) Create a single, global messenger key:
final GlobalKey<ScaffoldMessengerState> messengerKey =
GlobalKey<ScaffoldMessengerState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

/// 2) Turn MyApp into a StatefulWidget so we can hook up our global listeners
class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // 3) Subscribe once to both streams and show a SnackBar using our global key
    WebSocketService().tradeStream.listen((payload) {
      messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            "New trade request for “${payload['requestedItemTitle']}”",
          ),
          duration: const Duration(seconds: 10), // ⏱ Show for 10 seconds
        ),
      );
    });

    WebSocketService().donationStream.listen((payload) {
      messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            "New donation request for “${payload['donationTitle']}”",
          ),
          duration: const Duration(seconds: 10), // ⏱ Show for 10 seconds
        ),
      );
    });

  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Community App',

      // 4) Wire up our global messenger key here:
      scaffoldMessengerKey: messengerKey,

      initialRoute: '/',
      routes: {
        '/': (_) => const WelcomePage(),
        '/signin': (context) => SignInPage(
          onSignedIn: (token) {
            // connect WebSocket once we have a token
            WebSocketService().connect(token);
            // navigate into your trade page
            Navigator.pushReplacementNamed(
              context,
              '/trade',
              arguments: token,
            );
          },
        ),
        '/signup': (_) => const SignUpPage(),
        '/trade': (context) {
          final token = ModalRoute.of(context)!.settings.arguments as String;
          return TradeItemPage(token: token);
        },
      },
    );
  }
}
