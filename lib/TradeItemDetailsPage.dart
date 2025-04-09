import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';

class TradeItemDetailsPage extends StatefulWidget {
  final String token;
  final String itemId;

  const TradeItemDetailsPage({
    Key? key,
    required this.token,
    required this.itemId,
  }) : super(key: key);

  @override
  State<TradeItemDetailsPage> createState() => _TradeItemDetailsPageState();
}

class _TradeItemDetailsPageState extends State<TradeItemDetailsPage> {
  static const String BASE_URL = "http://10.0.2.2:8080";

  bool _isLoading = false;
  Map<String, dynamic>? _item;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchItemDetails();
  }

  Future<void> _fetchItemDetails() async {
    setState(() => _isLoading = true);
    try {
      final resp = await http.get(
        Uri.parse("$BASE_URL/api/trade/details/${widget.itemId}"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );
      setState(() => _isLoading = false);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() => _item = data);
      } else if (resp.statusCode == 404) {
        setState(() => _errorMessage = "Item not found.");
      } else {
        final msg = jsonDecode(resp.body)["message"] ?? "Failed to fetch item";
        setState(() => _errorMessage = msg);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB3D1B9),
      appBar: AppBar(
        title: const Text("Item Details"),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage))
          : _item == null
          ? const Center(child: Text("No data"))
          : _buildDetails(),
    );
  }

  Widget _buildDetails() {
    final title = _item?["title"] ?? "No Title";
    final description = _item?["description"] ?? "";
    final price = _item?["price"]?.toString() ?? "0";
    final status = _item?["status"] ?? "Unknown";
    final createdAt = _item?["createdAt"] ?? "";
    final images = _item?["images"] as List<dynamic>? ?? [];

    final ownerFullName = _item?["ownerFullName"] ?? "";
    final ownerEmail = _item?["ownerEmail"] ?? "";
    final ownerPhone = _item?["ownerPhone"] ?? "";
    final ownerAddress = _item?["ownerAddress"] ?? "";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Image Carousel (Fixed to show full image using BoxFit.contain)
          if (images.isNotEmpty)
            CarouselSlider(
              items: images.map((imgUrl) {
                return Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[300],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imgUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      errorBuilder: (ctx, error, stack) =>
                      const Center(child: Text("Image load error")),
                    ),
                  ),
                );
              }).toList(),
              options: CarouselOptions(
                height: 300,
                autoPlay: true,
                enlargeCenterPage: true,
                aspectRatio: 16 / 9,
                autoPlayInterval: const Duration(seconds: 3),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
              ),
            )
          else
            Container(
              height: 200,
              color: Colors.grey[300],
              child: const Center(child: Text("No images available")),
            ),

          const SizedBox(height: 20),

          // Item Info Card
          _buildSectionCard(
            title: "Item Information",
            children: [
              _infoTile("Title", title, Icons.label_important),
              _infoTile("Description", description, Icons.description),
              _infoTile("Price", "\$$price", Icons.monetization_on),
              _infoTile("Status", status, Icons.check_circle_outline),
              if (createdAt.isNotEmpty)
                _infoTile("Posted On", createdAt, Icons.calendar_today),
            ],
          ),

          const SizedBox(height: 20),

          // Owner Info Card
          _buildSectionCard(
            title: "Seller Contact",
            children: [
              _infoTile("Name", ownerFullName, Icons.person),
              if (ownerEmail.isNotEmpty)
                _infoTile("Email", ownerEmail, Icons.email),
              if (ownerPhone.isNotEmpty)
                _infoTile("Phone", ownerPhone, Icons.phone),
              if (ownerAddress.isNotEmpty)
                _infoTile("Address", ownerAddress, Icons.home),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              )),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
