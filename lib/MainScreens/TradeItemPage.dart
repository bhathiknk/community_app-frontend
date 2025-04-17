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
  static const BASE_URL = "http://10.0.2.2:8080";

  bool _isLoading = false;
  List<dynamic> _allItems = [];

  // Filters
  List<dynamic> _categories = [];
  int? _selectedCategoryId;
  final TextEditingController _searchCtrl = TextEditingController();

  // ✨ subtle list fade‑in
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fetchCategories();
    _fetchAllActiveTradeItems();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
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
        setState(() => _categories = jsonDecode(resp.body));
      }
    } catch (_) {}
  }

  Future<void> _fetchAllActiveTradeItems({
    String? search,
    int? categoryId,
  }) async {
    setState(() => _isLoading = true);

    // build query
    String url = "$BASE_URL/api/trade";
    final params = <String>[];
    if (search != null && search.isNotEmpty) params.add("search=$search");
    if (categoryId != null) params.add("categoryId=$categoryId");
    if (params.isNotEmpty) url += "?${params.join("&")}";

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
        _allItems = jsonDecode(resp.body);
        // restart the list fade‑in every time new data arrives
        _animCtrl.forward(from: 0);
      } else {
        final msg =
            jsonDecode(resp.body)["message"] ?? "Failed to fetch items";
        _snack(msg);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _snack("Error: $e");
    }
  }

  // ================= HELPERS =================
  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ================= FILTER UI =================
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
          child: ListView(
            controller: scrollCtrl,
            children: [
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
              const SizedBox(height: 18),
              const Text(
                "Filters",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),

              // 🔍 Search
              TextField(
                controller: _searchCtrl,
                decoration: _inputDecoration("Search by title", Icons.search),
              ),
              const SizedBox(height: 18),

              // 🏷️ Category chips
              Wrap(
                spacing: 8,
                children: [
                  _categoryChip(null, "All"),
                  ..._categories.map((c) =>
                      _categoryChip(c["categoryId"], c["categoryName"])),
                ],
              ),
              const SizedBox(height: 32),

              // Apply
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _fetchAllActiveTradeItems(
                    search: _searchCtrl.text.trim(),
                    categoryId: _selectedCategoryId,
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text("Apply Filters"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.green.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) =>
      InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );

  Widget _categoryChip(int? id, String text) {
    final selected = id == _selectedCategoryId;
    return ChoiceChip(
      label: Text(text),
      selected: selected,
      onSelected: (_) => setState(() => _selectedCategoryId = id),
      selectedColor: Colors.teal.shade600,
      backgroundColor: Colors.grey.shade200,
      labelStyle:
      TextStyle(color: selected ? Colors.white : Colors.grey.shade800),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Marketplace",
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black87),
            onPressed: _showFilterSheet,
            tooltip: "Filters",
          ),
        ],
      ),
      body: _isLoading
          ? const _PageLoader()
          : _allItems.isEmpty
          ? const Center(child: Text("No items found"))
          : FadeTransition(
        opacity: _animCtrl.drive(
          CurveTween(curve: Curves.easeIn),
        ),
        child: RefreshIndicator(
          onRefresh: () => _fetchAllActiveTradeItems(
              search: _searchCtrl.text.trim(),
              categoryId: _selectedCategoryId),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _allItems.length,
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
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
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.only(bottom: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // 📸 Images
            AspectRatio(
              aspectRatio: 16 / 9,
              child: images.isEmpty
                  ? Container(
                color: Colors.grey.shade200,
                child: const Center(child: Text("No images")),
              )
                  : CarouselSlider(
                items: images
                    .map((u) => Image.network(
                  u,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) =>
                  const Center(child: Icon(Icons.broken_image)),
                ))
                    .toList(),
                options: CarouselOptions(
                  viewportFraction: 1,
                  enlargeCenterPage: false,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 4),
                ),
              ),
            ),
            // 📑 Info
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: ownerImg != null && ownerImg.isNotEmpty
                        ? NetworkImage(ownerImg)
                        : const AssetImage("images/default_profile.png")
                    as ImageProvider,
                    radius: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Rs. $price",
                      style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold),
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

/// Simple fading dots loader
class _PageLoader extends StatelessWidget {
  const _PageLoader();
  @override
  Widget build(BuildContext context) => Center(
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 6),
      duration: const Duration(seconds: 2),
      builder: (_, val, __) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
              (i) => Padding(
            padding: const EdgeInsets.all(4),
            child: Opacity(
              opacity: (val.toInt() % 3) == i ? 1 : .3,
              child: const CircleAvatar(radius: 6, backgroundColor: Colors.teal),
            ),
          ),
        ),
      ),
      onEnd: () {},
    ),
  );
}
