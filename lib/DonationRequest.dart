import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DonationRequestPage extends StatefulWidget {
  final String token;
  const DonationRequestPage({Key? key, required this.token}) : super(key: key);

  @override
  State<DonationRequestPage> createState() => _DonationRequestPageState();
}

class _DonationRequestPageState extends State<DonationRequestPage>
    with TickerProviderStateMixin {
  late TabController _outerTabCtrl;
  late TabController _innerTabCtrl;
  bool _loading = true;
  List<dynamic> _incoming = [];
  List<dynamic> _sent = [];

  static const String BASE = "http://10.0.2.2:8080";

  @override
  void initState() {
    super.initState();
    _outerTabCtrl = TabController(length: 2, vsync: this);
    _innerTabCtrl = TabController(length: 3, vsync: this);
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => _loading = true);
    try {
      final inResp = await http.get(
        Uri.parse("$BASE/api/donation-requests/incoming"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      final sentResp = await http.get(
        Uri.parse("$BASE/api/donation-requests/sent"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      if (inResp.statusCode == 200 && sentResp.statusCode == 200) {
        _incoming = jsonDecode(inResp.body);
        _sent     = jsonDecode(sentResp.body);
      }
    } catch (_) {
      // handle errors…
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _respond(String id, bool accept) async {
    final path = accept ? "accept" : "reject";
    await http.post(
      Uri.parse("$BASE/api/donation-requests/$id/$path"),
      headers: {"Authorization": "Bearer ${widget.token}"},
    );
    _fetchAll();
  }

  List<dynamic> _filter(List<dynamic> list, String status) =>
      list.where((r) => r["status"] == status).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB3D1B9),
      appBar: AppBar(
        title: const Text("Donation Requests"),
        bottom: TabBar(
          controller: _outerTabCtrl,
          tabs: const [
            Tab(text: "Incoming"),
            Tab(text: "Sent"),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _outerTabCtrl,
        children: [
          _buildSection(_incoming, isIncoming: true),
          _buildSection(_sent, isIncoming: false),
        ],
      ),
    );
  }

  Widget _buildSection(List<dynamic> all, {required bool isIncoming}) {
    return Column(
      children: [
        Container(
          color: Colors.grey.shade200,
          child: TabBar(
            controller: _innerTabCtrl,
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.teal,
            tabs: const [
              Tab(text: "Pending"),
              Tab(text: "Accepted"),
              Tab(text: "Rejected"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _innerTabCtrl,
            children: [
              _buildList(_filter(all, "PENDING"), isIncoming),
              _buildList(_filter(all, "ACCEPTED"), isIncoming),
              _buildList(_filter(all, "REJECTED"), isIncoming),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildList(List<dynamic> items, bool isIncoming) {
    if (items.isEmpty) {
      return const Center(child: Text("No items here."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildCard(items[i], isIncoming),
    );
  }

  Widget _buildCard(dynamic r, bool isIncoming) {
    // common fields
    final title = isIncoming
        ? r["donationTitle"]
        : r["donationTitle"];
    final imgList = r["donationImages"] as List<dynamic>? ?? [];
    final img = imgList.isNotEmpty ? imgList.first : null;
    final status = r["status"];
    final msg = r["message"];
    final reqId = r["requestId"];

    // person info
    final name  = isIncoming
        ? r["requesterFullName"]
        : r["receiverFullName"];
    final email = isIncoming
        ? r["requesterEmail"]
        : r["receiverEmail"];
    final phone = isIncoming
        ? r["requesterPhone"]
        : r["receiverPhone"];
    final prof  = isIncoming
        ? r["requesterProfile"]
        : r["receiverProfile"];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Donation row
          Row(children: [
            if (img != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(img,
                    width: 60, height: 60, fit: BoxFit.cover),
              ),
            const SizedBox(width: 12),
            Expanded(
              child:
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: status == "PENDING"
                    ? Colors.orange
                    : status == "ACCEPTED"
                    ? Colors.green
                    : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(status, style: const TextStyle(color: Colors.white)),
            )
          ]),
          const SizedBox(height: 8),
          Text("Message: $msg"),
          const SizedBox(height: 8),
          // Person row
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 24,
              backgroundImage: prof.isNotEmpty
                  ? NetworkImage(prof)
                  : null,
              child:
              prof.isEmpty ? const Icon(Icons.person) : null,
            ),
            title: Text(name),
            subtitle: Text("$email\n$phone"),
          ),
          if (isIncoming && status == "PENDING")
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                onPressed: () => _respond(reqId, false),
                child: const Text("Reject",
                    style: TextStyle(color: Colors.red)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => _respond(reqId, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green),
                child: const Text("Accept"),
              ),
            ]),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _outerTabCtrl.dispose();
    _innerTabCtrl.dispose();
    super.dispose();
  }
}
