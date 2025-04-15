import 'package:customer/ui/styles/DesignConfig.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../Helper/Constant.dart';
import '../Helper/Color.dart';
import '../Helper/Session.dart';
import '../Provider/UserProvider.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class MidTrashWebview extends StatefulWidget {
  final String? url;
  final String? from;
  final String? msg;
  final String? amt;
  final String? orderId;
  const MidTrashWebview(
      {super.key, this.url, this.from, this.msg, this.amt, this.orderId,});
  @override
  State<StatefulWidget> createState() {
    return StateMidTrashWebview();
  }
}

class StateMidTrashWebview extends State<MidTrashWebview> {
  String message = '';
  bool isloading = true;
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  late final WebViewController _controller;
  DateTime? currentBackPressTime;
  late UserProvider userProvider;
  @override
  void initState() {
    webViewInitiliased();
    super.initState();
  }

  webViewInitiliased() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }
    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);
    controller
      ..loadRequest(Uri.parse(widget.url!))
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (String url) {
          setState(
            () {
              isloading = false;
            },
          );
        },
        onNavigationRequest: (request) async {
          print('*******request url1 ****** ${request.url}');
          if (request.url.contains('app/v1/api/midtrans_payment_process')) {
            if (mounted) {
              setState(
                () {
                  print('*******request url ****** ${request.url}');
                  isloading = true;
                },
              );
            }
            final String responseurl = request.url;
            print("response url*****$responseurl");
            if (responseurl.contains('Failed') ||
                responseurl.contains('failed')) {
              if (mounted) {
                setState(
                  () {
                    isloading = false;
                  },
                );
              } else if (responseurl.contains('capture') ||
                  responseurl.contains('completed') ||
                  responseurl.toLowerCase().contains('success')) {}
            }
            Navigator.of(context).pop();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),);
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        titleSpacing: 0,
        leading: Builder(
          builder: (BuildContext context) {
            return Container(
              margin: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(
                      color: Color(0x1a0400ff),
                      blurRadius: 30,),
                ],
              ),
              child: Card(
                elevation: 0,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () {
                    final DateTime now = DateTime.now();
                    if (currentBackPressTime == null ||
                        now.difference(currentBackPressTime!) >
                            const Duration(seconds: 2)) {
                      currentBackPressTime = now;
                      setSnackbar(
                        "${getTranslated(context, "Don't press back while doing payment!")}\n ${getTranslated(context, 'EXIT_WR')!}",
                        context,
                      );
                    }
                    Navigator.pop(context);
                  },
                  child: Center(
                    child: Icon(
                      Icons.keyboard_arrow_left,
                      color: Theme.of(context).colorScheme.primarytheme,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        title: Text(
          appName,
          style: TextStyle(
            fontFamily: 'ubuntu',
            color: Theme.of(context).colorScheme.fontColor,
          ),
        ),
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            final DateTime now = DateTime.now();
            if (currentBackPressTime == null ||
                now.difference(currentBackPressTime!) >
                    const Duration(seconds: 2)) {
              currentBackPressTime = now;
              setSnackbar(
                "${getTranslated(context, "Don't press back while doing payment!")}\n ${getTranslated(context, 'EXIT_WR')!}",
                context,
              );
            } else {
              if (didPop) {
                return;
              }
              Navigator.pop(context, 'true');
            }
          }
        },
        child: Stack(
          children: <Widget>[
            WebViewWidget(controller: _controller),
            if (isloading) const Center(
                    child: CircularProgressIndicator(),
                  ) else const SizedBox.shrink(),
            if (message.trim().isEmpty) const SizedBox.shrink() else Center(
                    child: Container(
                      color: Theme.of(context).colorScheme.primarytheme,
                      padding: const EdgeInsets.all(5),
                      margin: const EdgeInsets.all(5),
                      child: Text(
                        message,
                        style: TextStyle(
                          fontFamily: 'ubuntu',
                          color: Theme.of(context).colorScheme.white,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
