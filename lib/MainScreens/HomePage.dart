import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../ SettingsPage.dart';
import '../CustomTabSelector.dart';
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
  String _currentUserId = "";

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
        final parsedData = jsonDecode(response.body) as Map<String, dynamic>?;
        setState(() {
          _profile = parsedData;
          _isLoading = false;
        });
        _currentUserId = _profile?["userId"] ?? "";
        await _fetchProfileImage();
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

  Future<void> _fetchProfileImage() async {
    try {
      final response = await http.get(
        Uri.parse("$BASE_URL/getProfileImage"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        setState(() {
          _profile ??= {};
          _profile!["profileImage"] = jsonData["profileImage"];
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = _profile?["fullName"] ?? "";
    final profileImage = _profile?["profileImage"];

    return Scaffold(
      backgroundColor: Colors.teal.shade700,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Home', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () => Navigator.pushReplacementNamed(context, '/signin'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(
        child: Text(
          _error,
          style: const TextStyle(color: Colors.red),
        ),
      )
          : Padding(
        // Removed SingleChildScrollView to lock scrolling
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          children: [
            // Welcome text
            Text(
              "Welcome to Community App, $fullName!",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),

            // Profile card
            _buildProfileCard(profileImage),
            const SizedBox(height: 8),

            // Tabs
            Expanded(
              child: CustomTabSelector(
                token: widget.token,
                currentUserId: _currentUserId,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: 0, token: widget.token),
    );
  }

  Widget _buildProfileCard(String? profileImage) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: (profileImage != null && profileImage.isNotEmpty)
                        ? NetworkImage(profileImage)
                        : const AssetImage("images/default_profile.png") as ImageProvider,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _profile?["fullName"] ?? "-",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildRatingSection(),
                  const SizedBox(height: 6),
                  const Divider(thickness: 1, height: 20, color: Colors.black26),
                  _buildProfileDetails(),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsPage(
                    token: widget.token,
                    currentProfileImage: profileImage,
                  ),
                ),
              ).then((_) => _fetchProfile());
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.settings, size: 20, color: Colors.black87),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDetails() {
    return Column(
      children: [
        _glassInfoRow(Icons.email, "Email", _profile?["email"]),
        const SizedBox(height: 4),
        _glassInfoRow(Icons.phone, "Phone", _profile?["phone"]),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _glassInfoRow(Icons.location_city, "City", _profile?["city"]),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _glassInfoRow(Icons.map, "Province", _profile?["province"]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _glassInfoRow(Icons.home, "Address", _profile?["address"]),
      ],
    );
  }

  Widget _buildRatingSection() {
    double ratingValue = 4.5; // Hard-coded example rating
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Star icons
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < ratingValue.floor()
                    ? Icons.star
                    : index < ratingValue
                    ? Icons.star_half
                    : Icons.star_border,
                color: Colors.amberAccent.shade200,
                size: 18,
              );
            }),
          ),
          const SizedBox(width: 6),
          // Rating text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$ratingValue / 5",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const Text(
                "Community Rating",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _glassInfoRow(IconData icon, String label, String? value) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.greenAccent,
                      Colors.green.shade800,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 15, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 2),
                    Text(value ?? '-',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
