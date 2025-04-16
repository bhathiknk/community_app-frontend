import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/**
 * A page showing all incoming donation requests for the current user's donation items.
 * Each request shows:
 *   - Donation item data (title, first image, or "No image"),
 *   - Requester's data (name, email, phone, profile image),
 *   - The request message + status,
 *   - Accept/Reject buttons if status = PENDING.
 */
class DonationRequestPage extends StatefulWidget {
  final String token;
  const DonationRequestPage({Key? key, required this.token}) : super(key: key);

  @override
  State<DonationRequestPage> createState() => _DonationRequestPageState();
}

class _DonationRequestPageState extends State<DonationRequestPage> {
  bool _isLoading = false;
  List<dynamic> _requests = [];
  static const String BASE_URL = "http://10.0.2.2:8080";

  @override
  void initState() {
    super.initState();
    _fetchDonationRequests();
  }

  // GET /api/donation-requests/incoming => List<DonationRequestViewDTO>
  Future<void> _fetchDonationRequests() async {
    setState(() => _isLoading = true);
    try {
      final resp = await http.get(
        Uri.parse("$BASE_URL/api/donation-requests/incoming"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() => _requests = data);
      } else {
        debugPrint("Failed to load donation requests: ${resp.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Load failed: ${resp.statusCode}")),
        );
      }
    } catch (e) {
      debugPrint("Error fetching donation requests: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Accept a donation request => POST /api/donation-requests/{requestId}/accept
  Future<void> _acceptRequest(String requestId) async {
    try {
      final resp = await http.post(
        Uri.parse("$BASE_URL/api/donation-requests/$requestId/accept"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request accepted")),
        );
        _fetchDonationRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Accept failed: ${resp.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // Reject => POST /api/donation-requests/{requestId}/reject
  Future<void> _rejectRequest(String requestId) async {
    try {
      final resp = await http.post(
        Uri.parse("$BASE_URL/api/donation-requests/$requestId/reject"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request rejected")),
        );
        _fetchDonationRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Reject failed: ${resp.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB3D1B9),
      appBar: AppBar(
        title: const Text("Donation Requests"),
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
          ? const Center(child: Text("No donation requests yet."))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final r = _requests[index];
          return _buildRequestCard(r);
        },
      ),
    );
  }

  Widget _buildRequestCard(dynamic r) {
    // The request object is DonationRequestViewDTO
    final requestId = r["requestId"] ?? "";
    final donationId = r["donationId"] ?? "";
    final donationTitle = r["donationTitle"] ?? "Unknown item";
    final donationImages = (r["donationImages"] as List<dynamic>? ?? []);
    final donationStatus = r["donationStatus"] ?? "";
    final message = r["message"] ?? "";
    final status = r["status"] ?? "PENDING";
    final createdAt = r["createdAt"] ?? "";

    // Requester data
    final requestedBy = r["requestedBy"] ?? "";
    final requesterName = r["requesterFullName"] ?? "Unknown";
    final requesterEmail = r["requesterEmail"] ?? "";
    final requesterPhone = r["requesterPhone"] ?? "";
    final requesterProfile = r["requesterProfile"] ?? "";

    // We'll display the first donation image (if any)
    final firstImage = donationImages.isNotEmpty ? donationImages.first : null;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Donation info
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: firstImage != null
                      ? Image.network(
                    firstImage,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                      : Container(
                    color: Colors.grey.shade300,
                    width: 80,
                    height: 80,
                    child: const Icon(Icons.volunteer_activism, size: 40),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donationTitle,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text("Donation status: $donationStatus",
                          style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Request info
            Text("Message: $message"),
            const SizedBox(height: 6),
            Text("Request Status: $status",
                style: TextStyle(
                  color: status == "ACCEPTED"
                      ? Colors.green
                      : status == "REJECTED"
                      ? Colors.red
                      : Colors.orange,
                )),
            Text("Created at: $createdAt", style: const TextStyle(color: Colors.black45)),
            const SizedBox(height: 8),
            // Requester info
            Row(
              children: [
                // Requester profile
                CircleAvatar(
                  radius: 24,
                  backgroundImage: (requesterProfile.isNotEmpty)
                      ? NetworkImage(requesterProfile)
                      : const AssetImage("images/default_profile.png") as ImageProvider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Requested by: $requesterName",
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (requesterEmail.isNotEmpty)
                        Text("Email: $requesterEmail",
                            style: const TextStyle(fontSize: 13, color: Colors.black54)),
                      if (requesterPhone.isNotEmpty)
                        Text("Phone: $requesterPhone",
                            style: const TextStyle(fontSize: 13, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Accept/Reject if still pending
            if (status == "PENDING")
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => _acceptRequest(requestId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Accept"),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _rejectRequest(requestId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Reject"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
