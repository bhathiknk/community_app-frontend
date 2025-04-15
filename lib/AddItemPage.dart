import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

import 'MainScreens/HomePage.dart'; // Update with your actual path

class AddItemPage extends StatefulWidget {
  final String token;
  const AddItemPage({Key? key, required this.token}) : super(key: key);

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  static const String BASE_URL = "http://10.0.2.2:8080";
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _pickedImages = [];

  List<dynamic> _categories = [];
  int? _selectedCategoryId;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  // Fetch categories with JWT
  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse("$BASE_URL/api/categories"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _categories = data;
        });
      } else {
        setState(() => _errorMessage = "Failed to load categories");
      }
    } catch (e) {
      setState(() => _errorMessage = "Error: $e");
    }
  }

  // Pick up to 5 images
  Future<void> _pickImage() async {
    if (_pickedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maximum 5 images allowed.")),
      );
      return;
    }
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _pickedImages.add(image));
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a category")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Build JSON for item
    final itemJson = {
      "title": _titleCtrl.text.trim(),
      "description": _descCtrl.text.trim(),
      "price": double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
      "categoryId": _selectedCategoryId,
    };

    try {
      final uri = Uri.parse("$BASE_URL/api/items/add");
      final request = http.MultipartRequest("POST", uri)
        ..headers["Authorization"] = "Bearer ${widget.token}"
      // The 'item' part is JSON, we use fromString with contentType=application/json
        ..files.add(
          http.MultipartFile.fromString(
            'item',
            jsonEncode(itemJson),
            contentType: MediaType('application', 'json'),
          ),
        );

      // Attach images
      for (final img in _pickedImages) {
        final file = File(img.path);
        final stream = http.ByteStream(file.openRead());
        final length = await file.length();
        request.files.add(
          http.MultipartFile(
            'files',
            stream,
            length,
            filename: file.path.split('/').last,
          ),
        );
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        // Successfully created
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Item added successfully!")),
        );
        // Clear form
        _titleCtrl.clear();
        _descCtrl.clear();
        _priceCtrl.clear();
        _pickedImages.clear();
        setState(() => _selectedCategoryId = null);
        // Navigate back to HomePage instead of closing the app
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (context) => HomePage(token: widget.token),
        ));
      } else {
        final body = response.body.isNotEmpty ? response.body : "{}";
        final msg = jsonDecode(body)["message"] ?? "Item creation failed";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap with WillPopScope to override system back button
    return WillPopScope(
      onWillPop: () async {
        // When back is pressed, navigate to HomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(token: widget.token)),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFB3D1B9),
        appBar: AppBar(
          title: const Text("Add New Item"),
          backgroundColor: Colors.white,
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: const Color(0xFFB3D1B9),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text(
                        "Add Item Details",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField("Title", _titleCtrl),
                      const SizedBox(height: 16),
                      _buildTextField("Description", _descCtrl, maxLines: 3),
                      const SizedBox(height: 16),
                      _buildTextField("Price", _priceCtrl,
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      // Category Dropdown
                      DropdownButtonFormField<int>(
                        value: _selectedCategoryId,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.category, color: Colors.green),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        hint: const Text("Choose Category"),
                        items: _categories.map<DropdownMenuItem<int>>((cat) {
                          return DropdownMenuItem<int>(
                            value: cat["categoryId"],
                            child: Text(cat["categoryName"]),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedCategoryId = val);
                        },
                        validator: (val) =>
                        val == null ? "Please select a category" : null,
                      ),
                      const SizedBox(height: 16),
                      // Image Previews
                      if (_pickedImages.isNotEmpty)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _pickedImages.map((xfile) {
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey),
                                  image: DecorationImage(
                                    image: FileImage(File(xfile.path)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Button: Add image
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo, color: Colors.green),
                        label: Text(
                          "Add Image (${_pickedImages.length}/5)",
                          style: const TextStyle(color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveItem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            "Submit",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        int maxLines = 1,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (val) => val == null || val.isEmpty ? "Enter $label" : null,
    );
  }
}
