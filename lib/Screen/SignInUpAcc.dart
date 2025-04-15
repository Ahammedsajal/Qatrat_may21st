import 'package:customer/Helper/Session.dart';
import 'package:customer/Helper/String.dart';
import 'package:customer/Screen/Dashboard.dart';
import 'package:customer/ui/widgets/AppBtn.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../Helper/Color.dart';
import '../app/routes.dart';

class SignInUpAcc extends StatefulWidget {
  const SignInUpAcc({super.key});
  @override
  _SignInUpAccState createState() => _SignInUpAccState();
}

class _SignInUpAccState extends State<SignInUpAcc>
    with TickerProviderStateMixin {
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  @override
  void initState() {
    super.initState();
    buttonController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this,);
    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.9,
      end: 50.0,
    ).animate(CurvedAnimation(
      parent: buttonController!,
      curve: const Interval(
        0.0,
        0.150,
      ),
    ),);
  }

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  _subLogo() {
    return Padding(
        padding: const EdgeInsetsDirectional.only(top: 30.0),
        child: Image.asset(
          'assets/images/logo.PNG',
          ));
  }

  welcomecustomerTxt() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 30.0),
      child: Text(
        getTranslated(context, 'WELCOME_customer')!,
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
            color: Theme.of(context).colorScheme.fontColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,),
      ),
    );
  }

  eCommerceforBusinessTxt() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: 5.0,
      ),
      child: Text(
        getTranslated(context, 'ECOMMERCE_APP_FOR_ALL_BUSINESS')!,
        style: Theme.of(context).textTheme.titleSmall!.copyWith(
            color: Theme.of(context).colorScheme.secondaryFontColor,
            fontWeight: FontWeight.normal,),
      ),
    );
  }

  signInyourAccTxt() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: 60.0,
      ),
      child: Text(
        getTranslated(context, 'SIGNIN_ACC_LBL')!,
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
            color: Theme.of(context).colorScheme.fontColor,
            fontWeight: FontWeight.bold,),
      ),
    );
  }

  signInBtn() {
    return AppBtn(
      title: getTranslated(context, 'SIGNIN_LBL')!.toUpperCase(),
      btnAnim: buttonSqueezeanimation,
      btnCntrl: buttonController,
      onBtnSelected: () async {
        Navigator.pushNamed(context, Routers.loginScreen,
            arguments: {"isPop": false},);
      },
    );
  }

  createAccBtn() {
    return AppBtn(
      padding: const EdgeInsets.only(),
      title: getTranslated(context, 'CREATE_ACC_LBL')!.toUpperCase(),
      btnAnim: buttonSqueezeanimation,
      btnCntrl: buttonController,
      onBtnSelected: () async {
        Navigator.pushNamed(context, Routers.sendOTPScreen,
            arguments: {"title": getTranslated(context, 'SEND_OTP_TITLE')},);
      },
    );
  }

  skipSignInBtn() {
    return AppBtn(
      padding: const EdgeInsets.only(),
      title: getTranslated(context, 'SKIP_SIGNIN_LBL')!.toUpperCase(),
      btnAnim: buttonSqueezeanimation,
      btnCntrl: buttonController,
      onBtnSelected: () async {
        Dashboard.dashboardScreenKey = GlobalKey<HomePageState>();
        Navigator.pushReplacementNamed(
          context,
          Routers.dashboardScreen,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.lightWhite,
      body: Container(
        color: Theme.of(context).colorScheme.lightWhite,
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _subLogo(),
                welcomecustomerTxt(),
                eCommerceforBusinessTxt(),
                signInyourAccTxt(),
                signInBtn(),
                createAccBtn(),
                skipSignInBtn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
