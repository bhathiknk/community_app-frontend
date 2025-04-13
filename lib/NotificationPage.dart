import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NotificationPage extends StatefulWidget {
  final String token;
  const NotificationPage({Key? key, required this.token}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  static const String BASE_URL = "http://10.0.2.2:8080";
  bool _isLoading = false;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final resp = await http.get(
        Uri.parse("$BASE_URL/api/notifications/me"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );
      setState(() => _isLoading = false);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        setState(() {
          _notifications = data;
        });
      } else {
        final msg = jsonDecode(resp.body)["message"] ?? "Failed to load notifications";
        _showError(msg);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Error: $e");
    }
  }

  Future<void> _markAsRead(String notificationId, bool read) async {
    try {
      final resp = await http.put(
        Uri.parse("$BASE_URL/api/notifications/$notificationId/read?read=$read"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );
      if (resp.statusCode == 200) {
        _fetchNotifications();
      } else {
        _showError("Failed to update notification");
      }
    } catch (e) {
      _showError("Error: $e");
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      final resp = await http.delete(
        Uri.parse("$BASE_URL/api/notifications/$notificationId"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );
      if (resp.statusCode == 200) {
        _fetchNotifications();
      } else {
        _showError("Failed to delete notification");
      }
    } catch (e) {
      _showError("Error: $e");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB3D1B9),
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Notifications", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? const Center(
        child: Text(
          "You have no notifications.",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final notif = _notifications[index];
          final id = notif["notificationId"];
          final message = notif["message"] ?? "No message";
          final isRead = notif["read"] ?? false;
          final createdAt = notif["createdAt"]?.toString().split(".")[0] ?? "";

          return Container(
            decoration: BoxDecoration(
              color: isRead ? Colors.white : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: isRead ? Colors.grey[300] : Colors.green,
                child: Icon(
                  isRead ? Icons.notifications_none : Icons.notifications_active,
                  color: Colors.white,
                ),
              ),
              title: Text(
                message,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                createdAt,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.done_all, color: Colors.blue),
                    tooltip: "Mark as Read",
                    onPressed: () => _markAsRead(id, true),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: "Delete",
                    onPressed: () => _deleteNotification(id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
