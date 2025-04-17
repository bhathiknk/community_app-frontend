import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class MyDonationsPage extends StatefulWidget {
  final String token;
  const MyDonationsPage({Key? key, required this.token}) : super(key: key);

  @override
  State<MyDonationsPage> createState() => _MyDonationsPageState();
}

class _MyDonationsPageState extends State<MyDonationsPage> {
  bool _isLoading = false;
  List<dynamic> _donations = [];
  static const String BASE_URL = "http://10.0.2.2:8080";

  @override
  void initState() {
    super.initState();
    _fetchDonations();
  }

  Future<void> _fetchDonations() async {
    setState(() => _isLoading = true);
    try {
      final resp = await http.get(
        Uri.parse("$BASE_URL/api/donations/my"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() => _donations = data);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Load failed: ${resp.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showViewDialog(dynamic donation) {
    showDialog(
      context: context,
      builder: (context) => _DonationViewDialog(donation: donation),
    );
  }

  void _showEditDialog(dynamic donation) {
    showDialog(
      context: context,
      builder: (context) => _DonationEditDialog(
        donation: donation,
        token: widget.token,
        onUpdateSuccess: _fetchDonations,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB3D1B9),
      appBar: AppBar(
        title: const Text("My Donations"),
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _donations.isEmpty
          ? const Center(child: Text("You have no donations yet."))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _donations.length,
        itemBuilder: (context, index) {
          final d = _donations[index];
          return _buildDonationCard(
            d,
            d["title"] ?? "",
            d["description"] ?? "",
            d["images"] as List<dynamic>? ?? [],
            d["status"] ?? "ACTIVE",
          );
        },
      ),
    );
  }

  Widget _buildDonationCard(dynamic donation, String title, String description,
      List<dynamic> images, String status) {
    return Card(
      color: Colors.white,
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
              // Left image
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    images.isNotEmpty
                        ? Image.network(
                      images.first,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      color: Colors.grey,
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
                  ],
                ),
              ),

              // Right info
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Text(description,
                          style:
                          const TextStyle(fontSize: 14, color: Colors.black54),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: status == "DONATED"
                                ? Colors.pink.shade200
                                : Colors.green.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:
                          Text(status, style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_red_eye),
                            onPressed: () => _showViewDialog(donation),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditDialog(donation),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= VIEW DIALOG ================= //

class _DonationViewDialog extends StatelessWidget {
  final dynamic donation;
  const _DonationViewDialog({Key? key, required this.donation})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = donation["title"] ?? "";
    final description = donation["description"] ?? "";
    final status = donation["status"] ?? "";
    final images = (donation["images"] as List<dynamic>? ?? []);

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
              child: Text("Donation: $title",
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Status: $status",
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(description, style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 12),
                    if (images.isNotEmpty)
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: images.map((imgUrl) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(imgUrl,
                                width: 120, height: 120, fit: BoxFit.cover),
                          );
                        }).toList(),
                      )
                    else
                      const Text("No images"),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                ),
                child: const Text("Close", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= EDIT DIALOG ================= //

class _DonationEditDialog extends StatefulWidget {
  final dynamic donation;
  final String token;
  final VoidCallback onUpdateSuccess;
  const _DonationEditDialog({
    Key? key,
    required this.donation,
    required this.token,
    required this.onUpdateSuccess,
  }) : super(key: key);

  @override
  State<_DonationEditDialog> createState() => _DonationEditDialogState();
}

class _DonationEditDialogState extends State<_DonationEditDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _status = "ACTIVE";

  List<Map<String, dynamic>> _imagesToDisplay = [];
  final List<int> _imageIdsToRemove = [];
  List<XFile> _newImages = [];
  bool _isLoading = false;

  static const String BASE_URL = "http://10.0.2.2:8080";

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = widget.donation["title"] ?? "";
    _descCtrl.text = widget.donation["description"] ?? "";
    _status = widget.donation["status"] ?? "ACTIVE";

    final imageList = widget.donation["imageList"] as List<dynamic>? ?? [];
    for (var imgMap in imageList) {
      _imagesToDisplay.add({
        "imageId": imgMap["imageId"],
        "url": imgMap["url"],
        "remove": false,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
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
              child: const Text("Edit Donation",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextFieldSection(),
                    const SizedBox(height: 16),
                    _buildExistingImagesSection(),
                    const SizedBox(height: 16),
                    _buildAddImagesSection(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _updateDonation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 14),
                    ),
                    child: const Text("Save",
                        style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titleCtrl,
          decoration: InputDecoration(
            labelText: "Title",
            prefixIcon: Icon(Icons.title, color: Colors.teal.shade600),
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: "Description",
            prefixIcon: Icon(Icons.description, color: Colors.teal.shade600),
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),

        /// **FIXED**: include RESERVED so `_status` always finds exactly one match
        DropdownButtonFormField<String>(
          value: _status,
          decoration: InputDecoration(
            labelText: "Status",
            prefixIcon: Icon(Icons.info, color: Colors.teal.shade600),
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: const [
            DropdownMenuItem(value: "ACTIVE", child: Text("ACTIVE")),
            DropdownMenuItem(value: "RESERVED", child: Text("RESERVED")),
            DropdownMenuItem(value: "DONATED", child: Text("DONATED")),
          ],
          onChanged: (val) => setState(() => _status = val ?? "ACTIVE"),
        ),
      ],
    );
  }

  Widget _buildExistingImagesSection() {
    if (_imagesToDisplay.isEmpty) {
      return const Text("No existing images",
          style: TextStyle(color: Colors.grey));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Existing Images",
            style: TextStyle(
                color: Colors.teal.shade800,
                fontWeight: FontWeight.w600,
                fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _imagesToDisplay.map((img) {
            final removed = img["remove"] == true;
            return Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  img["url"],
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      img["remove"] = !removed;
                      if (img["remove"]) {
                        _imageIdsToRemove.add(img["imageId"]);
                      } else {
                        _imageIdsToRemove.remove(img["imageId"]);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: removed ? Colors.red : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close,
                        size: 18, color: removed ? Colors.white : Colors.red),
                  ),
                ),
              ),
            ]);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAddImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _pickNewImages,
          icon: const Icon(Icons.add_a_photo),
          label: const Text("Add Images"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_newImages.isNotEmpty)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(_newImages.length, (index) {
              final file = _newImages[index];
              return Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(file.path),
                      width: 100, height: 100, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _newImages.removeAt(index));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child:
                      const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ]);
            }),
          ),
      ],
    );
  }

  Future<void> _pickNewImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked != null && picked.isNotEmpty) {
      final kept = _newImages.length +
          (_imagesToDisplay.where((img) => img["remove"] == false).length);
      final allowed = 5 - kept;
      if (allowed <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Max 5 images total.")));
        return;
      }
      _newImages.addAll(picked.take(allowed));
      setState(() {});
    }
  }

  Future<void> _updateDonation() async {
    setState(() => _isLoading = true);
    final donationId = widget.donation["donationId"] ?? "";
    final uri = Uri.parse("$BASE_URL/api/donations/$donationId");
    final request = http.MultipartRequest("PUT", uri)
      ..headers["Authorization"] = "Bearer ${widget.token}"
      ..fields.addAll({
        "title": _titleCtrl.text.trim(),
        "description": _descCtrl.text.trim(),
        "status": _status,
      });

    // imageIdsToRemove
    for (final id in _imageIdsToRemove) {
      request.fields["imageIdsToRemove"] = "$id";
    }

    // new files
    for (var file in _newImages) {
      request.files
          .add(await http.MultipartFile.fromPath("files", file.path));
    }

    try {
      final resp = await request.send();
      if (resp.statusCode == 200) {
        Navigator.pop(context);
        widget.onUpdateSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Donation updated successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update failed: ${resp.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }
}
