import 'package:flutter/material.dart';

class MessagePage extends StatelessWidget {
  final List<Map<String, String>> messages = [
    {
      'title': 'Order Shipped',
      'subtitle': 'Your order #12345 has been shipped!',
      'date': '1/7/2025',
      'status': 'shipped',
    },
    {
      'title': 'Order Delivered',
      'subtitle': 'Your order #67890 was delivered.',
      'date': '12/25/2024',
      'status': 'delivered',
    },
    {
      'title': 'Payment Received',
      'subtitle': 'We have received your payment for order #98765.',
      'date': '12/20/2024',
      'status': 'payment',
    },
    {
      'title': 'Order Placed',
      'subtitle': 'Your order #54321 has been successfully placed!',
      'date': '12/15/2024',
      'status': 'order',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messenger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Settings action
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Notification Categories
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCategoryButton(Icons.shopping_cart, 'Orders'),
                _buildCategoryButton(Icons.notifications, 'Notification', badge: 20),
                _buildCategoryButton(Icons.more_horiz, 'Other'),
              ],
            ),
          ),
          const Divider(height: 1),
          // Messages List
          Expanded(
            child: ListView.separated(
              itemCount: messages.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final message = messages[index];
                return ListTile(
                  leading: _buildStatusIcon(message['status']!),
                  title: Text(
                    message['title']!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(message['subtitle']!),
                  trailing: Text(
                    message['date']!,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  onTap: () {
                    // Action for message tap
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(IconData icon, String label, {int badge = 0}) {
    return Column(
      children: [
        Stack(
          children: [
            Icon(icon, size: 30),
            if (badge > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildStatusIcon(String status) {
    switch (status) {
      case 'shipped':
        return const Icon(Icons.local_shipping, color: Colors.blue);
      case 'delivered':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'payment':
        return const Icon(Icons.attach_money, color: Colors.orange);
      case 'order':
        return const Icon(Icons.receipt, color: Colors.purple);
      default:
        return const Icon(Icons.info, color: Colors.grey);
    }
  }
}
