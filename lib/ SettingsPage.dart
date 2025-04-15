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
  File? _selectedImage;
  bool _uploading = false;
  String? _fetchedImageUrl;
  final picker = ImagePicker();
  static const String BASE_URL = "http://10.0.2.2:8080";

  @override
  void initState() {
    super.initState();
    _fetchedImageUrl = widget.currentProfileImage;
    _fetchLatestProfileImage();
  }

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
      print("Error fetching profile image: $e");
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
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
    setState(() {
      _uploading = true;
    });

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
        _fetchLatestProfileImage(); // Refresh after upload
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
      setState(() {
        _uploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider displayImage;
    if (_selectedImage != null) {
      displayImage = FileImage(_selectedImage!);
    } else if (_fetchedImageUrl != null && _fetchedImageUrl!.isNotEmpty) {
      displayImage = NetworkImage(_fetchedImageUrl!);
    } else {
      displayImage = const AssetImage("images/default_profile.png");
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
          ],
        ),
      ),
    );
  }
}
