import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'MainScreens/HomePage.dart';
import 'SenderItemSelectionPage.dart';

class TradeItemRequestPage extends StatefulWidget {
  final String token;
  final String? initialRequestId;
  final bool initialIsIncoming;

  const TradeItemRequestPage({
    Key? key,
    required this.token,
    this.initialRequestId,
    this.initialIsIncoming = false,
  }) : super(key: key);

  @override
  State<TradeItemRequestPage> createState() => _TradeItemRequestPageState();
}

class _TradeItemRequestPageState extends State<TradeItemRequestPage> {
  static const String BASE_URL = "http://10.0.2.2:8080";
  bool _isLoading = false;
  List<dynamic> _incoming = [];
  List<dynamic> _outgoing = [];

  @override
  void initState() {
    super.initState();
    _fetchAllRequests().then((_) {
      if (widget.initialRequestId != null) {
        _openInitialRequest();
      }
    });
  }

  Future<bool> _onWillPop() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage(token: widget.token)),
    );
    return false;
  }

  Future<void> _fetchAllRequests() async {
    setState(() => _isLoading = true);
    try {
      final incResp = await http.get(
        Uri.parse("$BASE_URL/api/trade/requests/incoming/detailed"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      final outResp = await http.get(
        Uri.parse("$BASE_URL/api/trade/requests/outgoing/detailed"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      if (incResp.statusCode == 200 && outResp.statusCode == 200) {
        setState(() {
          _incoming = jsonDecode(incResp.body);
          _outgoing = jsonDecode(outResp.body);
        });
      }
    } catch (_) {
      // ignore
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openInitialRequest() {
    final list = widget.initialIsIncoming ? _incoming : _outgoing;
    final req = list.firstWhere(
          (r) => r["requestId"] == widget.initialRequestId,
      orElse: () => null,
    );
    if (req != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (req["status"] == "ACCEPTED" || req["status"] == "REJECTED") {
          _showAcceptedRequestDetailsDialog(
              req, incoming: widget.initialIsIncoming);
        } else {
          _showRequestDetailsDialog(req,
              showActions: widget.initialIsIncoming);
        }
      });
    }
  }

  Future<void> _approveRequest(
      String requestId, String selectedItemId) async {
    final resp = await http.post(
      Uri.parse(
          "$BASE_URL/api/trade/requests/$requestId/approve?selectedItemId=$selectedItemId"),
      headers: {
        "Authorization": "Bearer ${widget.token}",
        "Content-Type": "application/json"
      },
    );
    if (resp.statusCode == 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Request Approved")));
      _fetchAllRequests();
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    final resp = await http.post(
      Uri.parse("$BASE_URL/api/trade/requests/$requestId/reject"),
      headers: {
        "Authorization": "Bearer ${widget.token}",
        "Content-Type": "application/json"
      },
    );
    if (resp.statusCode == 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Request Rejected")));
      _fetchAllRequests();
    }
  }

  Future<List<dynamic>> _fetchSenderItems(String senderUserId) async {
    final resp = await http.get(
      Uri.parse("$BASE_URL/api/trade/requests/sender/$senderUserId/items"),
      headers: {
        "Authorization": "Bearer ${widget.token}",
        "Content-Type": "application/json"
      },
    );
    if (resp.statusCode == 200) return jsonDecode(resp.body);
    return [];
  }

  void _showApproveDialog(String requestId,
      {required String tradeType, required String senderId}) async {
    if (tradeType == "ITEM") {
      final items = await _fetchSenderItems(senderId);
      final selected = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => SenderItemSelectionPage(senderItems: items),
          fullscreenDialog: true,
        ),
      );
      if (selected != null && selected.isNotEmpty) {
        _approveRequest(requestId, selected);
      }
    } else {
      _approveRequest(requestId, "");
    }
  }

  void _showRequestDetailsDialog(Map<String, dynamic> req,
      {required bool showActions}) {
    final id = req["requestId"];
    final name = showActions
        ? (req["offeredByUserName"] ?? "Unknown")
        : (req["receiverFullName"] ?? "Unknown");
    final type = req["tradeType"] ?? "MONEY";
    final title = req["requestedItemTitle"] ?? "";
    final desc = req["requestedItemDescription"] ?? "";
    final price = req["requestedItemPrice"]?.toString() ?? "0.0";
    final imgs = (req["requestedItemImages"] as List<dynamic>?) ?? [];

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      "${showActions ? "Request from" : "Request to"} $name",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(thickness: 1.3),
              const SizedBox(height: 8),
              // Item section
              _buildItemSection(
                label: "Your Item",
                title: title,
                description: desc,
                price: price,
                imageUrls: imgs,
              ),
              const SizedBox(height: 16),
              if (type == "MONEY")
                Text(
                    "Offered Money: \$${(req["moneyOffer"] as num).toStringAsFixed(2)}")
              else
                const Text("Sender wants to trade with an item."),
              const SizedBox(height: 16),
              if (showActions)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _rejectRequest(id);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text("REJECT"),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showApproveDialog(
                          id,
                          tradeType: type,
                          senderId: req["offeredByUserId"],
                        );
                      },
                      style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text("APPROVE"),
                    ),
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }

  void _showAcceptedRequestDetailsDialog(Map<String, dynamic> req,
      {required bool incoming}) {
    final name = incoming
        ? (req["offeredByUserName"] ?? "Unknown")
        : (req["receiverFullName"] ?? "Unknown");
    final title = req["requestedItemTitle"] ?? "";
    final desc = req["requestedItemDescription"] ?? "";
    final price = req["requestedItemPrice"]?.toString() ?? "";
    final imgsReq = (req["requestedItemImages"] as List<dynamic>?) ?? [];
    final offTitle = req["offeredItemTitle"] ?? "";
    final offDesc = req["offeredItemDescription"] ?? "";
    final offPrice = req["offeredItemPrice"]?.toString() ?? "";
    final imgsOff = (req["offeredItemImages"] as List<dynamic>?) ?? [];
    final email = req["senderEmail"] ?? "";
    final phone = req["senderPhone"] ?? "";
    final addr = req["senderAddress"] ?? "";

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 60),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFFB3D1B9), Colors.green],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        incoming
                            ? "Accepted Request from $name"
                            : "Accepted Request to $name",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Divider(color: Colors.white54),
                      const SizedBox(height: 10),
                      _buildColoredSection(
                        "Your Item",
                        _buildItemSection(
                          label: "Item",
                          title: title,
                          description: desc,
                          price: price,
                          imageUrls: imgsReq,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text("Offered Item Details",
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text("Title: $offTitle",
                          style: const TextStyle(color: Colors.white)),
                      Text("Description: $offDesc",
                          style: const TextStyle(color: Colors.white)),
                      Text("Price: \$$offPrice",
                          style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 8),
                      _buildImageSlideshow(imgsOff),
                      const SizedBox(height: 16),
                      const Text("Sender Contact Information",
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      Text("Email: $email",
                          style: const TextStyle(color: Colors.white)),
                      Text("Phone: $phone",
                          style: const TextStyle(color: Colors.white)),
                      Text("Address: $addr",
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
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
                  child:
                  const Icon(Icons.check_circle, size: 56, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColoredSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: child,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white));
  }

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
        Text("$label: $title",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        if (description.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text("Description: $description")),
        if (price != "0.0")
          Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text("Price: \$$price")),
        const SizedBox(height: 8),
        _buildImageSlideshow(imageUrls),
      ],
    );
  }

  Widget _buildImageSlideshow(List<dynamic> imageUrls) {
    if (imageUrls.isEmpty) return const Text("No images available");
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        itemBuilder: (_, i) {
          final url = imageUrls[i];
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[200]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                  const Center(child: Text("Error"))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestList(List<dynamic> requests, {required bool incoming}) {
    if (requests.isEmpty) {
      return const Center(child: Text("No requests found."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: requests.length,
      itemBuilder: (ctx, i) {
        final req = requests[i];
        final otherName = incoming
            ? (req["offeredByUserName"] ?? "Unknown")
            : (req["receiverFullName"] ?? "Unknown");
        final titleText =
        incoming ? "Request from $otherName" : "Request to $otherName";
        return Card(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: incoming
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              child: Icon(
                incoming ? Icons.swap_horiz : Icons.swap_horiz_outlined,
                color: incoming ? Colors.green : Colors.orange,
              ),
            ),
            title: Text(titleText,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Status: ${req["status"]}"),
            trailing: IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () {
                if (req["status"] == "ACCEPTED") {
                  _showAcceptedRequestDetailsDialog(req, incoming: incoming);
                } else {
                  _showRequestDetailsDialog(req, showActions: incoming);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAcceptedList(List<dynamic> requests,
      {required bool incoming}) {
    if (requests.isEmpty) {
      return Center(
          child: Text(incoming
              ? "No accepted incoming."
              : "No accepted sent."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: requests.length,
      itemBuilder: (ctx, i) {
        final req = requests[i];
        final otherName = incoming
            ? (req["offeredByUserName"] ?? "Unknown")
            : (req["receiverFullName"] ?? "Unknown");
        final titleText =
        incoming ? "Request from $otherName" : "Request to $otherName";
        return Card(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: incoming
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.purple.withOpacity(0.1),
              child: Icon(
                incoming ? Icons.check_circle : Icons.check_circle_outline,
                color: incoming ? Colors.blue : Colors.purple,
              ),
            ),
            title: Text(titleText,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("Status: ACCEPTED"),
            trailing: IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () => _showAcceptedRequestDetailsDialog(
                  req, incoming: incoming),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusTabs(List<dynamic> list,
      {required bool incoming}) {
    final pending = list.where((r) => r["status"] == "PENDING").toList();
    final accepted = list.where((r) => r["status"] == "ACCEPTED").toList();
    final rejected = list.where((r) => r["status"] == "REJECTED").toList();
    final bool isThisGroupInitial = widget.initialRequestId != null &&
        incoming == widget.initialIsIncoming;
    final int initialStatusIndex = isThisGroupInitial ? 1 : 0;

    return DefaultTabController(
      length: 3,
      initialIndex: initialStatusIndex,
      child: Column(
        children: [
          Material(
            color: Colors.white,
            child: TabBar(
              indicatorColor: Colors.green,
              labelColor: Colors.green,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: "Pending"),
                Tab(text: "Accepted"),
                Tab(text: "Rejected"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildRequestList(pending, incoming: incoming),
                _buildAcceptedList(accepted, incoming: incoming),
                _buildRequestList(rejected, incoming: incoming),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: DefaultTabController(
        length: 2,
        initialIndex: widget.initialIsIncoming ? 0 : 1,
        child: Scaffold(
          backgroundColor: const Color(0xFFECF3EC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            title:
            const Text("Trade Requests", style: TextStyle(color: Colors.black)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => _onWillPop(),
            ),
            bottom: const TabBar(
              indicatorColor: Colors.green,
              labelColor: Colors.green,
              unselectedLabelColor: Colors.grey,
              tabs: [Tab(text: "Incoming"), Tab(text: "Sent")],
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
            children: [
              _buildStatusTabs(_incoming, incoming: true),
              _buildStatusTabs(_outgoing, incoming: false),
            ],
          ),
        ),
      ),
    );
  }
}
