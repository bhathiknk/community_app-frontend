import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'MainScreens/HomePage.dart';

class DonationCompletePage extends StatefulWidget {
  final String token;
  final String requestId;

  const DonationCompletePage({
    Key? key,
    required this.token,
    required this.requestId,
  }) : super(key: key);

  @override
  State<DonationCompletePage> createState() => _DonationCompletePageState();
}

class _DonationCompletePageState extends State<DonationCompletePage> {
  static const _baseUrl = 'http://10.0.2.2:8080';
  bool _loading = true;
  bool _submitting = false;
  String _error = '';
  Map<String, dynamic>? _info;

  int _rating = 0;
  final TextEditingController _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCompleteInfo();
  }

  Future<void> _fetchCompleteInfo() async {
    setState(() => _loading = true);
    try {
      final resp = await http.get(
        Uri.parse('$_baseUrl/api/donation-requests/complete/${widget.requestId}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );
      if (resp.statusCode == 200) {
        _info = jsonDecode(resp.body);
      } else {
        _error = 'Failed to load details: ${resp.statusCode}';
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }
    setState(() => _submitting = true);
    final body = jsonEncode({
      'donationRequestId': widget.requestId,
      'score': _rating,
      'comment': _commentCtrl.text.trim(),
    });
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/ratings'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: body,
      );
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(token: widget.token),
          ),
              (route) => false,
        );
      } else {
        final msg = jsonDecode(resp.body)['message'] ?? 'Submission failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  Widget _buildStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final idx = i + 1;
        return IconButton(
          icon: Icon(
            idx <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
            size: 34,
            color: Colors.amber.shade600,
          ),
          onPressed: () => setState(() => _rating = idx),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: const Text('Donation Completion'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal.shade700,
        elevation: 1,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
          : _info == null
          ? const Center(child: Text('No data'))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Material(
              elevation: 4,
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage: (_info!['donorProfileImage'] as String)
                          .isNotEmpty
                          ? NetworkImage(_info!['donorProfileImage'])
                          : null,
                      child: (_info!['donorProfileImage'] as String).isEmpty
                          ? const Icon(Icons.person, size: 36)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _info!['donorFullName'] ?? '',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(_info!['donorEmail'] ?? '',
                              style: const TextStyle(color: Colors.black54)),
                          Text(_info!['donorPhone'] ?? '',
                              style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Rate your experience',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildStars(),
            const SizedBox(height: 16),
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Optional comment',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send_rounded, size: 20),
                onPressed: _submitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                label: _submitting
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
                    : const Text('Submit Rating'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
