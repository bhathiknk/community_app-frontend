import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;

class SettingsPage extends StatefulWidget {
  final String token;
  final String? currentProfileImage;

  const SettingsPage({
    Key? key,
    required this.token,
    this.currentProfileImage,
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Image
  File? _selectedImage;
  bool _uploading = false;
  String? _fetchedImageUrl;
  final picker = ImagePicker();

  // Editing logic
  bool _isEditing = false;

  // Profile fields
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();

  static const String BASE_URL = "http://10.0.2.2:8080";

  @override
  void initState() {
    super.initState();
    _fetchedImageUrl = widget.currentProfileImage;
    _fetchAllProfileData();
  }

  // ===== Fetch Profile Data and Image =====
  Future<void> _fetchAllProfileData() async {
    await _fetchUserProfile();
    await _fetchLatestProfileImage();
  }

  // 1) GET user data
  Future<void> _fetchUserProfile() async {
    try {
      final resp = await http.get(
        Uri.parse("$BASE_URL/api/user/profile"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          _fullNameController.text = data["fullName"] ?? "";
          _phoneController.text = data["phone"] ?? "";
          _addressController.text = data["address"] ?? "";
          _cityController.text = data["city"] ?? "";
          _provinceController.text = data["province"] ?? "";
        });
      } else {
        debugPrint("Failed to load profile: ${resp.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching user profile: $e");
    }
  }

  // 2) GET the latest profile image
  Future<void> _fetchLatestProfileImage() async {
    try {
      final response = await http.get(
        Uri.parse("$BASE_URL/getProfileImage"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
        },
      );
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        setState(() {
          _fetchedImageUrl = jsonData["profileImage"];
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile image: $e");
    }
  }

  // ===== Update User Profile =====
  Future<void> _updateUserProfile() async {
    final bodyData = {
      "fullName": _fullNameController.text.trim(),
      "phone": _phoneController.text.trim(),
      "address": _addressController.text.trim(),
      "city": _cityController.text.trim(),
      "province": _provinceController.text.trim(),
    };

    try {
      final resp = await http.put(
        Uri.parse("$BASE_URL/api/user/profile/update"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json"
        },
        body: jsonEncode(bodyData),
      );
      if (resp.statusCode == 200) {
        final updatedData = jsonDecode(resp.body);
        setState(() {
          _fullNameController.text = updatedData["fullName"] ?? "";
          _phoneController.text = updatedData["phone"] ?? "";
          _addressController.text = updatedData["address"] ?? "";
          _cityController.text = updatedData["city"] ?? "";
          _provinceController.text = updatedData["province"] ?? "";
          _isEditing = false; // lock fields
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update profile")),
        );
      }
    } catch (e) {
      debugPrint("Error updating user profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating profile: $e")),
      );
    }
  }

  // ===== Image picking, cropping, uploading =====
  Future<void> _pickImage() async {
    final pickedFile =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _cropImage() async {
    if (_selectedImage == null) return;
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: _selectedImage!.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.green,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioLockEnabled: true,
        ),
      ],
    );
    if (croppedFile != null) {
      setState(() {
        _selectedImage = File(croppedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;
    setState(() => _uploading = true);

    var uri = Uri.parse("$BASE_URL/uploadProfileImage");
    var request = http.MultipartRequest("POST", uri);
    request.headers["Authorization"] = "Bearer ${widget.token}";
    request.files.add(await http.MultipartFile.fromPath("file", _selectedImage!.path));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile image uploaded successfully")),
        );
        _fetchLatestProfileImage();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image upload failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Decide which image to show
    ImageProvider displayImage;
    if (_selectedImage != null) {
      displayImage = FileImage(_selectedImage!);
    } else if (_fetchedImageUrl != null && _fetchedImageUrl!.isNotEmpty) {
      displayImage = NetworkImage(_fetchedImageUrl!);
    } else {
      displayImage = const AssetImage("images/default_profile.png");
    }

    return Scaffold(
      backgroundColor: const Color(0xFFB3D1B9),
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Image + pick icon
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: displayImage,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.green,
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Crop + Upload Buttons
            if (_selectedImage != null)
              ElevatedButton(
                onPressed: _cropImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Crop Image"),
              ),
            const SizedBox(height: 10),
            _uploading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _uploadImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text("Upload Profile Image"),
            ),
            const SizedBox(height: 30),

            // A Card for the user data
            Card(
              color: Colors.white.withOpacity(0.8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _fullNameController,
                      label: "Full Name",
                      isEditable: _isEditing,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _phoneController,
                      label: "Phone",
                      isEditable: _isEditing,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _addressController,
                      label: "Address",
                      isEditable: _isEditing,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _cityController,
                      label: "City",
                      isEditable: _isEditing,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _provinceController,
                      label: "Province",
                      isEditable: _isEditing,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Edit / Save Buttons
            if (!_isEditing)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Edit Data"),
              )
            else
              ElevatedButton(
                onPressed: _updateUserProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Save Data"),
              ),
          ],
        ),
      ),
    );
  }

  // Helper widget for text fields with uniform styling
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool isEditable,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: !isEditable,
      maxLines: label == "Address" ? 2 : 1, // address can be multiline
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: Colors.black87),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
