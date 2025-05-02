import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'MainScreens/HomePage.dart'; // adjust to your real import

class AddItemPage extends StatefulWidget {
  final String token;
  const AddItemPage({Key? key, required this.token}) : super(key: key);

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  static const String BASE_URL = "http://10.0.2.2:8080";
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<File> _pickedFiles = [];
  List<dynamic> _categories = [];
  int? _selectedCategoryId;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final resp = await http.get(
        Uri.parse("$BASE_URL/api/categories"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json"
        },
      );
      if (resp.statusCode == 200) {
        setState(() => _categories = jsonDecode(resp.body));
      } else {
        setState(() => _errorMessage = "Failed to load categories");
      }
    } catch (e) {
      setState(() => _errorMessage = "Error: $e");
    }
  }

  /// Show bottom‐sheet to pick from camera, gallery, or file
  Future<void> _showImageSourceSheet() async {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take Photo"),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo =
                await _picker.pickImage(source: ImageSource.camera);
                if (photo != null && _pickedFiles.length < 5) {
                  setState(() => _pickedFiles.add(File(photo.path)));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Choose from Gallery"),
              onTap: () async {
                Navigator.pop(context);
                final List<XFile>? images = await _picker.pickMultiImage();
                if (images != null && images.isNotEmpty) {
                  final remaining = 5 - _pickedFiles.length;
                  for (var img in images.take(remaining)) {
                    _pickedFiles.add(File(img.path));
                  }
                  setState(() {});
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text("Browse Files"),
              onTap: () async {
                Navigator.pop(context);
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                  allowMultiple: true,
                );
                if (result != null && result.paths.isNotEmpty) {
                  final remaining = 5 - _pickedFiles.length;
                  for (var path in result.paths.take(remaining)) {
                    if (path != null) _pickedFiles.add(File(path));
                  }
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please select a category")));
      return;
    }
    setState(() => _isLoading = true);

    final itemJson = {
      "title": _titleCtrl.text.trim(),
      "description": _descCtrl.text.trim(),
      "price": double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
      "categoryId": _selectedCategoryId,
    };

    try {
      final uri = Uri.parse("$BASE_URL/api/items/add");
      final req = http.MultipartRequest("POST", uri)
        ..headers["Authorization"] = "Bearer ${widget.token}"
        ..files.add(
          http.MultipartFile.fromString(
            'item',
            jsonEncode(itemJson),
            contentType: MediaType('application', 'json'),
          ),
        );

      for (final file in _pickedFiles) {
        final stream = http.ByteStream(file.openRead());
        final length = await file.length();
        req.files.add(
          http.MultipartFile(
            'files',
            stream,
            length,
            filename: file.path.split('/').last,
          ),
        );
      }

      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);
      setState(() => _isLoading = false);

      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Item added successfully!")),
        );
        _titleCtrl.clear();
        _descCtrl.clear();
        _priceCtrl.clear();
        setState(() {
          _pickedFiles.clear();
          _selectedCategoryId = null;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage(token: widget.token)),
        );
      } else {
        final body = resp.body.isNotEmpty ? resp.body : "{}";
        final msg = jsonDecode(body)["message"] ?? "Item creation failed";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage(token: widget.token)),
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
            padding: const EdgeInsets.all(16),
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
                  DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    decoration: InputDecoration(
                      prefixIcon:
                      const Icon(Icons.category, color: Colors.green),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    hint: const Text("Choose Category"),
                    items: _categories
                        .map<DropdownMenuItem<int>>((cat) {
                      return DropdownMenuItem<int>(
                        value: cat["categoryId"],
                        child: Text(cat["categoryName"]),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCategoryId = val),
                    validator: (val) =>
                    val == null ? "Please select a category" : null,
                  ),
                  const SizedBox(height: 16),

                  // Preview selected images
                  if (_pickedFiles.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _pickedFiles.map((file) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey),
                              image: DecorationImage(
                                image: FileImage(file),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 8),

                  // Launch bottom‐sheet chooser
                  ElevatedButton.icon(
                    onPressed: _showImageSourceSheet,
                    icon:
                    const Icon(Icons.add_photo_alternate, color: Colors.green),
                    label: Text(
                      "Add Images (${_pickedFiles.length}/5)",
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

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "Submit",
                        style:
                        TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController ctrl, {
        int maxLines = 1,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return TextFormField(
      controller: ctrl,
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
