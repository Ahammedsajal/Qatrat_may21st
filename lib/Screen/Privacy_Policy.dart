import 'dart:async';
import 'package:customer/Helper/Color.dart';
import 'package:customer/Helper/Session.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Helper/String.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/widgets/AppBtn.dart';
import '../ui/widgets/SimpleAppBar.dart';
import '../utils/blured_router.dart';
import 'HomePage.dart';

class PrivacyPolicy extends StatefulWidget {
  final String? title;

  static route(RouteSettings settings) {
    final Map? arguments = settings.arguments as Map?;
    return BlurredRouter(
      builder: (context) {
        return PrivacyPolicy(
          title: arguments?['title'],
        );
      },
    );
  }

  const PrivacyPolicy({super.key, this.title});

  @override
  State<StatefulWidget> createState() {
    return StatePrivacy();
  }
}

class StatePrivacy extends State<PrivacyPolicy> with TickerProviderStateMixin {
  bool _isLoading = true;
  String? privacy;
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;

  @override
  void initState() {
    super.initState();
    getSetting();
    buttonController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(CurvedAnimation(
      parent: buttonController!,
      curve: const Interval(
        0.0,
        0.150,
      ),
    ));
  }

  static Route route(RouteSettings settings) {
    final Map? arguments = settings.arguments as Map?;
    return CupertinoPageRoute(
      builder: (context) => PrivacyPolicy(
        title: arguments?['title'],
      ),
    );
  }

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {
      return;
    }
  }

  Widget noInternet(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          noIntImage(),
          noIntText(context),
          noIntDec(context),
          AppBtn(
            title: getTranslated(context, 'TRY_AGAIN_INT_LBL'),
            btnAnim: buttonSqueezeanimation,
            btnCntrl: buttonController,
            onBtnSelected: () async {
              _playAnimation();
              Future.delayed(const Duration(seconds: 2)).then((_) async {
                _isNetworkAvail = await isNetworkAvailable();
                if (_isNetworkAvail) {
                  Navigator.pushReplacement(
                    context,
                    CupertinoPageRoute(
                      builder: (BuildContext context) => super.widget,
                    ),
                  );
                } else {
                  await buttonController!.reverse();
                  if (mounted) {
                    setState(() {
                      getSetting();
                    });
                  }
                }
              });
            },
          ),
        ],
      ),
    );
  }

  @override
 Widget build(BuildContext context) {
  return _isLoading
      ? Scaffold(
          appBar: getSimpleAppBar(widget.title!, context),
          body: getProgress(context),
        )
      : _isNetworkAvail
          ? privacy != ""
              ? Scaffold(
                  appBar: getSimpleAppBar(widget.title!, context),
                  body: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Directionality(
                        textDirection: getCurrentLang(context) == 'ar'
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        child: HtmlWidget(
                          privacy!,
                          onTapUrl: (String? url) async {
                            if (await canLaunchUrl(Uri.parse(url!))) {
                              await launchUrl(Uri.parse(url));
                              return true;
                            } else {
                              throw 'Could not launch $url';
                            }
                          },
                          onErrorBuilder: (context, element, error) =>
                              Text('$element error: $error'),
                          onLoadingBuilder:
                              (context, element, loadingProgress) =>
                                  showCircularProgress(
                                      context,
                                      true,
                                      Theme.of(context).primaryColor),
                          textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.fontColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : Scaffold(
                  appBar: getSimpleAppBar(widget.title!, context),
                  body: _isNetworkAvail
                      ? const SizedBox.shrink()
                      : noInternet(context),
                )
          : Scaffold(
              appBar: getSimpleAppBar(widget.title!, context),
              body: _isNetworkAvail
                  ? const SizedBox.shrink()
                  : noInternet(context),
            );
}


  Future<void> getSetting() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        String? type;
        if (widget.title == getTranslated(context, 'PRIVACY')) {
          type = PRIVACY_POLLICY;
        } else if (widget.title == getTranslated(context, 'TERM')) {
          type = TERM_COND;
        } else if (widget.title == getTranslated(context, 'ABOUT_LBL')) {
          type = ABOUT_US;
        } else if (widget.title == getTranslated(context, 'CONTACT_LBL')) {
          type = CONTACT_US;
        } else if (widget.title == getTranslated(context, 'SHIPPING_PO_LBL')) {
          type = SHIPPING_POLICY;
        } else if (widget.title == getTranslated(context, 'RETURN_PO_LBL')) {
          type = RETURN_POLICY;
        }

        final parameter = {TYPE: type};
        final currentLang = getCurrentLang(context);

        apiBaseHelper.postAPICall(getSettingApi, parameter).then(
          (getdata) {
            final bool error = getdata["error"];
            final String? msg = getdata["message"];
            if (!error) {
              privacy = getdata["data"][type][0][currentLang];
            } else {
              setSnackbar(msg!, context);
            }
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onError: (error) {
            setSnackbar(error.toString(), context);
          },
        );
      } on TimeoutException catch (_) {
        _isLoading = false;
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isNetworkAvail = false;
        });
      }
    }
  }

  String getCurrentLang(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ar' ? 'ar' : 'en';
  }
}
