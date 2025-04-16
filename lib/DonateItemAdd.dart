import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class DonateItemAddPage extends StatefulWidget {
  final String token;
  const DonateItemAddPage({Key? key, required this.token}) : super(key: key);

  @override
  _DonateItemAddPageState createState() => _DonateItemAddPageState();
}

class _DonateItemAddPageState extends State<DonateItemAddPage> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  List<XFile> _images = [];
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  static const String BASE_URL = "http://10.0.2.2:8080";

  Future<void> _pickImages() async {
    try {
      final picked = await _picker.pickMultiImage();
      if (picked != null && picked.isNotEmpty) {
        setState(() {
          // If user tries to pick more than 5, we can limit here or in the backend
          if (picked.length + _images.length > 5) {
            final allowed = 5 - _images.length;
            _images.addAll(picked.take(allowed));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("You can only upload up to 5 images.")),
            );
          } else {
            _images.addAll(picked);
          }
        });
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
  }

  Future<void> _addDonation() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title is required")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse("$BASE_URL/api/donations/add");
      final request = http.MultipartRequest("POST", uri);
      request.headers["Authorization"] = "Bearer ${widget.token}";


      // Donation JSON data
      request.fields["title"] = _titleCtrl.text.trim();
      request.fields["description"] = _descCtrl.text.trim();


      // Add images (if any)
      for (int i = 0; i < _images.length; i++) {
        final imageFile = await http.MultipartFile.fromPath("files", _images[i].path);
        request.files.add(imageFile);
      }

      final response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Donation added successfully!")),
        );
        Navigator.pop(context); // go back to previous screen
      } else if (response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Not authorized (403). Please log in.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${response.statusCode}")),
        );
      }
    } catch (e) {
      debugPrint("Error adding donation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFB3D1B9),
      appBar: AppBar(
        title: const Text("Add Donation"),
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Fancy card for input fields
                  Card(
                    elevation: 3,
                    color: Colors.white.withOpacity(0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            "Donation Details",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _titleCtrl,
                            decoration: InputDecoration(
                              labelText: "Title",
                              prefixIcon: Icon(Icons.title),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _descCtrl,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: "Description",
                              prefixIcon: Icon(Icons.description),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Images section
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Donation Images (up to 5)",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickImages,
                              icon: const Icon(Icons.add_a_photo),
                              label: const Text("Select Images"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_images.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(_images.length, (index) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_images[index].path),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              );
                            }),
                          )
                        else
                          const Text(
                            "No images selected",
                            style: TextStyle(color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Submit Button
                  ElevatedButton.icon(
                    onPressed: _addDonation,
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text("Submit Donation"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white, // Ensures white text and icon
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  )

                ],
              ),
            ),
        ],
      ),
    );
  }
}
