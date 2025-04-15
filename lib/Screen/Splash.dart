import 'dart:async';
import 'dart:convert';
import 'package:customer/Provider/SettingProvider.dart';
import 'package:customer/Provider/UserProvider.dart';
import 'package:customer/Screen/HomePage.dart';
import 'package:customer/app/routes.dart';
import 'package:customer/utils/blured_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../utils/blured_router.dart';
import '../Provider/SettingProvider.dart';
import 'package:flutter/cupertino.dart';
import 'package:customer/Screen/SignInUpAcc.dart';


class Splash extends StatefulWidget {
  const Splash({super.key});
  static route(RouteSettings settings) {
    return BlurredRouter(
      builder: (context) {
        return const Splash();
      },
    );
  }

  @override
  _SplashScreen createState() => _SplashScreen();
}

class _SplashScreen extends State<Splash> {
  bool from = false;
       final PageController _pageController = PageController();
  AnimationController? buttonController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top],);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ),
    );
    apiBaseHelper.postAPICall(getSettingApi, {}).then((value) {
      isCityWiseDelivery = (value['data'] as Map)['system_settings'][0]
              ['city_wise_deliverability'] ==
          "1";
      isFirebaseAuth = (value['data'] as Map)['authentication_settings'][0]
              ['authentication_method'] ==
          "firebase";
    });
    startTime();
  }
 @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
    buttonController!.dispose();
    
  }
  Future<void> setToken() async {
    FirebaseMessaging.instance.getToken().then(
      (token) async {
        final SettingProvider settingsProvider =
            Provider.of<SettingProvider>(context, listen: false);
        final String getToken = await settingsProvider.getPrefrence(FCMTOKEN) ?? '';
        print("fcm token****$token");
        if (token != getToken && token != null) {
          print("register token***$token");
          registerToken(token);
        }
      },
    );
  }

  Future<void> registerToken(String? token) async {
    final SettingProvider settingsProvider =
        Provider.of<SettingProvider>(context, listen: false);
    final parameter = {
      FCM_ID: token,
    };
    if (context.read<UserProvider>().userId != "") {
      parameter[USER_ID] = context.read<UserProvider>().userId;
    }
    final Response response =
        await post(updateFcmApi, body: parameter, headers: headers)
            .timeout(const Duration(seconds: timeOut));
    final getdata = json.decode(response.body);
    print("param noti fcm***$parameter");
    print("value notification****$getdata");
    if (getdata['error'] == false) {
      print("fcm token****$token");
      settingsProvider.setPrefrence(FCMTOKEN, token!);
    }
  }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Stack(
        children: <Widget>[
        Container(
  width: double.infinity,
  height: double.infinity,
  color: Theme.of(context).colorScheme.primarytheme,
  child: Center(
    child: Image.asset(
      'assets/images/logowhite.png', // Ensure the correct path and file extension
      fit: BoxFit.contain, // Adjust based on your design needs
    ),
  ),
),

          Image.asset(
            'assets/images/doodle.png',
            fit: BoxFit.fill,
            width: double.infinity,
            height: double.infinity,
          ),
        ],
      ),
    );
  }

  startTime() async {
    const duration = Duration(seconds: 2);
    return Timer(duration, navigationPage);
  }

  Future<void> navigationPage() async {
  Navigator.pushReplacementNamed(context, Routers.dashboardScreen);
}

 
}
