import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;

import '../TradeItemDetailsPage.dart';
import '../bottom_nav_bar.dart';

class TradeItemPage extends StatefulWidget {
  final String token;
  const TradeItemPage({Key? key, required this.token}) : super(key: key);

  @override
  State<TradeItemPage> createState() => _TradeItemPageState();
}

class _TradeItemPageState extends State<TradeItemPage> {
  static const BASE_URL = "http://10.0.2.2:8080";

  bool _isLoading = false;
  List<dynamic> _allItems = [];

  // For filter use
  List<dynamic> _categories = [];
  int? _selectedCategoryId;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCategories(); // fetch categories for filter usage
    _fetchAllActiveTradeItems();
  }

  // ================= BACKEND CALLS =================

  Future<void> _fetchCategories() async {
    try {
      final resp = await http.get(
        Uri.parse("$BASE_URL/api/categories"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          _categories = data;
        });
      }
    } catch (e) {
      // handle error if needed
    }
  }

  Future<void> _fetchAllActiveTradeItems({String? search, int? categoryId}) async {
    setState(() => _isLoading = true);

    // build query string e.g. /api/trade?search=xxx&categoryId=yyy
    String url = "$BASE_URL/api/trade";
    List<String> params = [];
    if (search != null && search.isNotEmpty) {
      params.add("search=$search");
    }
    if (categoryId != null) {
      params.add("categoryId=$categoryId");
    }

    if (params.isNotEmpty) {
      url += "?${params.join("&")}";
    }

    try {
      final resp = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );

      setState(() => _isLoading = false);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        setState(() {
          _allItems = data;
        });
      } else {
        final msg = jsonDecode(resp.body)["message"] ?? "Failed to fetch items";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // ================= FILTER UI (BOTTOM SHEET) =================

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Filter Items",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search Input
                    TextFormField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        labelText: "Search by Title",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Filter
                    DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: "Category",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text("All Categories"),
                        ),
                        ..._categories.map((cat) {
                          return DropdownMenuItem<int>(
                            value: cat["categoryId"],
                            child: Text(cat["categoryName"]),
                          );
                        }).toList()
                      ].cast<DropdownMenuItem<int>>(),
                      onChanged: (val) {
                        setState(() => _selectedCategoryId = val);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Apply Button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // close bottom sheet
                        _fetchAllActiveTradeItems(
                          search: _searchCtrl.text.trim(),
                          categoryId: _selectedCategoryId,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "Apply",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB3D1B9),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Trade Items"),
        backgroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _showFilterSheet,
            icon: const Icon(Icons.filter_list, color: Colors.black),
            label: const Text(
              "Filter Items",
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allItems.isEmpty
          ? const Center(child: Text("No items found."))
          : ListView.builder(
        itemCount: _allItems.length,
        itemBuilder: (ctx, i) {
          final item = _allItems[i];
          final title = item["title"] ?? "No Title";
          final price = item["price"]?.toString() ?? "0";
          final status = item["status"] ?? "Unknown";
          final images = item["images"] as List<dynamic>?;

          // Wrap the card in a GestureDetector so we can navigate to details
          return GestureDetector(
            onTap: () {
              // Navigate to a detail page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TradeItemDetailsPage(
                    token: widget.token,
                    itemId: item["itemId"],
                  ),
                ),
              );
            },
            child: Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image slider
                    if (images != null && images.isNotEmpty)
                      CarouselSlider(
                        items: images.map((imgUrl) {
                          return Builder(
                            builder: (context) {
                              return Container(
                                margin: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[200],
                                ),
                                child: Image.network(
                                  imgUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, error, stack) {
                                    return const Center(
                                      child: Text("Image load error"),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        }).toList(),
                        options: CarouselOptions(
                          height: 200,
                          autoPlay: true,
                          enlargeCenterPage: true,
                          enableInfiniteScroll: false,
                          aspectRatio: 16 / 9,
                          autoPlayInterval: const Duration(seconds: 3),
                          autoPlayAnimationDuration:
                          const Duration(milliseconds: 800),
                          viewportFraction: 0.8,
                        ),
                      )
                    else
                      Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Text("No images"),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Price
                    Text("Price: \$$price"),
                    const SizedBox(height: 6),

                    // Status
                    Text("Status: $status"),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: 1, token: widget.token),
    );
  }
}
