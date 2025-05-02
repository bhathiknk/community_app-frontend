import 'package:flutter/material.dart';

import 'MainScreens/DonationsPage.dart';
import 'MainScreens/HomePage.dart';
import 'MainScreens/TradeItemPage.dart';

class BottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final String token;

  const BottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.token,
  }) : super(key: key);

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  late int _currentIndex;

  @override
  void initState() {
    // Initialize from the passed‐in selectedIndex
    _currentIndex = widget.selectedIndex;
    super.initState();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    // Update the indicator immediately
    setState(() {
      _currentIndex = index;
    });

    // Then navigate
    Widget page;
    switch (index) {
      case 0:
        page = TradeItemPage(token: widget.token);
        break;
      case 1:
        page = DonationsPage(token: widget.token);
        break;
      case 2:
        page = HomePage(token: widget.token);
        break;
      default:
        page = TradeItemPage(token: widget.token);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      currentIndex: _currentIndex,           // now follows your setState
      onTap: _onTabTapped,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey[700],
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.swap_horiz),
          label: "Trade",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.volunteer_activism),
          label: "Donations",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Home",
        ),
      ],
    );
  }
}
