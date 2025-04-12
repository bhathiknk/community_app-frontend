import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TradeItemRequestPage extends StatefulWidget {
  final String token;
  const TradeItemRequestPage({Key? key, required this.token}) : super(key: key);

  @override
  State<TradeItemRequestPage> createState() => _TradeItemRequestPageState();
}

class _TradeItemRequestPageState extends State<TradeItemRequestPage> {
  static const String BASE_URL = "http://10.0.2.2:8080";
  bool _isLoading = false;
  List<dynamic> _detailedRequests = [];
  int _notificationCount = 0;

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
        final msg = jsonDecode(resp.body)["message"] ?? "Failed to load requests";
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
        setState(() {
          _notificationCount++;
        });
        _fetchIncomingRequestsDetailed();
      } else {
        final msg = jsonDecode(resp.body)["message"] ?? "Failed to approve";
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
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
        setState(() {
          _notificationCount++;
        });
        _fetchIncomingRequestsDetailed();
      } else {
        final msg = jsonDecode(resp.body)["message"] ?? "Failed to reject";
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  /// Single definition of _showApproveDialog.
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
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
    return Scaffold(
      backgroundColor: const Color(0xFFB3D1B9),
      appBar: AppBar(
        title: const Text(
          "Incoming Trade Requests",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Bell icon with notification count.
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.black),
                onPressed: () {
                  // Navigate to notification page if needed.
                },
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '$_notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _detailedRequests.isEmpty
          ? const Center(child: Text("No incoming requests."))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _detailedRequests.length,
        itemBuilder: (context, i) {
          final req = _detailedRequests[i];
          final requestId = req["requestId"];
          final status = req["status"];
          final moneyOffer = req["moneyOffer"] ?? 0;
          final offeredByName = req["offeredByUserName"] ?? "Unknown";
          final tradeType = req["tradeType"] ?? "MONEY";

          final requestedTitle = req["requestedItemTitle"] ?? "??";
          final requestedDescription = req["requestedItemDescription"] ?? "";
          final requestedPrice = req["requestedItemPrice"]?.toString() ?? "0.0";
          final requestedImages = req["requestedItemImages"] as List<dynamic>? ?? [];

          return Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              title: Text(
                "Request from $offeredByName",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                status == "PENDING"
                    ? "Status: Pending"
                    : "Status: ${status[0]}${status.substring(1).toLowerCase()}",
              ),
              children: [
                _buildItemSection(
                  label: "Your Item",
                  title: requestedTitle,
                  description: requestedDescription,
                  price: requestedPrice,
                  imageUrls: requestedImages,
                ),
                if (tradeType == "MONEY" && moneyOffer > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 12),
                    child: Text(
                      "Offered Money: \$${moneyOffer.toStringAsFixed(2)}",
                    ),
                  )
                else if (tradeType == "ITEM") ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 16, bottom: 12),
                    child: Text("Sender wants to trade with an item."),
                  ),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: status == "PENDING"
                          ? () => _rejectRequest(requestId)
                          : null,
                      child: const Text("REJECT"),
                    ),
                    TextButton(
                      onPressed: status == "PENDING"
                          ? () => _showApproveDialog(
                        requestId,
                        tradeType: tradeType,
                        senderId: req["offeredByUserId"],
                      )
                          : null,
                      child: const Text("APPROVE"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
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
                errorBuilder: (ctx, e, stack) =>
                const Center(child: Text("Error")),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Full-screen sender item selection page with a grid view and an overlay "eye" icon.
/// Tapping the eye icon now opens a fixed–size popup (near full screen) that uses a slider (PageView)
/// to show all images of that item, with a clear, reactive design.
class SenderItemSelectionPage extends StatefulWidget {
  final List<dynamic> senderItems;
  const SenderItemSelectionPage({Key? key, required this.senderItems}) : super(key: key);

  @override
  State<SenderItemSelectionPage> createState() => _SenderItemSelectionPageState();
}

class _SenderItemSelectionPageState extends State<SenderItemSelectionPage> {
  String? selectedItemId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background.
      appBar: AppBar(
        title: const Text("Select Sender's Item"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          itemCount: widget.senderItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Two items per row.
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.7,
          ),
          itemBuilder: (ctx, index) {
            final item = widget.senderItems[index];
            final itemId = item["itemId"] ?? "";
            final title = item["title"] ?? "";
            final description = item["description"] ?? "";
            final price = item["price"]?.toString() ?? "0.0";
            final images = item["images"] as List<dynamic>? ?? [];
            final imageUrl = images.isNotEmpty ? images[0] : null;
            final isSelected = selectedItemId == itemId;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedItemId = itemId;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Colors.green : Colors.grey.shade300,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display item image.
                        if (imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              imageUrl,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, e, stack) =>
                              const Icon(Icons.error),
                            ),
                          )
                        else
                          Container(
                            height: 150,
                            width: double.infinity,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image, size: 40),
                          ),
                        const SizedBox(height: 4),
                        // Item title.
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // Item description.
                        Text(
                          description,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // Price.
                        Text(
                          "\$$price",
                          style: const TextStyle(fontSize: 12, color: Colors.blueAccent),
                        ),
                      ],
                    ),
                    // Overlay "eye" icon at top-right.
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () {
                          _showItemDetailsPopup(item);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.remove_red_eye,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {
            if (selectedItemId == null || selectedItemId!.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please select an item first.")),
              );
              return;
            }
            Navigator.pop(context, selectedItemId);
          },
          child: const Text(
            "Approve",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }

  /// Show a popup with full details about an item.
  void _showItemDetailsPopup(dynamic item) {
    final title = item["title"] ?? "";
    final description = item["description"] ?? "";
    final price = item["price"]?.toString() ?? "0.0";
    final images = item["images"] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: 500,
            child: Column(
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                // Image slider if images exist
                Container(
                  height: 150,
                  child: images.isNotEmpty
                      ? PageView.builder(
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      final imageUrl = images[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, error, stackTrace) =>
                            const Icon(Icons.error),
                          ),
                        ),
                      );
                    },
                  )
                      : Container(
                    height: 150,
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.image, size: 50)),
                  ),
                ),
                // Price and description details.
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Price: \$$price",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                // Close button.
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Close", style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
