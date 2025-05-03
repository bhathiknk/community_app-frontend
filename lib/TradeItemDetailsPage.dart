import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;

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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: primary),
        title: Text(
          _item?['title'] ?? 'Item Details',
          style: TextStyle(color: primary),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
          : _item == null
          ? const Center(child: Text('No data'))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── IMAGE CAROUSEL ───────────────────────────
            if ((_item!['images'] as List).isNotEmpty)
              CarouselSlider(
                items: (_item!['images'] as List).map((url) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  );
                }).toList(),
                options: CarouselOptions(
                  height: 240,
                  viewportFraction: 1.0,
                  autoPlay: true,
                ),
              )
            else
              Container(
                height: 240,
                color: Colors.grey[300],
                child: const Center(child: Icon(Icons.broken_image, size: 60)),
              ),
            const SizedBox(height: 16),

            // ─── ITEM DETAILS CARD ───────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Item Information',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primary)),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _infoRow(Icons.label_important, 'Title',
                          _item!['title']),

                      // Expanded, multiline description:
                      const SizedBox(height: 12),
                      Text('Description:',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: primary)),
                      const SizedBox(height: 6),
                      Text(
                        _item!['description'] ?? '-',
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.left,
                      ),

                      const SizedBox(height: 16),
                      _infoRow(Icons.attach_money, 'Price',
                          'Rs.${_item!['price']}'),
                      _infoRow(Icons.info_outline, 'Status',
                          _item!['status']),
                      _infoRow(Icons.calendar_today, 'Posted On',
                          _item!['createdAt']),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ─── SELLER INFO CARD ─────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Seller Information',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primary)),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundImage: (_item!['ownerProfileImage']
                            as String?)?.isNotEmpty ==
                                true
                                ? NetworkImage(
                                _item!['ownerProfileImage'])
                                : const AssetImage(
                                'images/default_profile.png')
                            as ImageProvider,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(_item!['ownerFullName'],
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                        FontWeight.bold)),
                                const SizedBox(height: 4),
                                _starRating(
                                  (_item!['ownerAvgRating']
                                  as num?)
                                      ?.toDouble() ??
                                      0.0,
                                  (_item!['ownerReviewCount']
                                  as int?) ??
                                      0,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      _infoRow(Icons.email, 'Email',
                          _item!['ownerEmail']),
                      _infoRow(Icons.phone, 'Phone',
                          _item!['ownerPhone']),
                      _infoRow(Icons.home, 'Address',
                          _item!['ownerAddress']),
                      _infoRow(Icons.location_city, 'City',
                          _item!['ownerCity']),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showTradeDialog,
            icon: const Icon(Icons.send, color: Colors.white),
            label:
            const Text('Send Trade Request', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.teal.shade50,
            child: Icon(icon, size: 18, color: Colors.teal.shade600),
          ),
          const SizedBox(width: 12),
          Text('$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(child: Text(value ?? '-', style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _starRating(double avg, int count) {
    int full = avg.floor();
    bool half = (avg - full) >= 0.5;
    return Row(
      children: [
        ...List.generate(5, (i) {
          if (i < full) return const Icon(Icons.star, size: 18, color: Colors.amber);
          if (i == full && half) return const Icon(Icons.star_half, size: 18, color: Colors.amber);
          return const Icon(Icons.star_border, size: 18, color: Colors.amber);
        }),
        const SizedBox(width: 4),
        Text('(${count})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  void _showTradeDialog() {
    final primary = Colors.teal.shade600;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape:
      const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        String selected = 'MONEY';
        final ctrl = TextEditingController();
        return StatefulBuilder(
          builder: (ctx, setState) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2))),
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
                  Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text('Offer Money')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text('Offer Item')),
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
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
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
              ]),
            ]),
          ),
        );
      },
    );
  }

  Future<void> _submitTrade({required String type, String? money}) async {
    final offer = type == 'MONEY' ? double.tryParse(money ?? '') ?? 0.0 : 0.0;
    final body = jsonEncode({'itemId': widget.itemId, 'tradeType': type, 'moneyOffer': offer});
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }
}
