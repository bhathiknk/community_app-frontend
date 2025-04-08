import 'package:flutter/material.dart';
import 'package:community_app/bottom_nav_bar.dart';

class DonationsPage extends StatelessWidget {
  final String token;

  const DonationsPage({Key? key, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Donations"), backgroundColor: Colors.green),
      body: const Center(child: Text("Help others by donating!")),
      bottomNavigationBar: BottomNavBar(selectedIndex: 2, token: token),
    );
  }
}
