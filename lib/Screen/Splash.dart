import 'dart:async';
import 'dart:convert';
import 'package:customer/Provider/SettingProvider.dart';
import 'package:customer/Provider/UserProvider.dart';
import 'package:customer/Screen/HomePage.dart';
import 'package:customer/app/routes.dart';
import 'package:customer/utils/blured_router.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'SignInUpAcc.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  static route(RouteSettings settings) {
    return BlurredRouter(
      builder: (context) => const Splash(),
    );
  }

  @override
  _SplashScreen createState() => _SplashScreen();
}

class _SplashScreen extends State<Splash> {
  final PageController _pageController = PageController();
  AnimationController? buttonController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );

    _initApp();
  }

  @override
  void dispose() {
    _pageController.dispose();
    buttonController?.dispose(); // ✅ Safe dispose
    super.dispose();
  }

  Future<void> _initApp() async {
    // ✅ Initialize Firebase safely
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    // Fetch settings
    final value = await apiBaseHelper.postAPICall(getSettingApi, {});
    isCityWiseDelivery = (value['data'] as Map)['system_settings'][0]
            ['city_wise_deliverability'] ==
        "1";
    isFirebaseAuth = (value['data'] as Map)['authentication_settings'][0]
            ['authentication_method'] ==
        "firebase";

    // Set device token
    await setToken();

    // Move forward after delay
    startTime();
  }

  Future<void> setToken() async {
    FirebaseMessaging.instance.getToken().then((token) async {
      final settingsProvider =
          Provider.of<SettingProvider>(context, listen: false);
      final storedToken =
          await settingsProvider.getPrefrence(FCMTOKEN) ?? '';
      if (token != null && token != storedToken) {
        registerToken(token);
      }
    });
  }

  Future<void> registerToken(String? token) async {
    final settingsProvider =
        Provider.of<SettingProvider>(context, listen: false);

    final parameter = {
      FCM_ID: token,
    };

    if (context.read<UserProvider>().userId.isNotEmpty) {
      parameter[USER_ID] = context.read<UserProvider>().userId;
    }

    try {
      final response = await post(updateFcmApi,
              body: parameter, headers: headers)
          .timeout(const Duration(seconds: timeOut));
      final getdata = json.decode(response.body);

      if (getdata['error'] == false && token != null) {
        settingsProvider.setPrefrence(FCMTOKEN, token);
      }
    } catch (e) {
      print("FCM token registration error: $e");
    }
  }

  startTime() async {
    const duration = Duration(seconds: 2);
    return Timer(duration, navigationPage);
  }

  Future<void> navigationPage() async {
    Navigator.pushReplacementNamed(context, Routers.dashboardScreen);
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
                'assets/images/logowhite.png',
                fit: BoxFit.contain,
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
}
