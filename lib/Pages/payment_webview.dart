import 'package:flutter/foundation.dart'; // For defaultTargetPlatform
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart'; // Core WebView package
import 'package:webview_flutter_android/webview_flutter_android.dart'; // Android-specific configuration
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart'; // iOS-specific configuration
import 'package:webview_windows/webview_windows.dart'; // Windows-specific configuration

class PaymentWebView extends StatefulWidget {
  final String checkoutUrl;

  const PaymentWebView({Key? key, required this.checkoutUrl}) : super(key: key);

  @override
  _PaymentWebViewState createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  WebViewController? _webViewController; // For Android & iOS
  WebviewController? _windowsWebViewController; // For Windows
  bool isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();

    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      // Mobile Configuration (Android & iOS)
      final params = defaultTargetPlatform == TargetPlatform.android
          ? AndroidWebViewControllerCreationParams()
          : WebKitWebViewControllerCreationParams(
              allowsInlineMediaPlayback: true,
              mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
            );

      _webViewController = WebViewController.fromPlatformCreationParams(params);
      _setupWebView();
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      // Windows Configuration
      _windowsWebViewController = WebviewController()
        ..initialize().then((_) {
          _windowsWebViewController?.loadUrl(widget.checkoutUrl);
          setState(() {
            isLoading = false;
          });
        });
    } else {
      throw UnsupportedError('Unsupported platform: $defaultTargetPlatform');
    }
  }

  void _setupWebView() {
    _webViewController?.setJavaScriptMode(JavaScriptMode.unrestricted);
    _webViewController?.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          setState(() {
            isLoading = progress < 100;
          });
        },
        onPageStarted: (String url) {
          setState(() {
            isLoading = true;
          });
        },
        onPageFinished: (String url) {
          setState(() {
            isLoading = false;
          });
        },
        onNavigationRequest: (NavigationRequest request) {
          print("Navigating to: ${request.url}");
          
          // Detect PayChangu transaction status
          if (request.url.contains('payment-success')) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment successful!')),
            );
            return NavigationDecision.prevent;
          } else if (request.url.contains('payment-failed')) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment failed. Please try again.')),
            );
            return NavigationDecision.prevent;
          }

          return NavigationDecision.navigate;
        },
      ),
    );

    _webViewController?.loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Payment')),
      body: Stack(
        children: [
          defaultTargetPlatform == TargetPlatform.windows
              ? _windowsWebViewController != null
                  ? Webview(_windowsWebViewController!)
                  : const Center(child: CircularProgressIndicator())
              : WebViewWidget(controller: _webViewController!), // Mobile WebView
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
