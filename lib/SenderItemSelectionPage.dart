import 'package:flutter/material.dart';

class SenderItemSelectionPage extends StatefulWidget {
  final List<dynamic> senderItems;
  const SenderItemSelectionPage({Key? key, required this.senderItems}) : super(key: key);

  @override
  State<SenderItemSelectionPage> createState() => _SenderItemSelectionPageState();
}

class _SenderItemSelectionPageState extends State<SenderItemSelectionPage> {
  String? selectedItemId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background.
      appBar: AppBar(
        title: const Text("Select Sender's Item"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          itemCount: widget.senderItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Two items per row.
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.7,
          ),
          itemBuilder: (ctx, index) {
            final item = widget.senderItems[index];
            final itemId = item["itemId"] ?? "";
            final title = item["title"] ?? "";
            final description = item["description"] ?? "";
            final price = item["price"]?.toString() ?? "0.0";
            final images = item["images"] as List<dynamic>? ?? [];
            final imageUrl = images.isNotEmpty ? images[0] : null;
            final isSelected = selectedItemId == itemId;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedItemId = itemId;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Colors.green : Colors.grey.shade300,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display item image.
                        if (imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              imageUrl,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, e, stack) =>
                              const Icon(Icons.error),
                            ),
                          )
                        else
                          Container(
                            height: 150,
                            width: double.infinity,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image, size: 40),
                          ),
                        const SizedBox(height: 4),
                        // Item title.
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // Item description.
                        Text(
                          description,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // Price.
                        Text(
                          "\$$price",
                          style: const TextStyle(fontSize: 12, color: Colors.blueAccent),
                        ),
                      ],
                    ),
                    // Overlay "eye" icon at top-right.
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () {
                          _showItemDetailsPopup(item);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.remove_red_eye,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {
            if (selectedItemId == null || selectedItemId!.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please select an item first.")),
              );
              return;
            }
            Navigator.pop(context, selectedItemId);
          },
          child: const Text(
            "Approve",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }

  /// Show a fixed–size popup with full details about an item, including an image slider.
  void _showItemDetailsPopup(dynamic item) {
    final title = item["title"] ?? "";
    final description = item["description"] ?? "";
    final price = item["price"]?.toString() ?? "0.0";
    final images = item["images"] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: 500,
            child: Column(
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                // Image slider showing all images.
                Container(
                  height: 150,
                  child: images.isNotEmpty
                      ? PageView.builder(
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      final imageUrl = images[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, error, stackTrace) =>
                            const Icon(Icons.error),
                          ),
                        ),
                      );
                    },
                  )
                      : Container(
                    height: 150,
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.image, size: 50)),
                  ),
                ),
                // Price and description details.
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Price: \$$price", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(description, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                // Close button.
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Close", style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
