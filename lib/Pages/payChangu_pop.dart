import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

class PayChanguInlinePopup extends StatefulWidget {
  final String publicKey;
  final double amount;
  final String currency;
  final String callbackUrl;
  final String returnUrl;
  final String email;
  final String name;

  const PayChanguInlinePopup({
    Key? key,
    required this.publicKey,
    required this.amount,
    required this.currency,
    required this.callbackUrl,
    required this.returnUrl,
    required this.email,
    required this.name,
  }) : super(key: key);

  @override
  _PayChanguInlinePopupState createState() => _PayChanguInlinePopupState();
}

class _PayChanguInlinePopupState extends State<PayChanguInlinePopup> {
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();

    // Initialize the WebView controller with required settings
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Error loading page: ${error.description}');
          },
        ),
      );

    // Load the payment HTML
    _loadPaymentPage();
  }

  void _loadPaymentPage() {
    final String paymentPage = '''
      <html>
        <head>
          <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
          <script src="https://in.paychangu.com/js/popup.js"></script>
          <style>
            body, html {
              margin: 0;
              padding: 0;
              height: 100%;
              display: flex;
              align-items: center;
              justify-content: center;
              background-color: #f5f5f5;
            }
            #wrapper {
              width: 90%;
              max-width: 600px;
              background-color: #fff;
              padding: 20px;
              box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
              border-radius: 10px;
              text-align: center;
            }
            button {
              padding: 10px 20px;
              background-color: #4caf50;
              color: white;
              border: none;
              border-radius: 5px;
              font-size: 16px;
              cursor: pointer;
            }
            button:hover {
              background-color: #45a049;
            }
          </style>
        </head>
        <body>
          <div id="wrapper">
            <h2>Complete Your Payment</h2>
            <button type="button" id="pay-now" onClick="makePayment()">Pay Now</button>
          </div>
          <script>
            function makePayment() {
              PaychanguCheckout({
                public_key: "${widget.publicKey}",
                tx_ref: '' + Math.floor((Math.random() * 1000000000) + 1),
                amount: ${widget.amount},
                currency: "${widget.currency}",
                callback_url: "${widget.callbackUrl}",
                return_url: "${widget.returnUrl}",
                customer: {
                  email: "${widget.email}",
                  first_name: "${widget.name}",
                },
                customization: {
                  title: "Hostel Booking",
                  description: "Payment for Hostel Booking",
                },
              });
            }
          </script>
        </body>
      </html>
    ''';

    _webViewController.loadRequest(
      Uri.dataFromString(
        paymentPage,
        mimeType: 'text/html',
        encoding: Encoding.getByName('utf-8'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay with PayChangu'),
        backgroundColor: Colors.green,
      ),
      body: WebViewWidget(controller: _webViewController),
    );
  }
}
