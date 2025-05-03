import 'package:flutter/material.dart';

import 'AddItemPage.dart';
import 'DonateItemAdd.dart';
import 'DonationRequest.dart';
import 'MyDonateItems.dart';
import 'MyItemsPage.dart';
import 'TradeItemRequestPage.dart';

class CustomTabSelector extends StatefulWidget {
  final String token;
  const CustomTabSelector({Key? key, required this.token}) : super(key: key);

  @override
  State<CustomTabSelector> createState() => _CustomTabSelectorState();
}

class _CustomTabSelectorState extends State<CustomTabSelector> {
  int _selected = 0;
  final _tabs = ['Trade', 'Donations'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // pill bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 2),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final sel = _selected == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selected = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? Colors.teal : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Text(
                        _tabs[i],
                        style: TextStyle(
                          color: sel ? Colors.white : Colors.teal,
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

        // content
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _selected == 0 ? _tradeTab() : _donationTab(),
          ),
        ),
      ],
    );
  }

  /* ----- tabs ----- */

  Widget _tradeTab() => _grid([
    _action("Add Item", Icons.add_box,
            () => _push(AddItemPage(token: widget.token))),
    _action("My Items", Icons.inventory,
            () => _push(MyItemsPage(token: widget.token))),
    _action("Trade Request", Icons.swap_horiz,
            () => _push(TradeItemRequestPage(token: widget.token))),
  ]);

  Widget _donationTab() => _grid([
    _action("Add Donation", Icons.volunteer_activism,
            () => _push(DonateItemAddPage(token: widget.token))),
    _action("My Donations", Icons.card_giftcard,
            () => _push(MyDonationsPage(token: widget.token))),
    _action("Donation Request", Icons.redeem,
            () => _push(DonationRequestPage(token: widget.token))),
  ]);

  /* ----- grid & buttons ----- */

  Widget _grid(List<Widget> buttons) => GridView.count(
    crossAxisCount: 3,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 1,
    padding: const EdgeInsets.all(6),
    physics: const BouncingScrollPhysics(),
    children: buttons,
  );

  Widget _action(String title, IconData icon, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Center(
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Colors.teal),
                  child: Icon(icon, size: 25, color: Colors.white),
                ),
                const SizedBox(height: 5),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87)),
              ],
            ),
          ),
        ),
      );

  void _push(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}
