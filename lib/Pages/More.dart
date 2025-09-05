import 'package:flutter/material.dart';
import 'package:vero360_app/Pages/Bike.dart';
import 'package:vero360_app/Pages/customerservice.dart';
import 'package:vero360_app/Pages/transaction.dart';
import 'package:vero360_app/screens/register_screen.dart';

class MorePage extends StatelessWidget {
  const MorePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> subcategories = [
      {'name': 'Social', 'icon': Icons.group},
      {'name': 'Health', 'icon': Icons.health_and_safety},
      {'name': 'Bike', 'icon': Icons.motorcycle},
      {'name': 'Transactions', 'icon': Icons.money},
      {'name': 'Customer Service', 'icon': Icons.contact_support_sharp},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('More Apps'),
        backgroundColor: Colors.orange, // Orange header
      ),
      
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: subcategories.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                String subcategoryName = subcategories[index]['name'];
                if (subcategoryName == 'social') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>  RegisterScreen()),
                  );
                } else if (subcategoryName == 'Health') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BikePage()),
                  );
                } else if (subcategoryName == 'Bike') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BikePage()),
                  );
                } else if (subcategoryName == 'Transactions') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TransactionPage()),
                  );
                } else if (subcategoryName == 'Customer Service') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CustomerServicePage()),
                  );
                }
              },
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.orange, // Orange icon background
                    child: Icon(
                      subcategories[index]['icon'],
                      color: Colors.white, // White icon color
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subcategories[index]['name'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black, // Black text for readability
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
