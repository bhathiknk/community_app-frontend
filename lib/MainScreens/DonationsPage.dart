import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/**
 * A page showing all donation items from other users.
 * Main card displays the first image, title, status, and short description.
 * When tapped, a near full-screen dialog opens with a clear slideshow of images,
 * donation details, and owner info (including profile data).
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
      appBar: AppBar(
        title: const Text("All Donations"),
        backgroundColor: Colors.teal.shade600,
      ),
      body: Stack(
        children: [
          // Subtle gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade50, Colors.teal.shade100],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
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
    );
  }

  Widget _buildDonationCard(dynamic donation) {
    final title = donation["title"] ?? "No Title";
    final description = donation["description"] ?? "";
    final images = donation["images"] as List<dynamic>? ?? [];
    final status = donation["status"] ?? "ACTIVE";

    // Owner details
    final ownerName = donation["ownerFullName"] ?? "Unknown";
    final ownerPhone = donation["ownerPhone"] ?? "";
    final ownerAddress = donation["ownerAddress"] ?? "";
    final ownerCity = donation["ownerCity"] ?? "";
    final ownerProvince = donation["ownerProvince"] ?? "";
    final ownerProfile = donation["ownerProfileImage"] ?? ""; // URL

    // Display first image; if multiple then show "+X more" overlay.
    final firstImage = images.isNotEmpty ? images.first : null;
    final extraImagesCount = images.length > 1 ? images.length - 1 : 0;

    return GestureDetector(
      onTap: () {
        _showDonationDialog(
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
        );
      },
      child: Card(
        elevation: 5,
        margin: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Row(
              children: [
                // Left side: Donation image with overlay and extra count indicator.
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
                        width: double.infinity,
                        height: double.infinity,
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
                // Right side: donation information.
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                color: status == "DONATED" ? Colors.pink.shade200 : Colors.green.shade200,
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

  /// Shows a near full-screen dialog with a clear slideshow of images,
  /// donation details, and owner info.
  void _showDonationDialog({
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
        );
      },
    );
  }
}

// -------------------- Full-Screen Dialog with Slideshow -------------------- //

class _DonationDetailsDialog extends StatefulWidget {
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

  const _DonationDetailsDialog({
    Key? key,
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
  }) : super(key: key);

  @override
  State<_DonationDetailsDialog> createState() => _DonationDetailsDialogState();
}

class _DonationDetailsDialogState extends State<_DonationDetailsDialog> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
            // Header with title and status
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
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            // Slideshow section with clear full images
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
                  // Use BoxFit.contain for full clear display
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
            // Dots indicator
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
            // Donation details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status chip
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
                  // Owner Info
                  _buildOwnerSection(),
                ],
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
                child: const Text(
                  "Close",
                  style: TextStyle(fontSize: 16),
                ),
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
          // Owner profile image
          CircleAvatar(
            radius: 30,
            backgroundImage: (widget.ownerProfile.isNotEmpty)
                ? NetworkImage(widget.ownerProfile)
                : const AssetImage("images/default_profile.png") as ImageProvider,
          ),
          const SizedBox(width: 12),
          // Contact Info
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
