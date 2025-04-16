import 'package:flutter/material.dart';

import 'AddItemPage.dart';
import 'DonateItemAdd.dart';
import 'DonationRequest.dart';
import 'MyDonateItems.dart';
import 'MyItemsPage.dart';
import 'TradeItemRequestPage.dart';

class CustomTabSelector extends StatefulWidget {
  final String token;
  final String currentUserId;

  const CustomTabSelector({
    Key? key,
    required this.token,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<CustomTabSelector> createState() => _CustomTabSelectorState();
}

class _CustomTabSelectorState extends State<CustomTabSelector> {
  int _selectedIndex = 0;

  final List<String> _tabs = ['Trade', 'Donations'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Pill-shaped tab bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 2),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: List.generate(_tabs.length, (index) {
              final isSelected = _selectedIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedIndex = index);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.teal : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Text(
                        _tabs[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        // Tab content
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _selectedIndex == 0
                ? _buildTradeTab()
                : _buildDonationsTab(),
          ),
        ),
      ],
    );
  }

  Widget _buildTradeTab() {
    return _buildGrid([
      _modernActionButton("Add Item", Icons.add_box, onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddItemPage(token: widget.token)),
        );
      }),
      _modernActionButton("My Items", Icons.inventory, onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MyItemsPage(token: widget.token)),
        );
      }),
      _modernActionButton("Trade Request", Icons.swap_horiz, onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TradeItemRequestPage(
              token: widget.token,
              currentUserId: widget.currentUserId,
            ),
          ),
        );
      }),
    ]);
  }

  Widget _buildDonationsTab() {
    return _buildGrid([
      _modernActionButton("Add Donation", Icons.volunteer_activism, onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DonateItemAddPage(token: widget.token)),
        );
      }),
      _modernActionButton("My Donations", Icons.card_giftcard, onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MyDonationsPage(token: widget.token)),
        );
      }),
      _modernActionButton("Donation Request", Icons.redeem, onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DonationRequestPage(token: widget.token)),
        );
      }),
    ]);
  }

  Widget _buildGrid(List<Widget> buttons) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.0, // square layout
      padding: const EdgeInsets.all(6),
      children: buttons,
    );
  }


  Widget _modernActionButton(String title, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Container(
          width: 90, // Smaller width
          height: 90, // Smaller height (square shape)
          decoration: BoxDecoration(
              color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Smaller icon in circle
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.teal,
                ),
                child: Icon(icon, size: 25, color: Colors.white),
              ),
              const SizedBox(height: 5),
              // Label
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
