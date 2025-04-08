import 'package:flutter/material.dart';
import 'package:community_app/bottom_nav_bar.dart';

class TradeItemPage extends StatelessWidget {
  final String token;

  const TradeItemPage({Key? key, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trade Items"), backgroundColor: Colors.green),
      body: const Center(child: Text("Trade your community items here.")),
      bottomNavigationBar: BottomNavBar(selectedIndex: 1, token: token),
    );
  }
}
