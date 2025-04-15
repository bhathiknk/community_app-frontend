import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'MainScreens/HomePage.dart';
import 'NotificationPage.dart';
import 'SenderItemSelectionPage.dart';

class TradeItemRequestPage extends StatefulWidget {
  final String token;
  final String currentUserId;
  const TradeItemRequestPage({
    Key? key,
    required this.token,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<TradeItemRequestPage> createState() => _TradeItemRequestPageState();
}

class _TradeItemRequestPageState extends State<TradeItemRequestPage> {
  static const String BASE_URL = "http://10.0.2.2:8080";
  bool _isLoading = false;
  List<dynamic> _detailedRequests = [];

  // WillPopScope fix
  Future<bool> _onWillPop() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage(token: widget.token)),
    );
    return false;
  }

  @override
  void initState() {
    super.initState();
    _fetchIncomingRequestsDetailed();
  }

  Future<void> _fetchIncomingRequestsDetailed() async {
    setState(() => _isLoading = true);
    try {
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
        final msg =
            jsonDecode(resp.body)["message"] ?? "Failed to load requests";
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
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
        Uri.parse(
            "$BASE_URL/api/trade/requests/$requestId/approve?selectedItemId=$selectedItemId"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Request Approved")));
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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Request Rejected")));
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
        final msg =
            jsonDecode(resp.body)["message"] ?? "Failed to load sender's items";
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching sender items: $e")));
    }
    return [];
  }

  void _showApproveDialog(String requestId,
      {required String tradeType, required String senderId}) async {
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

  /// Displays a clean, attractive dialog for pending or rejected requests.
  void _showRequestDetailsDialog(Map<String, dynamic> req,
      {required bool showActions}) {
    final requestId = req["requestId"];
    final offeredByName = req["offeredByUserName"] ?? "Unknown";
    final tradeType = req["tradeType"] ?? "MONEY";
    final requestedTitle = req["requestedItemTitle"] ?? "??";
    final requestedDescription = req["requestedItemDescription"] ?? "";
    final requestedPrice = req["requestedItemPrice"]?.toString() ?? "0.0";
    final requestedImages = req["requestedItemImages"] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          insetPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with title and close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          "Request from $offeredByName",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    ],
                  ),
                  const Divider(thickness: 1.3),
                  const SizedBox(height: 8),
                  _buildItemSection(
                    label: "Your Item",
                    title: requestedTitle,
                    description: requestedDescription,
                    price: requestedPrice,
                    imageUrls: requestedImages,
                  ),
                  const SizedBox(height: 16),
                  if (tradeType == "MONEY")
                    Text(
                      "Offered Money: \$${(req["moneyOffer"] as num).toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 16),
                    )
                  else if (tradeType == "ITEM")
                    const Text(
                      "Sender wants to trade with an item instead of money.",
                      style: TextStyle(fontSize: 16),
                    ),
                  const SizedBox(height: 16),
                  if (showActions)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _rejectRequest(requestId);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "REJECT",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showApproveDialog(
                              requestId,
                              tradeType: tradeType,
                              senderId: req["offeredByUserId"],
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "APPROVE",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Displays a clean, attractive dialog for accepted requests.
  void _showAcceptedRequestDetailsDialog(Map<String, dynamic> req) {
    final offeredByName = req["offeredByUserName"] ?? "Unknown";
    final requestedTitle = req["requestedItemTitle"] ?? "??";
    final requestedDescription = req["requestedItemDescription"] ?? "";
    final requestedPrice = req["requestedItemPrice"]?.toString() ?? "0.0";
    final requestedImages = req["requestedItemImages"] as List<dynamic>? ?? [];
    final offeredItemTitle = req["offeredItemTitle"] ?? "";
    final offeredItemDescription = req["offeredItemDescription"] ?? "";
    final offeredItemPrice = req["offeredItemPrice"]?.toString() ?? "";
    final offeredItemImages = req["offeredItemImages"] as List<dynamic>? ?? [];
    final senderEmail = req["senderEmail"] ?? "";
    final senderPhone = req["senderPhone"] ?? "";
    final senderAddress = req["senderAddress"] ?? "";

    showDialog(
      context: context,
      barrierDismissible: true, // allows tapping outside to close
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent, // Transparent for custom shapes
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main gradient background container
              Container(
                margin: const EdgeInsets.only(top: 60),
                // leaves space for the circle
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB3D1B9), Colors.green],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            "Accepted Request from $offeredByName",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Divider(
                            thickness: 1.3,
                            color: Colors.white54,
                          ),
                          const SizedBox(height: 10),

                          // Your Item
                          _buildColoredSection(
                            "Your Item",
                            _buildItemSection(
                              label: "Item",
                              title: requestedTitle,
                              description: requestedDescription,
                              price: requestedPrice,
                              imageUrls: requestedImages,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Offered Item Header
                          _buildSectionHeader("Offered Item Details"),
                          const SizedBox(height: 8),

                          // Offered Item Fields
                          Text(
                            "Title: $offeredItemTitle",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Description: $offeredItemDescription",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Price: \$$offeredItemPrice",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildImageSlideshow(offeredItemImages),
                          const SizedBox(height: 16),

                          // Sender contact
                          _buildSectionHeader("Sender Contact Information"),
                          const SizedBox(height: 8),
                          Text(
                            "Name: $offeredByName",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "Email: $senderEmail",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "Phone: $senderPhone",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "Address: $senderAddress",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Circle Avatar or Icon at the top (floating effect)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.transparent,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Colors.green, Colors.teal],
                        center: Alignment.center,
                        radius: 0.9,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Close button in the top-right corner (over the avatar area)
              Positioned(
                right: 0,
                top: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper for coloring sections
  Widget _buildColoredSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: child,
        ),
      ],
    );
  }

  // Helper for section headers
  Widget _buildSectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter requests based on status.
    final pendingRequests =
    _detailedRequests.where((req) => req["status"] == "PENDING").toList();
    final acceptedRequests =
    _detailedRequests.where((req) => req["status"] == "ACCEPTED").toList();
    final rejectedRequests =
    _detailedRequests.where((req) => req["status"] == "REJECTED").toList();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: const Color(0xFFECF3EC),
          appBar: AppBar(
            title: const Text(
              "Incoming Trade Requests",
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.white,
            elevation: 2,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomePage(token: widget.token),
                  ),
                );
              },
            ),
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
              _buildRequestList(pendingRequests, showActions: true),
              _buildAcceptedList(acceptedRequests),
              _buildRejectedList(rejectedRequests),
            ],
          ),
        ),
      ),
    );
  }

  // List builder for pending requests
  Widget _buildRequestList(List<dynamic> requests, {required bool showActions}) {
    if (requests.isEmpty) {
      return const Center(child: Text("No requests found."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: requests.length,
      itemBuilder: (context, i) {
        final req = requests[i];
        final offeredByName = req["offeredByUserName"] ?? "Unknown";
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Card(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: CircleAvatar(
                backgroundColor: Colors.green.withOpacity(0.1),
                child: const Icon(Icons.swap_horiz, color: Colors.green),
              ),
              title: Text(
                "Request from $offeredByName",
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text("Status: ${req["status"]}"),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.open_in_new),
                color: Colors.grey[700],
                onPressed: () =>
                    _showRequestDetailsDialog(req, showActions: showActions),
              ),
            ),
          ),
        );
      },
    );
  }

  // Accepted requests list builder.
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
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Card(
            color: Colors.white,
            elevation: 2,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: const Icon(Icons.check_circle, color: Colors.blue),
              ),
              title: Text(
                "Request from $offeredByName",
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text("Status: ACCEPTED"),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.open_in_new),
                color: Colors.grey[700],
                onPressed: () {
                  _showAcceptedRequestDetailsDialog(req);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // Rejected requests list builder (red theme).
  Widget _buildRejectedList(List<dynamic> requests) {
    if (requests.isEmpty) {
      return const Center(child: Text("No rejected requests found."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: requests.length,
      itemBuilder: (context, i) {
        final req = requests[i];
        final offeredByName = req["offeredByUserName"] ?? "Unknown";
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Card(
            color: Colors.white,
            elevation: 2,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: CircleAvatar(
                backgroundColor: Colors.red.withOpacity(0.1),
                child: const Icon(Icons.cancel, color: Colors.red),
              ),
              title: Text(
                "Request from $offeredByName",
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text("Status: REJECTED"),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.open_in_new),
                color: Colors.red,
                onPressed: () {
                  // Even though it's rejected, we can still show the details
                  _showRequestDetailsDialog(req, showActions: false);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // Utility widget for displaying item details.
  Widget _buildItemSection({
    required String label,
    required String title,
    required String description,
    required String price,
    required List<dynamic> imageUrls,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: $title",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        if (description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "Description: $description",
              style: const TextStyle(fontSize: 14),
            ),
          ),
        if (price != "0.0")
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "Price: \$$price",
              style: const TextStyle(fontSize: 14),
            ),
          ),
        const SizedBox(height: 12),
        _buildImageSlideshow(imageUrls),
      ],
    );
  }

  // Utility widget for the horizontal image slideshow.
  Widget _buildImageSlideshow(List<dynamic> imageUrls) {
    if (imageUrls.isEmpty) {
      return const Text("No images available", style: TextStyle(fontSize: 14));
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
              color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (ctx, e, stack) => Container(
                  color: Colors.redAccent.withOpacity(0.1),
                  alignment: Alignment.center,
                  child: const Text(
                    "Error",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
