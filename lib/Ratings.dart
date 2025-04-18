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
        backgroundColor: Colors.teal.shade50,
        appBar: AppBar(
          title: const Text('My Ratings', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.teal,
          elevation: 4,
          bottom: const TabBar(
            labelColor: Colors.white,
            indicatorColor: Colors.amber,
            tabs: [
              Tab(icon: Icon(Icons.inbox), text: 'Received'),
              Tab(icon: Icon(Icons.send), text: 'Sent'),
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

  Widget _buildTab(bool loading, List<dynamic> items, {required bool isReceived}) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }
    if (items.isEmpty) {
      return Center(
        child: Text(
          isReceived ? 'No received ratings yet' : 'No sent ratings yet',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (_, i) {
        final r = items[i];
        final imageField = isReceived ? r['raterProfileImage'] : r['rateeProfileImage'];
        final nameField = isReceived ? r['raterFullName'] : r['rateeFullName'];

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              radius: 26,
              backgroundImage: (imageField != null && imageField.isNotEmpty)
                  ? NetworkImage(imageField)
                  : null,
              child: (imageField == null || imageField.isEmpty)
                  ? const Icon(Icons.person_outline, size: 26)
                  : null,
            ),
            title: Text(
              nameField ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  'Item: ${r['donationTitle'] ?? ''}',
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(5, (j) {
                    return j < (r['score'] as int)
                        ? const Icon(Icons.star, size: 18, color: Colors.amber)
                        : const Icon(Icons.star_border, size: 18, color: Colors.amber);
                  }),
                ),
                const SizedBox(height: 6),
                Text(
                  r['comment'] ?? '',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
            trailing: (r['donationImage'] != null && r['donationImage'].isNotEmpty)
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                r['donationImage'],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            )
                : null,
          ),
        );
      },
    );
  }
}
