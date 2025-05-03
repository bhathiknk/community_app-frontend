import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'donation_complete_page.dart';

class DonationRequestPage extends StatefulWidget {
  final String token;
  final String? initialRequestId;
  final bool initialIsIncoming;

  const DonationRequestPage({
    Key? key,
    required this.token,
    this.initialRequestId,
    this.initialIsIncoming = false,
  }) : super(key: key);

  @override
  State<DonationRequestPage> createState() => _DonationRequestPageState();
}

class _DonationRequestPageState extends State<DonationRequestPage> {
  int _outerIndex = 0; // 0 = Incoming, 1 = Sent
  int _innerIndex = 0; // 0 = Pending, 1 = Accepted, 2 = Rejected
  bool _loading = true;

  List<dynamic> _incoming = [];
  List<dynamic> _sent = [];

  static const String _base = "http://10.0.2.2:8080";

  @override
  void initState() {
    super.initState();
    _fetchAll().then((_) {
      if (widget.initialRequestId != null) {
        _openInitialRequest();
      }
    });
  }

  Future<void> _fetchAll() async {
    setState(() => _loading = true);
    try {
      final inResp = await http.get(
        Uri.parse("$_base/api/donation-requests/incoming"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      final sentResp = await http.get(
        Uri.parse("$_base/api/donation-requests/sent"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      if (inResp.statusCode == 200) _incoming = jsonDecode(inResp.body);
      if (sentResp.statusCode == 200) _sent = jsonDecode(sentResp.body);
    } catch (_) {
      // ignore errors
    } finally {
      setState(() => _loading = false);
    }
  }

  void _openInitialRequest() {
    // choose the right list based on sender/receiver
    final list = widget.initialIsIncoming ? _incoming : _sent;
    final req = list.firstWhere(
          (r) => r["requestId"] == widget.initialRequestId,
      orElse: () => null,
    );
    if (req != null) {
      final status = (req["status"] as String).toUpperCase();
      int idx;
      switch (status) {
        case "ACCEPTED":
          idx = 1;
          break;
        case "REJECTED":
          idx = 2;
          break;
        default:
          idx = 0;
      }
      setState(() {
        _outerIndex = widget.initialIsIncoming ? 0 : 1;
        _innerIndex = idx;
      });
    }
  }

  Future<void> _respond(String id, bool accept) async {
    final action = accept ? "accept" : "reject";
    await http.post(
      Uri.parse("$_base/api/donation-requests/$id/$action"),
      headers: {"Authorization": "Bearer ${widget.token}"},
    );
    _fetchAll();
  }

  Future<void> _complete(String id) async {
    final resp = await http.post(
      Uri.parse("$_base/api/donation-requests/$id/complete"),
      headers: {"Authorization": "Bearer ${widget.token}"},
    );
    if (resp.statusCode == 200) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DonationCompletePage(
            token: widget.token,
            requestId: id,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Complete failed")));
    }
  }

  List<dynamic> _filter(List<dynamic> all, String status) =>
      all.where((r) => r["status"] == status).toList();

  Color _statusColor(String status) {
    switch (status) {
      case "ACCEPTED":
        return Colors.green.shade600;
      case "REJECTED":
        return Colors.red.shade600;
      default:
        return Colors.orange.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Colors.teal.shade600;
    final secondary = Colors.teal.shade900;

    return Scaffold(
      backgroundColor: const Color(0xFFB3D1B9),
      appBar: AppBar(
        title: const Text("Donation Requests"),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          _buildOuterSelector(primary),
          const SizedBox(height: 12),
          _buildInnerSelector(secondary),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOuterSelector(Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PhysicalModel(
        color: Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(30),
        child: Row(
          children: ["Incoming", "Sent"].asMap().entries.map((entry) {
            final idx = entry.key;
            final selected = idx == _outerIndex;
            return Expanded(
              child: InkWell(
                onTap: () => setState(() {
                  _outerIndex = idx;
                  _innerIndex = 0;
                }),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        color: selected ? Colors.white : primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInnerSelector(Color secondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: PhysicalModel(
        color: Colors.white,
        elevation: 1,
        borderRadius: BorderRadius.circular(30),
        child: Row(
          children: ["Pending", "Accepted", "Rejected"]
              .asMap()
              .entries
              .map((entry) {
            final idx = entry.key;
            final selected = idx == _innerIndex;
            return Expanded(
              child: InkWell(
                onTap: () => setState(() => _innerIndex = idx),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? secondary : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        color: selected ? Colors.white : secondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildList() {
    final data = _outerIndex == 0 ? _incoming : _sent;
    final status = ["PENDING", "ACCEPTED", "REJECTED"][_innerIndex];
    final items = _filter(data, status);

    if (items.isEmpty) {
      return Center(
        child: Text(
          "No ${status.toLowerCase()} requests",
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildCard(items[i]),
    );
  }

  Widget _buildCard(dynamic r) {
    final incoming = _outerIndex == 0;
    final title = r["donationTitle"] as String? ?? "";
    final imgs = (r["donationImages"] as List? ?? []).cast<String>();
    final img = imgs.isNotEmpty ? imgs.first : null;
    final status = r["status"] as String;
    final msg = r["message"] as String? ?? "";
    final id = r["requestId"] as String;

    final name =
    incoming ? r["requesterFullName"] : r["receiverFullName"];
    final email =
    incoming ? r["requesterEmail"] : r["receiverEmail"];
    final phone =
    incoming ? r["requesterPhone"] : r["receiverPhone"];
    final prof =
    incoming ? r["requesterProfile"] : r["receiverProfile"];

    final statusColor = _statusColor(status);

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Row(
        children: [
          Container(width: 6, height: 140, color: statusColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(children: [
                    if (img != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(img,
                            width: 60, height: 60, fit: BoxFit.cover),
                      ),
                    if (img != null) const SizedBox(width: 12),
                    Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(status,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Message: $msg",
                        style: TextStyle(color: Colors.grey.shade700)),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundImage:
                      prof.isNotEmpty ? NetworkImage(prof) : null,
                      child: prof.isEmpty
                          ? const Icon(Icons.person_outline)
                          : null,
                    ),
                    title: Text(name,
                        style:
                        const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text("$email\n$phone",
                        style: const TextStyle(fontSize: 12)),
                  ),
                  if (incoming && status == "PENDING")
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _respond(id, false),
                          child: const Text("Reject"),
                          style: TextButton.styleFrom(
                              foregroundColor:
                              Colors.red.shade700),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => _respond(id, true),
                          child: const Text("Accept"),
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                              Colors.teal.shade600),
                        ),
                      ],
                    ),
                  if (!incoming && status == "ACCEPTED")
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () => _complete(id),
                        child:
                        const Text("🎉 Donation Complete"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade900,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
