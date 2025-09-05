import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RandomProductSection extends StatefulWidget {
  const RandomProductSection({Key? key}) : super(key: key);

  @override
  _RandomProductSectionState createState() => _RandomProductSectionState();
}

class _RandomProductSectionState extends State<RandomProductSection> {
  late String greeting;
  bool isEnglish = true; // Track whether we're showing English or Chichewa
  
  @override
  void initState() {
    super.initState();
    greeting = getGreeting(isEnglish);
    // Update greeting every 3 seconds
    Future.delayed(const Duration(seconds: 5), _updateGreeting);
  }

  void _updateGreeting() {
    setState(() {
      isEnglish = !isEnglish; // Toggle language between English and Chichewa
      greeting = getGreeting(isEnglish);
    });
    // Call itself every 3 seconds for continuous change
    Future.delayed(const Duration(seconds: 3), _updateGreeting);
  }

  String getGreeting(bool isEnglish) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return isEnglish
          ? 'Good Morning! What are you buying today?'
          : 'Mwadzuka bwanji, akugula chani lero?';
    } else if (hour < 18) {
      return isEnglish
          ? 'Good Afternoon! Buy something nice.'
          : 'Mwasera bwanji, mudya chan lero?';
    } else {
      return isEnglish
          ? 'Good Night! Close the day with buying something.'
          : 'Madzulo abwino mwatigulako lero?';
    }
  }

  Future<List<Map<String, String>>> fetchRandomProducts() async {
    try {
      //random api
      final response = await http.get(Uri.parse('https://weatherapi-com.p.rapidapi.com/alerts.json?q=london'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((product) {
          return {
            'name': product['name'].toString(),
            'image': product['imageUrl'].toString(),
          };
        }).toList();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: const Duration(seconds: 3),
          child: Text(
            greeting,
            key: ValueKey<String>(greeting), // Unique key for animated transition
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 5),
        FutureBuilder<List<Map<String, String>>>(
          future: fetchRandomProducts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Failed to load products',
                  style: TextStyle(color: Colors.red),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'No products available',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            } else {
              final products = snapshot.data!;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Two products per row
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 3 / 4,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 3,
                    child: Column(
                      children: [
                        Image.network(
                          products[index]['image']!,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          products[index]['name']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Colors.black),
                        ),
                      ],
                    ),
                  );
                },
              );
            }
          },
        ),
      ],
    );
  }
}
