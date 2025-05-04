import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';

import 'MainScreens/HomePage.dart';

class MyItemsPage extends StatefulWidget {
  final String token;
  const MyItemsPage({Key? key, required this.token}) : super(key: key);

  @override
  State<MyItemsPage> createState() => _MyItemsPageState();
}

class _MyItemsPageState extends State<MyItemsPage> {
  static const BASE = "http://10.0.2.2:8080";
  bool _loading = false;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    final resp = await http.get(
      Uri.parse("$BASE/api/items/my"),
      headers: {
        "Authorization": "Bearer ${widget.token}",
        "Content-Type": "application/json",
      },
    );
    if (resp.statusCode == 200) {
      setState(() => _items = jsonDecode(resp.body));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(jsonDecode(resp.body)["message"] ?? "Error")),
      );
    }
    setState(() => _loading = false);
  }

  Future<void> _deleteItem(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Item?", style: TextStyle(color: Colors.black87)),
        content: const Text(
          "This will remove your item and all its images.",
          style: TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );
    if (ok != true) return;
    final resp = await http.delete(
      Uri.parse("$BASE/api/items/$id"),
      headers: {"Authorization": "Bearer ${widget.token}"},
    );
    if (resp.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Deleted"), backgroundColor: Colors.redAccent),
      );
      _loadItems();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(jsonDecode(resp.body)["message"] ?? "Error")),
      );
    }
  }

  Future<void> _showEditSheet(dynamic item) async {
    final titleCtrl = TextEditingController(text: item["title"]);
    final descCtrl  = TextEditingController(text: item["description"]);
    final priceCtrl = TextEditingController(text: item["price"]?.toString());

    final rawList = item["imageList"] as List<dynamic>? ?? [];
    final rawUrls = (item["images"] as List<dynamic>?)?.cast<String>() ?? [];

    final existingImages = <Map<String, dynamic>>[];
    for (var i = 0; i < rawUrls.length; i++) {
      existingImages.add({
        "id": i < rawList.length ? rawList[i]["imageId"] as int : null,
        "url": rawUrls[i],
      });
    }

    final toRemove = <int>[];
    final toAdd    = <XFile>[];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
          ),
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: StatefulBuilder(
            builder: (context, setSt) {
              final currentCount = existingImages.length + toAdd.length;
              final remaining    = 5 - currentCount;

              InputDecoration _inputDecoration(String label) => InputDecoration(
                labelText: label,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              );

              return SingleChildScrollView(
                controller: scroll,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text("Edit Item",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal[800])),
                    const SizedBox(height: 24),

                    // Title Field
                    TextField(
                      controller: titleCtrl,
                      decoration: _inputDecoration("Title"),
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),

                    // Description Field (expanded height)
                    TextField(
                      controller: descCtrl,
                      decoration: _inputDecoration("Description"),
                      style: TextStyle(fontSize: 16),
                      minLines: 4,
                      maxLines: 8,
                    ),
                    const SizedBox(height: 16),

                    // Price Field
                    TextField(
                      controller: priceCtrl,
                      decoration: _inputDecoration("Price"),
                      style: TextStyle(fontSize: 16),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),

                    Text("Images", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text("You can add $remaining more image${remaining == 1 ? '' : 's'}",
                        style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (var idx = 0; idx < existingImages.length; idx++)
                          _buildThumbnail(existingImages[idx]["url"], onRemove: () {
                            setSt(() {
                              final id = existingImages[idx]["id"] as int?;
                              if (id != null) toRemove.add(id);
                              existingImages.removeAt(idx);
                            });
                          }),
                        for (var idx = 0; idx < toAdd.length; idx++)
                          _buildThumbnail(File(toAdd[idx].path).path, isFile: true, onRemove: () {
                            setSt(() => toAdd.removeAt(idx));
                          }),
                        GestureDetector(
                          onTap: () async {
                            if (remaining <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Max 5 images"), backgroundColor: Colors.orangeAccent),
                              );
                              return;
                            }
                            final pics = await ImagePicker().pickMultiImage();
                            if (pics != null && pics.isNotEmpty) {
                              setSt(() => toAdd.addAll(pics.take(remaining)));
                            }
                          },
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.teal.shade200),
                            ),
                            child: Icon(Icons.add_a_photo, color: Colors.teal.shade400),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text("Cancel", style: TextStyle(color: Colors.black87, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal[700],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () async {
                              final uri = Uri.parse("$BASE/api/items/${item["itemId"]}");
                              final req = http.MultipartRequest("PUT", uri)
                                ..headers["Authorization"] = "Bearer ${widget.token}"
                                ..fields["item"] = jsonEncode({
                                  "title": titleCtrl.text,
                                  "description": descCtrl.text,
                                  "price": double.tryParse(priceCtrl.text),
                                  "categoryId": item["categoryId"]
                                });
                              if (toRemove.isNotEmpty) {
                                req.fields["imageIdsToRemove"] = toRemove.join(",");
                              }
                              for (var f in toAdd) {
                                req.files.add(await http.MultipartFile.fromPath("files", f.path));
                              }
                              final resp = await req.send();
                              if (resp.statusCode == 200) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Updated successfully"), backgroundColor: Colors.green),
                                );
                                _loadItems();
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Update failed"), backgroundColor: Colors.red),
                                );
                              }
                            },
                            child: const Text(
                              "Save Changes",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),

                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(String path, {required VoidCallback onRemove, bool isFile = false}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 80,
            height: 80,
            color: Colors.grey[100],
            child: isFile
                ? Image.file(File(path), fit: BoxFit.cover)
                : Image.network(path, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Material(
            color: Colors.redAccent,
            shape: CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: CircleBorder(),
              onTap: onRemove,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
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
          backgroundColor: Colors.white,
          title: const Text("My Items"),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _items.length,
          itemBuilder: (_, i) {
            final it     = _items[i];
            final images = List<String>.from(it["images"] ?? []);
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 400),
              builder: (ctx, v, child) => Opacity(opacity: v, child: child),
              child: Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (images.isNotEmpty)
                      CarouselSlider(
                        items: images
                            .map((u) => ClipRRect(
                          borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Container(
                            color: Colors.white,
                            child: Image.network(
                              u,
                              fit: BoxFit.contain,
                              width: double.infinity,
                            ),
                          ),
                        ))
                            .toList(),
                        options: CarouselOptions(
                          height: 240,
                          viewportFraction: 0.9,
                          enlargeCenterPage: true,
                          autoPlay: true,
                        ),
                      )
                    else
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: const Center(
                            child: Text("No image", style: TextStyle(color: Colors.grey))),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(it["title"] ?? "",
                                    style: TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text("Rs. ${it["price"]}",
                                    style: TextStyle(color: Colors.grey[700])),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.teal[700]),
                                onPressed: () => _showEditSheet(it),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red.shade400),
                                onPressed: () => _deleteItem(it["itemId"]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
