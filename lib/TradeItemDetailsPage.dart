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
  static const _baseUrl = 'http://10.0.2.2:8080';
  bool _isLoading = false;
  String _error = '';
  Map<String, dynamic>? _item;

  @override
  void initState() {
    super.initState();
    _fetchItem();
  }

  Future<void> _fetchItem() async {
    setState(() => _isLoading = true);
    try {
      final resp = await http.get(
        Uri.parse('$_baseUrl/api/trade/details/${widget.itemId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (resp.statusCode == 200) {
        _item = jsonDecode(resp.body);
      } else {
        _error = 'Failed to load item';
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Colors.teal.shade600;

    return Scaffold(
      backgroundColor: const Color(0xFFB3D1B9),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
          : _item == null
          ? const Center(child: Text('No data'))
          : CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            iconTheme: IconThemeData(color: primary),
            titleTextStyle: TextStyle(color: primary, fontSize: 20, fontWeight: FontWeight.bold),
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _item!['title'] ?? 'Details',
                style: const TextStyle(shadows: [Shadow(blurRadius: 4, color: Colors.black45)]),
              ),
              background: _buildCarousel(_item!['images'] as List<dynamic>? ?? []),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _sectionCard(
                  'Item Information',
                  primary,
                  [
                    Icons.label_important, 'Title', _item!['title'],
                    Icons.description,      'Description', _item!['description'],
                    Icons.attach_money,     'Price', '\Rs.${_item!['price']}',
                    Icons.info_outline,     'Status', _item!['status'],
                    Icons.calendar_today,   'Posted On', _item!['createdAt'],
                  ],
                ),
                _sectionCard(
                  'Seller Contact',
                  primary,
                  [
                    Icons.person,        'Name', _item!['ownerFullName'],
                    Icons.email,         'Email', _item!['ownerEmail'],
                    Icons.phone,         'Phone', _item!['ownerPhone'],
                    Icons.home,          'Address', _item!['ownerAddress'],
                    Icons.location_city, 'City', _item!['ownerCity'],
                  ],
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showTradeDialog,
            icon: const Icon(Icons.send, color: Colors.white),
            label: const Text('Send Trade Request', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCarousel(List<dynamic> imgs) {
    if (imgs.isEmpty) {
      return Container(color: Colors.grey[300]);
    }
    return CarouselSlider.builder(
      itemCount: imgs.length,
      itemBuilder: (ctx, idx, _) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: Colors.grey[200],
          child: Image.network(
            imgs[idx],
            fit: BoxFit.contain,
            width: double.infinity,
            errorBuilder: (_, __, ___) => const Center(child: Text('Image error')),
          ),
        ),
      ),
      options: CarouselOptions(
        height: 280,
        viewportFraction: 1.0,
        enableInfiniteScroll: false,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 3),
      ),
    );
  }

  Widget _sectionCard(String title, Color color, List<dynamic> data) {
    // data: [icon, label, value, icon, label, value, ...]
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.09),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ),
          for (var i = 0; i < data.length; i += 3)
            ListTile(
              leading: Icon(data[i] as IconData, color: color),
              title: Text(data[i + 1] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text((data[i + 2] ?? '').toString()),
            ),
        ],
      ),
    );
  }

  void _showTradeDialog() {
    final primary = Colors.teal.shade600;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        String selected = 'MONEY';
        final ctrl = TextEditingController();
        return StatefulBuilder(
          builder: (ctx, setState) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Send Trade Request',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ToggleButtons(
                  isSelected: [selected == 'MONEY', selected == 'ITEM'],
                  borderRadius: BorderRadius.circular(8),
                  selectedColor: Colors.white,
                  fillColor: primary,
                  onPressed: (i) => setState(() => selected = i == 0 ? 'MONEY' : 'ITEM'),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text('Offer Money'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text('Offer Item'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (selected == 'MONEY')
                  TextField(
                    controller: ctrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _submitTrade(type: selected, money: ctrl.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Send', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitTrade({required String type, String? money}) async {
    final offer = type == 'MONEY' ? double.tryParse(money ?? '') ?? 0.0 : 0.0;
    final body = jsonEncode({
      'itemId': widget.itemId,
      'tradeType': type,
      'moneyOffer': offer,
    });
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/trade/requests'),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
        body: body,
      );
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trade request sent!'), backgroundColor: Colors.green),
        );
      } else {
        final err = jsonDecode(resp.body)['message'] ?? 'Failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
