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

class _TradeItemPageState extends State<TradeItemPage>
    with SingleTickerProviderStateMixin {
  static const _baseUrl = "http://10.0.2.2:8080";

  bool _isLoading = false;
  List<dynamic> _allItems = [];
  List<dynamic> _categories = [];
  int? _selectedCategoryId;
  final TextEditingController _searchCtrl = TextEditingController();
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _fetchCategories();
    _fetchAllActiveTradeItems();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final resp = await http.get(
        Uri.parse("$_baseUrl/api/categories"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      if (resp.statusCode == 200) {
        setState(() => _categories = jsonDecode(resp.body));
      }
    } catch (_) {}
  }

  Future<void> _fetchAllActiveTradeItems({String? search, int? categoryId}) async {
    setState(() => _isLoading = true);
    var url = "$_baseUrl/api/trade";
    final params = <String>[];
    if ((search ?? "").isNotEmpty) params.add("search=${search!.trim()}");
    if (categoryId != null) params.add("categoryId=$categoryId");
    if (params.isNotEmpty) url += "?${params.join("&")}";

    try {
      final resp = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      if (resp.statusCode == 200) {
        _allItems = jsonDecode(resp.body);
        _animCtrl.forward(from: 0);
      } else {
        final msg = jsonDecode(resp.body)["message"] ?? "Failed to load";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (ctx, ctl) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(20, 24, 20, 30),
          child: ListView(controller: ctl, children: [
            // drag handle
            Center(
              child: Container(
                height: 5,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            SizedBox(height: 18),
            Text(
              "Filters",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.teal.shade600,
              ),
            ),
            SizedBox(height: 20),

            // Search field
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: "Search by title",
                prefixIcon: Icon(Icons.search, color: Colors.teal.shade600),
                filled: true,
                fillColor: Colors.teal.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 18),

            // Category dropdown
            DropdownButtonFormField<int?>(
              value: _selectedCategoryId,
              decoration: InputDecoration(
                labelText: "Category",
                labelStyle: TextStyle(color: Colors.teal.shade600),
                prefixIcon: Icon(Icons.category, color: Colors.teal.shade600),
                filled: true,
                fillColor: Colors.teal.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.teal.shade600),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.teal.shade600),
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text("All", style: TextStyle(color: Colors.black87)),
                ),
                ..._categories.map((c) {
                  return DropdownMenuItem(
                    value: c["categoryId"] as int,
                    child: Text(c["categoryName"], style: TextStyle(color: Colors.black87)),
                  );
                }).toList(),
              ],
              onChanged: (val) => setState(() => _selectedCategoryId = val),
            ),
            SizedBox(height: 32),

            // Apply button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _fetchAllActiveTradeItems(
                  search: _searchCtrl.text,
                  categoryId: _selectedCategoryId,
                );
              },
              icon: Icon(Icons.check, color: Colors.white),
              label: Text("Apply Filters", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                minimumSize: Size.fromHeight(50),
                backgroundColor: Colors.teal.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade700,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          "Trade Items",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.teal.shade600),
            tooltip: "Filters",
            onPressed: _showFilterSheet,
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.teal.shade600))
          : _allItems.isEmpty
          ? Center(
          child: Text("No items found", style: TextStyle(color: Colors.grey)))
          : FadeTransition(
        opacity: _animCtrl.drive(CurveTween(curve: Curves.easeIn)),
        child: RefreshIndicator(
          color: Colors.teal.shade600,
          onRefresh: () => _fetchAllActiveTradeItems(
            search: _searchCtrl.text,
            categoryId: _selectedCategoryId,
          ),
          child: ListView.builder(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            itemCount: _allItems.length,
            itemBuilder: (_, i) => _itemCard(_allItems[i]),
          ),
        ),
      ),
      bottomNavigationBar:
      BottomNavBar(selectedIndex: 1, token: widget.token),
    );
  }

  Widget _itemCard(dynamic item) {
    final title = item["title"] ?? "Untitled";
    final price = item["price"]?.toString() ?? "0";
    final images = (item["images"] as List?)?.cast<String>() ?? [];
    final ownerImg = item["ownerProfileImage"] as String?;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              TradeItemDetailsPage(token: widget.token, itemId: item["itemId"]),
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB3D1B9), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ⇨ SLIDESHOW CAROUSEL
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              child: Container(
                height: 200,
                color: Colors.grey.shade200,
                child: images.isNotEmpty
                    ? CarouselSlider.builder(
                  itemCount: images.length,
                  itemBuilder: (ctx, idx, _) => Image.network(
                    images[idx],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Center(
                        child: Icon(Icons.broken_image,
                            size: 60, color: Colors.grey.shade400)),
                  ),
                  options: CarouselOptions(
                    viewportFraction: 1.0,
                    autoPlay: true,
                    autoPlayInterval: Duration(seconds: 4),
                    enlargeCenterPage: false,
                  ),
                )
                    : Center(
                  child: Icon(Icons.broken_image,
                      size: 60, color: Colors.grey.shade400),
                ),
              ),
            ),

            // Title, avatar, price pill
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: ownerImg != null && ownerImg.isNotEmpty
                        ? NetworkImage(ownerImg)
                        : AssetImage("images/default_profile.png")
                    as ImageProvider,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "₹ $price",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
