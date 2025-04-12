import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../AddItemPage.dart';
import '../MyItemsPage.dart';
import '../TradeItemRequestPage.dart';
import '../bottom_nav_bar.dart';

class HomePage extends StatefulWidget {
  final String token;

  const HomePage({Key? key, required this.token}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String _error = '';
  static const String BASE_URL = "http://10.0.2.2:8080";

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await http.get(
        Uri.parse("$BASE_URL/api/user/profile"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _profile = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Failed to load profile";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Something went wrong: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = _profile?["fullName"] ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFB3D1B9),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Home'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/signin');
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
          : Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Welcome to Community App, $fullName!",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Profile Info
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: const Color(0xFFFDFDFD),
              elevation: 2,
              shadowColor: Colors.black12,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                child: Column(
                  children: [
                    const Text(
                      "Your Profile Info",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Divider(thickness: 1, height: 20, color: Colors.grey),
                    _profileItem(Icons.person, "Full Name", _profile?["fullName"]),
                    _profileItem(Icons.email, "Email", _profile?["email"]),
                    _profileItem(Icons.phone, "Phone", _profile?["phone"]),
                    _profileItem(Icons.home, "Address", _profile?["address"]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tabs
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const TabBar(
                        indicatorColor: Colors.green,
                        labelColor: Colors.green,
                        unselectedLabelColor: Colors.grey,
                        tabs: [
                          Tab(text: 'Trade'),
                          Tab(text: 'Donations'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Buttons inside each tab
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildGrid([
                            _actionCard("Add Item", Icons.add_box),
                            _actionCard("My Items", Icons.inventory),
                            _actionCard("Trade Request", Icons.swap_horiz),
                          ]),
                          _buildGrid([
                            _actionCard("Add Donation", Icons.volunteer_activism),
                            _actionCard("My Donations", Icons.card_giftcard),
                            _actionCard("Donated Items", Icons.redeem),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: 0, token: widget.token),
    );
  }

  Widget _profileItem(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black54,
                    )),
                const SizedBox(height: 2),
                Text(value ?? '-',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(String title, IconData icon) {
    return GestureDetector(
      onTap: () {
          if (title == "Add Item") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddItemPage(token: widget.token),
              ),
            );
          } else if (title == "My Items") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MyItemsPage(token: widget.token),
              ),
            );
          } else if (title == "Trade Request")
          {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TradeItemRequestPage(token: widget.token),
              ),
            );
          }
        },

      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Colors.green),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<Widget> items) {
    return GridView.count(
      crossAxisCount: 3,
      padding: const EdgeInsets.all(8),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: items,
    );
  }
}
