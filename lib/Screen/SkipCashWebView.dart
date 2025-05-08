import 'dart:convert';
import 'dart:io';

import 'package:customer/app/routes.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../Helper/routes.dart';
import '../HELPER/Constant.dart';
import '../HELPER/routes.dart';
import '../Helper/String.dart';
import '../Provider/CartProvider.dart';
import '../utils/Hive/hive_utils.dart';

class SkipCashWebView extends StatefulWidget {
  final String payUrl;
  final String paymentId;                                   // ← kept for logging
  final Future<void> Function(String message) onSuccess;    // callback to Checkout
  final Function(String error) onError;                     // callback to Checkout

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

  bool _isVerifying   = false;   // block double-verify
  bool _isWebReady    = false;   // show loader until first page done
  bool _paymentDone   = false;   // ignore late Web-resource errors

  final String? _jwt = HiveUtils.getJWT();

  @override
  void initState() {
    super.initState();

    final params   = const PlatformWebViewControllerCreationParams();
    _controller    = WebViewController.fromPlatformCreationParams(params);

    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            debugPrint('[SkipCash] Loaded ⇒ $url');

            if (!_isVerifying && url.contains('skipcash-success')) {
              final uri = Uri.parse(url);
              final pid = uri.queryParameters['id'];
              if (pid != null && pid.isNotEmpty) {
                _verifyPayment(pid);
              } else {
                widget.onError('Missing payment ID in return URL');
              }
            }
            if (mounted) setState(() => _isWebReady = true);
          },
          onNavigationRequest: (request) => NavigationDecision.navigate,
          onWebResourceError: (err) {
            if (_paymentDone) return; // ignore favicon / late errors
            widget.onError('WebView error: ${err.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.payUrl));
  }

  /* ─────────────────────────────────────────────────────────────── */
  /*  Verify with backend                                            */
  /* ─────────────────────────────────────────────────────────────── */
  Future<void> _verifyPayment(String paymentId) async {
    if (_isVerifying) return;
    setState(() => _isVerifying = true);

    final url = Uri.parse('${baseUrl}verify_skipcash_payment');
    debugPrint('[SkipCash] POST verify ⇒ $url');

    try {
      final res = await http.post(
        url,
        headers: {
          HttpHeaders.contentTypeHeader : 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $_jwt',
        },
        body: jsonEncode({'payment_id': paymentId}),
      );

      final data = jsonDecode(res.body);
      debugPrint('[SkipCash] Verify response ⇒ $data');

      if (res.statusCode == 200 && data['error'] == false) {
        /* 1. mark as done so further web-errors are ignored */
        _paymentDone = true;

        /* 2. inform Checkout sheet */
        await widget.onSuccess(data['message'] ?? 'Order placed');

        /* 3. clear local cart */
        if (mounted) context.read<CartProvider>().clearCart();

        /* 4. close WebView first … */
        if (mounted) Navigator.of(context).pop();

        /* 5. … then open Order-success on root navigator */
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context, rootNavigator: true)
              .pushNamedAndRemoveUntil(
                Routers.orderSuccessScreen,
                (route) => route.isFirst,
              );
        });
      } else {
        widget.onError(data['message'] ?? 'Payment verification failed.');
      }
    } catch (e) {
      widget.onError('Verification failed: $e');
    }
  }

  /* ─────────────────────────────────────────────────────────────── */

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
