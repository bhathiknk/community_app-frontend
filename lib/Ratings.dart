// lib/pages/RatingsPage.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RatingsPage extends StatefulWidget {
  final String token;
  const RatingsPage({Key? key, required this.token}) : super(key: key);

  @override
  State<RatingsPage> createState() => _RatingsPageState();
}

class _RatingsPageState extends State<RatingsPage> {
  final _base = 'http://10.0.2.2:8080';
  List<dynamic> _received = [];
  List<dynamic> _sent = [];
  bool _loadingReceived = true;
  bool _loadingSent = true;

  @override
  void initState() {
    super.initState();
    _loadReceived();
    _loadSent();
  }

  Future<void> _loadReceived() async {
    final resp = await http.get(
      Uri.parse('$_base/api/ratings/me/received'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (resp.statusCode == 200) {
      setState(() {
        _received = jsonDecode(resp.body);
      });
    }
    setState(() => _loadingReceived = false);
  }

  Future<void> _loadSent() async {
    final resp = await http.get(
      Uri.parse('$_base/api/ratings/me/detailed'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (resp.statusCode == 200) {
      setState(() {
        _sent = jsonDecode(resp.body);
      });
    }
    setState(() => _loadingSent = false);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Ratings'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Received'),
              Tab(text: 'Sent'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTab(_loadingReceived, _received, isReceived: true),
            _buildTab(_loadingSent, _sent, isReceived: false),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(bool loading, List<dynamic> items,
      {required bool isReceived}) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return Center(
        child: Text(isReceived
            ? 'No received ratings yet'
            : 'No sent ratings yet'),
      );
    }
    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (_, i) {
        final r = items[i];
        final imageField = isReceived
            ? r['raterProfileImage']
            : r['rateeProfileImage'];
        final nameField = isReceived
            ? r['raterFullName']
            : r['rateeFullName'];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: (imageField != null && imageField.isNotEmpty)
                  ? NetworkImage(imageField)
                  : null,
              child: (imageField == null || imageField.isEmpty)
                  ? const Icon(Icons.person_outline)
                  : null,
            ),
            title: Text(nameField ?? ''),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Item: ${r['donationTitle'] ?? ''}'),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(5, (j) {
                    return j < (r['score'] as int)
                        ? const Icon(Icons.star, size: 16, color: Colors.amber)
                        : const Icon(Icons.star_border,
                        size: 16, color: Colors.amber);
                  }),
                ),
                const SizedBox(height: 4),
                Text(r['comment'] ?? ''),
              ],
            ),
            isThreeLine: true,
            trailing: (r['donationImage'] != null &&
                r['donationImage'].isNotEmpty)
                ? Image.network(
              r['donationImage'],
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            )
                : null,
          ),
        );
      },
    );
  }
}
