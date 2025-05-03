import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    setState(() => _isLoading = true);
    try {
      final resp = await http.get(
        Uri.parse("$BASE_URL/api/notifications/me/detailed"),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (resp.statusCode == 200) {
        setState(() => _notes = jsonDecode(resp.body));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load notifications')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markRead(String id, bool read) async {
    await http.put(
      Uri.parse("$BASE_URL/api/notifications/$id/read?read=$read"),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    _fetchNotes();
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
          final msg = n['message'] as String? ?? '';
          final when = (n['createdAt'] as String?)?.split('.')[0] ?? '';
          final type = n['referenceType'] as String? ?? 'UNKNOWN';
          final refId = n['referenceId'] as String? ?? '';

          return Card(
            color: read ? Colors.white : const Color(0xFFE8F5E9),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Icon(
                read ? Icons.mark_email_read : Icons.mark_email_unread,
                color: read ? Colors.grey : Colors.green,
              ),
              title: Text(msg,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(when,
                      style:
                      const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text("Type: $type",
                      style: const TextStyle(fontSize: 12)),
                  Text("ID: $refId", style: const TextStyle(fontSize: 12)),
                ],
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: Icon(read ? Icons.close : Icons.done),
                tooltip: read ? "Mark unread" : "Mark read",
                onPressed: () => _markRead(n['notificationId'], !read),
              ),
              onTap: () {
                if (type == 'TRADE_REQUEST') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TradeItemRequestPage(
                        token: widget.token,
                        initialRequestId: refId,
                        initialIsIncoming: false,
                      ),
                    ),
                  );
                }
                // TODO: handle DONATION_REQUEST the same way
              },
            ),
          );
        },
      ),
    );
  }
}
