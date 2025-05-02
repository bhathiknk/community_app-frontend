import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../bottom_nav_bar.dart';

/**
 * A page showing all donation items from other users.
 * Main card displays the first image (with a slideshow hint if more),
 * title, status, and short description.
 * When tapped, a near full-screen dialog opens with a clear slideshow,
 * detailed donation info, owner info (with profile data), and a "Request Donation" button.
 */
class DonationsPage extends StatefulWidget {
  final String token;
  const DonationsPage({Key? key, required this.token}) : super(key: key);

  @override
  State<DonationsPage> createState() => _DonationsPageState();
}

class _DonationsPageState extends State<DonationsPage> {
  bool _isLoading = false;
  List<dynamic> _donations = [];
  static const String BASE_URL = "http://10.0.2.2:8080";

  @override
  void initState() {
    super.initState();
    _fetchOtherDonations();
  }

  // Fetch all active donation items from others.
  // ALGORITHM: Linear filtering – backend returns only donations from others.
  Future<void> _fetchOtherDonations() async {
    setState(() => _isLoading = true);
    try {
      final resp = await http.get(
        Uri.parse("$BASE_URL/api/donations/others"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() => _donations = data);
      } else {
        debugPrint("Failed to load other donations: ${resp.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Load failed: ${resp.statusCode}")),
        );
      }
    } catch (e) {
      debugPrint("Error fetching others' donations: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade700,
      appBar: AppBar(
        automaticallyImplyLeading: false, // no back button
        title: const Text("All Donations"),
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _donations.isEmpty
              ? const Center(child: Text("No donations from others yet."))
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _donations.length,
            itemBuilder: (context, index) {
              final donation = _donations[index];
              return _buildDonationCard(donation);
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: 1, token: widget.token),
    );
  }

  // Builds a modern card for each donation item.
  Widget _buildDonationCard(dynamic donation) {
    final title = donation["title"] ?? "No Title";
    final description = donation["description"] ?? "";
    final images = donation["images"] as List<dynamic>? ?? [];
    final status = donation["status"] ?? "ACTIVE";

    // Owner details (shown briefly on card)
    final ownerName = donation["ownerFullName"] ?? "Unknown";
    // We use only the first image in the card.
    final firstImage = images.isNotEmpty ? images.first : null;
    final extraImagesCount = images.length > 1 ? images.length - 1 : 0;

    return GestureDetector(
      onTap: () {
        _showDonationDialog(
          donationId: donation["donationId"],
          title: title,
          description: description,
          status: status,
          images: images,
          ownerName: donation["ownerFullName"] ?? "Unknown",
          ownerPhone: donation["ownerPhone"] ?? "",
          ownerAddress: donation["ownerAddress"] ?? "",
          ownerCity: donation["ownerCity"] ?? "",
          ownerProvince: donation["ownerProvince"] ?? "",
          ownerProfile: donation["ownerProfileImage"] ?? "",
        );
      },
      child: Card(
        elevation: 5,
        margin: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: 220,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Row(
              children: [
                // Left: Image with gradient overlay and extra count indicator.
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      firstImage != null
                          ? Image.network(
                        firstImage,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      )
                          : Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.volunteer_activism, size: 60),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black45, Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                      if (extraImagesCount > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "+$extraImagesCount more",
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Right: Donation info.
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: status == "DONATED"
                                    ? Colors.pink.shade200
                                    : Colors.green.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Text(
                          "Posted by: $ownerName",
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Open the near full-screen Donation Details Dialog.
  void _showDonationDialog({
    required String donationId,
    required String title,
    required String description,
    required String status,
    required List<dynamic> images,
    required String ownerName,
    required String ownerPhone,
    required String ownerAddress,
    required String ownerCity,
    required String ownerProvince,
    required String ownerProfile,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return _DonationDetailsDialog(
          donationId: donationId,
          title: title,
          description: description,
          status: status,
          images: images,
          ownerName: ownerName,
          ownerPhone: ownerPhone,
          ownerAddress: ownerAddress,
          ownerCity: ownerCity,
          ownerProvince: ownerProvince,
          ownerProfile: ownerProfile,
          token: widget.token,
        );
      },
    );
  }
}

///////////////////////////////////////////////////////////////////////////
// Near full-screen Details Dialog with Slideshow and Request Button
class _DonationDetailsDialog extends StatefulWidget {
  final String donationId;
  final String title;
  final String description;
  final String status;
  final List<dynamic> images;
  final String ownerName;
  final String ownerPhone;
  final String ownerAddress;
  final String ownerCity;
  final String ownerProvince;
  final String ownerProfile;
  final String token;
  const _DonationDetailsDialog({
    Key? key,
    required this.donationId,
    required this.title,
    required this.description,
    required this.status,
    required this.images,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerAddress,
    required this.ownerCity,
    required this.ownerProvince,
    required this.ownerProfile,
    required this.token,
  }) : super(key: key);

  @override
  State<_DonationDetailsDialog> createState() => _DonationDetailsDialogState();
}

class _DonationDetailsDialogState extends State<_DonationDetailsDialog> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  bool _isRequesting = false;
  final TextEditingController _messageCtrl = TextEditingController();

  static const String BASE_URL = "http://10.0.2.2:8080";

  @override
  void dispose() {
    _pageController.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  // Function to send a donation request to the backend.
  Future<void> _sendDonationRequest() async {
    setState(() {
      _isRequesting = true;
    });
    try {
      final uri = Uri.parse("$BASE_URL/api/donation-requests");
      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}"
        },
        body: jsonEncode({
          "donationId": widget.donationId,
          "message": _messageCtrl.text.trim(),
        }),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Donation request sent successfully.")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Request failed: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        _isRequesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    return Dialog(
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.teal.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Header with title
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.teal.shade600,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              width: double.infinity,
              child: Text(
                widget.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            // Slideshow section
            Container(
              height: 300,
              color: Colors.black12,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentImageIndex = index);
                },
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final imageUrl = images[index];
                  return Container(
                    alignment: Alignment.center,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  );
                },
              ),
            ),
            if (images.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(images.length, (index) {
                    return Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: _currentImageIndex == index ? Colors.teal : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ),
            // Donation details and owner info
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.status == "DONATED" ? Colors.pink.shade200 : Colors.green.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.status,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.description,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    _buildOwnerSection(),
                    const SizedBox(height: 20),
                    // Request Donation Section
                    if (!_isRequesting)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Request Donation",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _messageCtrl,
                            decoration: const InputDecoration(
                              labelText: "Message (Optional)",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: ElevatedButton(
                              onPressed: _sendDonationRequest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade700,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                              ),
                              child: const Text(
                                "Send Request",
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ),
            // Footer button
            Padding(
              padding: const EdgeInsets.all(14),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                ),
                child: const Text("Close", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.teal.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: widget.ownerProfile.isNotEmpty
                ? NetworkImage(widget.ownerProfile)
                : const AssetImage("images/default_profile.png") as ImageProvider,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.ownerName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                if (widget.ownerPhone.isNotEmpty)
                  Text(
                    "Phone: ${widget.ownerPhone}",
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                const SizedBox(height: 2),
                if (widget.ownerCity.isNotEmpty || widget.ownerProvince.isNotEmpty)
                  Text(
                    "${widget.ownerCity}, ${widget.ownerProvince}",
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                if (widget.ownerAddress.isNotEmpty)
                  Text(
                    widget.ownerAddress,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
