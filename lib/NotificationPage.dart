import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'DonationRequest.dart';
import 'TradeItemRequestPage.dart';

class NotificationPage extends StatefulWidget {
  final String token;
  const NotificationPage({Key? key, required this.token}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  static const String BASE_URL = "http://10.0.2.2:8080";

  bool _isLoading = false;
  List<dynamic> _notes = [];

  // We fetch these to build friendly donation messages:
  List<dynamic> _donationIncoming = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await Future.wait([_fetchNotes(), _fetchDonationIncoming()]);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchNotes() async {
    try {
      final resp = await http.get(
        Uri.parse("$BASE_URL/api/notifications/me/detailed"),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (resp.statusCode == 200) {
        _notes = jsonDecode(resp.body);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load notifications')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading notifications: $e')),
      );
    }
  }

  Future<void> _fetchDonationIncoming() async {
    try {
      final resp = await http.get(
        Uri.parse("$BASE_URL/api/donation-requests/incoming"),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (resp.statusCode == 200) {
        _donationIncoming = jsonDecode(resp.body);
      }
    } catch (_) {
      // no‐op
    }
  }

  Future<void> _markRead(String id, bool read) async {
    await http.put(
      Uri.parse("$BASE_URL/api/notifications/$id/read?read=$read"),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    await _fetchNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB3D1B9),
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
          ? const Center(
          child: Text("No notifications", style: TextStyle(color: Colors.black54)))
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _notes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final n = _notes[i];
          final read = n['read'] as bool? ?? false;
          final type = (n['referenceType'] as String? ?? 'UNKNOWN').toUpperCase();
          final refId = n['referenceId'] as String? ?? '';
          final when = (n['createdAt'] as String?)?.split('.')[0] ?? '';

          // Default to the raw, sanitized backend message:
          final rawMsg = n['message'] as String? ?? '';
          final msgDefault = rawMsg.replaceAll(RegExp(r'[^\x00-\x7F]'), '');

          // Build a custom donation‐request message if possible:
          String displayMsg = msgDefault;
          if (type == 'DONATION_REQUEST') {
            final match = _donationIncoming.firstWhere(
                  (r) => r['requestId'] == refId,
              orElse: () => null,
            );
            if (match != null) {
              final requester = match['requesterFullName'] ?? 'Someone';
              final title = match['donationTitle'] ?? 'your item';
              displayMsg = "$requester requested your donation “$title”.";
            }
          }

          return Card(
            color: read ? Colors.white : const Color(0xFFE8F5E9),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              leading: Icon(
                read ? Icons.mark_email_read : Icons.mark_email_unread,
                color: read ? Colors.grey : Colors.green,
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayMsg,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Chip(
                    label: Text(type),
                    backgroundColor: Colors.teal.shade100,
                  ),
                ],
              ),
              subtitle: Text(when,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black54)),
              isThreeLine: true,
              trailing: IconButton(
                icon: Icon(read ? Icons.close : Icons.done),
                tooltip: read ? "Mark unread" : "Mark read",
                onPressed: () => _markRead(n['notificationId'], !read),
              ),
              onTap: () {
                if (type == 'TRADE_REQUEST') {
                  final isAccepted = displayMsg.toLowerCase().contains('accepted') ||
                      displayMsg.toLowerCase().contains('rejected');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TradeItemRequestPage(
                        token: widget.token,
                        initialRequestId: refId,
                        initialIsIncoming: !isAccepted,
                      ),
                    ),
                  );
                } else if (type == 'DONATION_REQUEST') {
                  final isAccepted = displayMsg.toLowerCase().contains('accepted') ||
                      displayMsg.toLowerCase().contains('rejected');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DonationRequestPage(
                        token: widget.token,
                        initialRequestId: refId,
                        initialIsIncoming: !isAccepted,
                      ),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
