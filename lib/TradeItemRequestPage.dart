import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'NotificationPage.dart';
import 'SenderItemSelectionPage.dart';

class TradeItemRequestPage extends StatefulWidget {
  final String token;
  final String currentUserId;
  const TradeItemRequestPage({Key? key, required this.token, required this.currentUserId})
      : super(key: key);

  @override
  State<TradeItemRequestPage> createState() => _TradeItemRequestPageState();
}

class _TradeItemRequestPageState extends State<TradeItemRequestPage> {
  static const String BASE_URL = "http://10.0.2.2:8080";
  bool _isLoading = false;
  List<dynamic> _detailedRequests = [];

  @override
  void initState() {
    super.initState();
    _fetchIncomingRequestsDetailed();
  }

  Future<void> _fetchIncomingRequestsDetailed() async {
    setState(() => _isLoading = true);
    try {
      // Fetch all incoming requests. Client-side filtering will be performed.
      final resp = await http.get(
        Uri.parse("$BASE_URL/api/trade/requests/incoming/detailed"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );
      setState(() => _isLoading = false);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        setState(() {
          _detailedRequests = data;
        });
      } else {
        final msg = jsonDecode(resp.body)["message"] ?? "Failed to load requests";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _approveRequest(String requestId, String selectedItemId) async {
    try {
      final resp = await http.post(
        Uri.parse("$BASE_URL/api/trade/requests/$requestId/approve?selectedItemId=$selectedItemId"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request Approved")),
        );
        _fetchIncomingRequestsDetailed();
      } else {
        final msg = jsonDecode(resp.body)["message"] ?? "Failed to approve";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      final resp = await http.post(
        Uri.parse("$BASE_URL/api/trade/requests/$requestId/reject"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request Rejected")),
        );
        _fetchIncomingRequestsDetailed();
      } else {
        final msg = jsonDecode(resp.body)["message"] ?? "Failed to reject";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showApproveDialog(String requestId, {required String tradeType, required String senderId}) async {
    if (tradeType == "ITEM") {
      final senderItems = await _fetchSenderItems(senderId);
      final selectedItemId = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => SenderItemSelectionPage(senderItems: senderItems),
          fullscreenDialog: true,
        ),
      );
      if (selectedItemId != null && selectedItemId.isNotEmpty) {
        _approveRequest(requestId, selectedItemId);
      }
    } else {
      _approveRequest(requestId, "");
    }
  }

  Future<List<dynamic>> _fetchSenderItems(String senderUserId) async {
    final url = "$BASE_URL/api/trade/requests/sender/$senderUserId/items";
    try {
      final resp = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json"
        },
      );
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as List;
      } else {
        final msg = jsonDecode(resp.body)["message"] ?? "Failed to load sender's items";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching sender items: $e")),
      );
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    // Filter requests based on status.
    final pendingRequests = _detailedRequests.where((req) => req["status"] == "PENDING").toList();
    final acceptedRequests = _detailedRequests.where((req) => req["status"] == "ACCEPTED").toList();
    final rejectedRequests = _detailedRequests.where((req) => req["status"] == "REJECTED").toList();

    // Wrap Scaffold inside a DefaultTabController
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFB3D1B9),
        appBar: AppBar(
          title: const Text(
            "Incoming Trade Requests",
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationPage(token: widget.token),
                  ),
                );
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.green,
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Accepted'),
              Tab(text: 'Rejected'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          children: [
            _buildRequestList(pendingRequests),
            _buildAcceptedList(acceptedRequests),
            _buildRequestList(rejectedRequests),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestList(List<dynamic> requests) {
    if (requests.isEmpty) {
      return const Center(child: Text("No requests found."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: requests.length,
      itemBuilder: (context, i) {
        final req = requests[i];
        final requestId = req["requestId"];
        final offeredByName = req["offeredByUserName"] ?? "Unknown";
        final tradeType = req["tradeType"] ?? "MONEY";

        final requestedTitle = req["requestedItemTitle"] ?? "??";
        final requestedDescription = req["requestedItemDescription"] ?? "";
        final requestedPrice = req["requestedItemPrice"]?.toString() ?? "0.0";
        final requestedImages = req["requestedItemImages"] as List<dynamic>? ?? [];

        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            title: Text(
              "Request from $offeredByName",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Status: ${req["status"]}"),
            children: [
              _buildItemSection(
                label: "Your Item",
                title: requestedTitle,
                description: requestedDescription,
                price: requestedPrice,
                imageUrls: requestedImages,
              ),
              if (tradeType == "MONEY")
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 12),
                  child: Text("Offered Money: \$${(req["moneyOffer"] as num).toStringAsFixed(2)}"),
                )
              else if (tradeType == "ITEM")
                const Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 12),
                  child: Text("Sender wants to trade with an item."),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (req["status"] == "PENDING")
                    TextButton(
                      onPressed: () => _rejectRequest(requestId),
                      child: const Text("REJECT"),
                    ),
                  if (req["status"] == "PENDING")
                    TextButton(
                      onPressed: () => _showApproveDialog(
                        requestId,
                        tradeType: tradeType,
                        senderId: req["offeredByUserId"],
                      ),
                      child: const Text("APPROVE"),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // For accepted requests, show extra offered item details
  Widget _buildAcceptedList(List<dynamic> requests) {
    if (requests.isEmpty) {
      return const Center(child: Text("No accepted requests found."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: requests.length,
      itemBuilder: (context, i) {
        final req = requests[i];
        final offeredByName = req["offeredByUserName"] ?? "Unknown";
        final tradeType = req["tradeType"] ?? "MONEY";
        final requestedTitle = req["requestedItemTitle"] ?? "??";
        final requestedDescription = req["requestedItemDescription"] ?? "";
        final requestedPrice = req["requestedItemPrice"]?.toString() ?? "0.0";
        final requestedImages = req["requestedItemImages"] as List<dynamic>? ?? [];

        final offeredItemTitle = req["offeredItemTitle"] ?? "";
        final offeredItemDescription = req["offeredItemDescription"] ?? "";
        final offeredItemPrice = req["offeredItemPrice"]?.toString() ?? "";
        final offeredItemImages = req["offeredItemImages"] as List<dynamic>? ?? [];

        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            title: Text(
              "Accepted: Request from $offeredByName",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text("Status: ACCEPTED"),
            children: [
              _buildItemSection(
                label: "Your Item",
                title: requestedTitle,
                description: requestedDescription,
                price: requestedPrice,
                imageUrls: requestedImages,
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Offered Item Details",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text("Title: $offeredItemTitle"),
                    const SizedBox(height: 4),
                    Text("Description: $offeredItemDescription"),
                    const SizedBox(height: 4),
                    Text("Price: \$$offeredItemPrice"),
                    const SizedBox(height: 8),
                    _buildImageSlideshow(offeredItemImages),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemSection({
    required String label,
    required String title,
    required String description,
    required String price,
    required List<dynamic> imageUrls,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: $title", style: const TextStyle(fontWeight: FontWeight.bold)),
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text("Description: $description"),
            ),
          if (price != "0.0")
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text("Price: \$$price"),
            ),
          const SizedBox(height: 8),
          _buildImageSlideshow(imageUrls),
        ],
      ),
    );
  }

  Widget _buildImageSlideshow(List<dynamic> imageUrls) {
    if (imageUrls.isEmpty) {
      return const Text("No images");
    }
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        itemBuilder: (ctx, idx) {
          final url = imageUrls[idx];
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(3, 2)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (ctx, e, stack) => const Center(child: Text("Error")),
              ),
            ),
          );
        },
      ),
    );
  }
}
