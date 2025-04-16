import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MyDonationsPage extends StatefulWidget {
  final String token;
  const MyDonationsPage({Key? key, required this.token}) : super(key: key);

  @override
  State<MyDonationsPage> createState() => _MyDonationsPageState();
}

class _MyDonationsPageState extends State<MyDonationsPage> {
  bool _isLoading = false;
  List<dynamic> _donations = [];
  static const String BASE_URL = "http://10.0.2.2:8080";

  @override
  void initState() {
    super.initState();
    _fetchDonations();
  }

  Future<void> _fetchDonations() async {
    setState(() => _isLoading = true);
    try {
      final resp = await http.get(
        Uri.parse("$BASE_URL/api/donations/my"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() => _donations = data);
      } else {
        debugPrint("Failed to load donations: ${resp.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Load failed: ${resp.statusCode}")),
        );
      }
    } catch (e) {
      debugPrint("Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Donations"),
        backgroundColor: Colors.teal.shade600,
      ),
      body: Stack(
        children: [
          // Subtle gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade50, Colors.teal.shade100],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _donations.isEmpty
              ? const Center(
            child: Text("You have no donations yet."),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _donations.length,
            itemBuilder: (context, index) {
              final donation = _donations[index];
              final title = donation["title"] ?? "No Title";
              final description = donation["description"] ?? "";
              final images = donation["images"] as List<dynamic>? ?? [];

              return _buildDonationCard(title, description, images);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDonationCard(String title, String description, List<dynamic> images) {
    final imageUrl = (images.isNotEmpty) ? images.first : null;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // Thumbnail
            imageUrl != null
                ? Image.network(
              imageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            )
                : Container(
              color: Colors.grey.shade300,
              width: 100,
              height: 100,
              child: const Icon(Icons.volunteer_activism, size: 40),
            ),
            // Donation details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
