import 'package:customer/Helper/Session.dart';
import 'package:customer/Helper/String.dart';
import 'package:customer/ui/styles/DesignConfig.dart';
import 'package:customer/ui/widgets/AppBtn.dart';
import 'package:flutter/material.dart';

class NoInternetWidget extends StatefulWidget {
  final Function onRetry;
  const NoInternetWidget({super.key, required this.onRetry});
  @override
  State<NoInternetWidget> createState() => _NoInternetWidgetState();
}

class _NoInternetWidgetState extends State<NoInternetWidget>
    with TickerProviderStateMixin {
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  @override
  void initState() {
    super.initState();
    buttonController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this,);
    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(CurvedAnimation(
      parent: buttonController!,
      curve: const Interval(
        0.0,
        0.150,
      ),
    ),);
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {
      return;

    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
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
              final isNetworkAvail = await isNetworkAvailable();

              if (isNetworkAvail) {
                await widget.onRetry();
              } else {
                await buttonController!.reverse();
                if (mounted) setState(() {});
              }
            });
          },
        ),
      ],),
    );
  }
}
