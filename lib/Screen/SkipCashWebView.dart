import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../app/routes.dart';
import '../HELPER/Constant.dart';
import '../Provider/CartProvider.dart';
import '../utils/Hive/hive_utils.dart';

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
  bool _isWebReady  = false;
  bool _paymentDone = false;

  final String? _jwt = HiveUtils.getJWT();

  @override
  void initState() {
    super.initState();

    final params = const PlatformWebViewControllerCreationParams();
    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (req) {
            final url = req.url;
            // Intercept the success‐URL
            if (url.contains('skipcash-success')) {
              final pid = Uri.parse(url).queryParameters['id'];
              if (pid != null && pid.isNotEmpty) {
                _verifyPayment(pid);
              } else {
                // you can still log this, but skip the popup:
                debugPrint('Missing payment ID in return URL');
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isWebReady = true);
          },
          onWebResourceError: (err) {
            // Fully suppress any "WebView error" popups:
            // (we do nothing here)
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.payUrl));
  }

  Future<void> _verifyPayment(String paymentId) async {
    if (_isVerifying) return;
    setState(() => _isVerifying = true);

    final url = Uri.parse('${baseUrl}verify_skipcash_payment');
    debugPrint('[SkipCash] POST verify ⇒ $url');

    try {
      final res = await http.post(
        url,
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $_jwt',
        },
        body: jsonEncode({'payment_id': paymentId}),
      );

      final data = jsonDecode(res.body);
      debugPrint('[SkipCash] Verify response ⇒ $data');

      if (res.statusCode == 200 && data['error'] == false) {
        _paymentDone = true;

        // notify checkout sheet
        await widget.onSuccess(data['message'] ?? 'Order placed');

        // clear local cart
        if (mounted) context.read<CartProvider>().clearCart();

        // close this WebView
        if (mounted) Navigator.of(context).pop();

        // push success screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context, rootNavigator: true)
              .pushNamedAndRemoveUntil(
                Routers.orderSuccessScreen,
                (route) => route.isFirst,
              );
        });
      } else {
        // you can choose to log or ignore
        debugPrint('Payment verification failed: ${data['message']}');
      }
    } catch (e) {
      // likewise, just log
      debugPrint('Verification failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SkipCash Payment')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (!_isWebReady)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
