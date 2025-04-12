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

  // ================== DATA FETCHING ================== //
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

  // ================== UI BUILD ================== //
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB3D1B9),
      appBar: AppBar(
        title: const Text("Item Details"),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      // The "Send Trade Request" at the bottom
      bottomNavigationBar: _buildBottomBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage))
          : _item == null
          ? const Center(child: Text("No data"))
          : _buildPageContent(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: ElevatedButton(
        onPressed: _showTradeOptionsDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          "Send Trade Request",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildPageContent() {
    final images = _item?["images"] as List<dynamic>? ?? [];

    return Column(
      children: [
        // 1) Image Carousel (fixed height)
        SizedBox(
          height: 280,
          child: _buildCarousel(images),
        ),
        // 2) Info sections
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildInfoSections(),
          ),
        ),
      ],
    );
  }

  Widget _buildCarousel(List<dynamic> images) {
    if (images.isNotEmpty) {
      return CarouselSlider(
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
                fit: BoxFit.contain, // show entire image
                width: double.infinity,
                errorBuilder: (ctx, error, stack) =>
                const Center(child: Text("Image load error")),
              ),
            ),
          );
        }).toList(),
        options: CarouselOptions(
          height: 280,
          autoPlay: true,
          enlargeCenterPage: true,
          aspectRatio: 16 / 9,
          autoPlayInterval: const Duration(seconds: 3),
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
        ),
      );
    } else {
      return Container(
        color: Colors.grey[300],
        child: const Center(child: Text("No images available")),
      );
    }
  }

  Widget _buildInfoSections() {
    final title = _item?["title"] ?? "No Title";
    final description = _item?["description"] ?? "";
    final price = _item?["price"]?.toString() ?? "0";
    final status = _item?["status"] ?? "Unknown";
    final createdAt = _item?["createdAt"] ?? "";

    final ownerFullName = _item?["ownerFullName"] ?? "";
    final ownerEmail = _item?["ownerEmail"] ?? "";
    final ownerPhone = _item?["ownerPhone"] ?? "";
    final ownerAddress = _item?["ownerAddress"] ?? "";

    return Column(
      children: [
        // Item Info
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
        const SizedBox(height: 16),

        // Seller Info
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
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
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

  // ================== TRADE REQUEST CREATION ================== //

  void _showTradeOptionsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String selectedOption = "MONEY"; // "MONEY" or "ITEM"
        TextEditingController moneyCtrl = TextEditingController();

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 100),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        "Send Trade Request",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                     SizedBox(height: 20),
                    const Text("Choose Offer Type:"),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Radio<String>(
                          value: "MONEY",
                          groupValue: selectedOption,
                          onChanged: (val) {
                            if (val != null) {
                              setStateDialog(() => selectedOption = val);
                            }
                          },
                        ),
                        const Text("Offer Money"),
                        const SizedBox(width: 20),
                        Radio<String>(
                          value: "ITEM",
                          groupValue: selectedOption,
                          onChanged: (val) {
                            if (val != null) {
                              setStateDialog(() => selectedOption = val);
                            }
                          },
                        ),
                        const Text("Offer Item"),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (selectedOption == "MONEY")
                      TextField(
                        controller: moneyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Enter your offer amount",
                          prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _submitTradeRequest(
                              tradeType: selectedOption,
                              moneyOffer:
                              (selectedOption == "MONEY") ? moneyCtrl.text.trim() : null,
                            );
                          },
                          child: const Text("Send", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitTradeRequest({
    required String tradeType,
    String? moneyOffer,
  }) async {
    double money = 0.0;
    if (tradeType == "MONEY" && moneyOffer != null && moneyOffer.isNotEmpty) {
      money = double.tryParse(moneyOffer) ?? 0.0;
    }

    final body = {
      "itemId": widget.itemId, // The item we're looking at
      "tradeType": tradeType,  // "MONEY" or "ITEM"
      "moneyOffer": money,
    };

    try {
      final resp = await http.post(
        Uri.parse("$BASE_URL/api/trade/requests"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Trade request sent successfully!")),
        );
      } else {
        final err = jsonDecode(resp.body)["message"] ?? "Request failed";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}
