import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// function to initiate the payment request to the payChangu Api
Future<void> initiatePayment({
  required String apiKey,
  required String phoneNumber,
  required double amount,
  required String currency,
  required String provider, // AirtelMoney, Mpamba
}) async {

  // setting up api end point where the payment request is sent
  const String url = "https://api.paychangu.com/v1/create-payment";

  // sending the HTTP request

  final response = await http.post(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    },
    //encodes parameters as JSON
    body: jsonEncode({
      "amount": amount,
      "currency": currency, // e.g., MWK
      "phone_number": phoneNumber,
      "provider": provider, // e.g., AirtelMoney
      "description": "Payment for order #12345",
    }),
  );
// handling api response
// check if request is successful
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final transactionId = data['transaction_id'];
    final paymentUrl = data['payment_url']; // Assuming the response includes a payment URL

    print('Payment initiated successfully, transaction ID: $transactionId');

    // Check if payment URL is available
    if (paymentUrl != null) {
      // Navigate to the payment page (WebView)
      print('Redirecting to payment URL: $paymentUrl');
      // Use a WebView to load the payment URL
      // You can implement the WebView here or pass the URL to the page where it's implemented.
    } else {
      print('No payment URL provided. Please check your API response.');
    }
  } else {
    print('Failed to initiate payment: ${response.body}');
  }
}

class CheckoutPage extends StatelessWidget {
  final TextEditingController phoneController = TextEditingController();
  final double totalAmount = 500.0; // Example amount

  CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                hintText: "Enter your phone number",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Initiate payment when the button is pressed
                await initiatePayment(
                  apiKey: 'PUB-TEST-uvvnO504OZQbxOw8jwpUggL63mkSPNsM',
                  phoneNumber: phoneController.text,
                  amount: totalAmount,
                  currency: 'MWK',
                  provider: 'AirtelMoney', // Or 'Mpamba'
                );
              },
              child: const Text('Pay Now'),
            ),
          ],
        ),
      ),
    );
  }
}