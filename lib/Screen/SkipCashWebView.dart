import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../Helper/String.dart';
import '../Helper/Constant.dart';
import '../utils/Hive/hive_utils.dart';
import '../Provider/CartProvider.dart';
import '../HELPER/routes.dart';

class SkipCashWebView extends StatefulWidget {
  final String payUrl;
  final String paymentId;
  final Future<void> Function(String message) onSuccess;
  final Function(String error) onError;

  const SkipCashWebView({
    Key? key,
    required this.payUrl,
    required this.paymentId,
    required this.onSuccess,
    required this.onError,
  }) : super(key: key);

  @override
  State<SkipCashWebView> createState() => _SkipCashWebViewState();
}

class _SkipCashWebViewState extends State<SkipCashWebView> {
  late final WebViewController _controller;
  bool _isVerifying = false;
  bool _isWebViewReady = false;

  final String? jwtToken = HiveUtils.getJWT();

  @override
  void initState() {
    super.initState();
    final PlatformWebViewControllerCreationParams params =
        const PlatformWebViewControllerCreationParams();
    _controller = WebViewController.fromPlatformCreationParams(params);

    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            print('Loaded URL: \$url');

            if (!_isVerifying && url.contains('skipcash-success')) {
              final uri = Uri.parse(url);
              final paymentIdFromUrl = uri.queryParameters['id'];
              if (paymentIdFromUrl != null && paymentIdFromUrl.isNotEmpty) {
                _verifyPayment(paymentIdFromUrl);
              } else {
                widget.onError('Missing payment ID in return URL');
              }
            }

            setState(() => _isWebViewReady = true);
          },
          onNavigationRequest: (request) => NavigationDecision.navigate,
          onWebResourceError: (error) {
            widget.onError('WebView error: \${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.payUrl));
  }

  Future<void> _verifyPayment(String paymentId) async {
    if (_isVerifying) return;
    setState(() => _isVerifying = true);

    final url = Uri.parse('\${baseUrl}verify_skipcash_payment');
    print('[SkipCash] Verifying payment using POST: \$url');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer \$jwtToken',
        },
        body: jsonEncode({'payment_id': paymentId}),
      );

      final data = jsonDecode(response.body);
      print('[SkipCash] Verification response: \$data');

      if (response.statusCode == 200 && data['error'] == false) {
        await widget.onSuccess(data['message'] ?? 'Order placed successfully');

        // ✅ Clear cart and navigate to order success
        if (mounted) {
          Provider.of<CartProvider>(context, listen: false).clearCart();

          Navigator.pushNamedAndRemoveUntil(
            context,
            '/order_success',
            (route) => route.isFirst,
          );
        }
      } else {
        widget.onError(data['message'] ?? 'Payment verification failed.');
      }
    } catch (e) {
      widget.onError('Verification failed: \$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SkipCash Payment")),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (!_isWebViewReady)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
