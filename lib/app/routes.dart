import 'dart:developer';
import 'package:customer/Screen/Dashboard.dart';
import 'package:customer/Screen/FaqsProduct.dart';
import 'package:customer/Screen/Favorite.dart';
import 'package:customer/Screen/Intro_Slider.dart';
import 'package:customer/Screen/MyOrder.dart';
import 'package:customer/Screen/MyTransactions.dart';
import 'package:customer/Screen/My_Wallet.dart';
import 'package:customer/Screen/NotificationLIst.dart';
import 'package:customer/Screen/Order_Success.dart';
import 'package:customer/Screen/ProductList.dart';
import 'package:customer/Screen/Product_DetailNew.dart';
import 'package:customer/Screen/PromoCode.dart';
import 'package:customer/Screen/Sale_Section.dart';
import 'package:customer/Screen/Search.dart';
import 'package:customer/Screen/SendOtp.dart';
import 'package:customer/Screen/Set_Password.dart';
import 'package:customer/Screen/SignUp.dart';
import 'package:customer/Screen/Splash.dart';
import 'package:customer/Screen/SubCategory.dart';
import 'package:customer/Screen/Verify_Otp.dart';
import '../Screen/about_us.dart';
import '../Screen/TermsScreen.dart';
import '../Screen/PrivacyScreen.dart';
import 'package:customer/utils/blured_router.dart';
import 'package:flutter/material.dart';
import '../Screen/Login.dart';
import '../Screen/Payment.dart';
import '../Screen/SectionList.dart';
import 'package:customer/Screen/most_needed_mosques.dart';
import 'package:customer/Screen/qatar_mosques.dart';
import 'package:customer/Screen/watering_feeding.dart';
import 'package:customer/Screen/iftar.dart';
import '../cubits/FetchMosquesCubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../settings.dart';



class Routers {
  Routers._();
  static const String splash = "/";
  static const String dashboardScreen = "/dashboard";
  static const String mostNeededMosquesScreen = "/mostNeededMosques";
  static const String qatarMosquesScreen = "/qatarMosques";
  static const String wateringFeedingScreen = "/wateringFeeding";
  static const String iftarScreen = "/iftar";

  static const String introSliderScreen = "/introSliderScreen";
  static const String notificationListScreen = "/notificationListScreen";
  static const String loginScreen = "/loginScreen";
  static const String sendOTPScreen = "/sendOTPScreen";
  static const String productDetails = "/productDetailsScreen";
  static const String saleSectionScreen = "/saleSectionScreen";
  static const String sectionListScreen = "/sectionListScreen";
  static const String setPassScreen = "/setPassScreen";
  static const String signupScreen = "/signupScreen";
  static const String faqProductScreen = "/faqProduct";
  static const String productListScreen = "/productListScreen";
  static const String subCategoryScreen = "/subCategoryScreen";
  static const String searchScreen = "/searchScreen";
  static const String myOrderScreen = "/myOrderScreen";
  static const String transactionHistoryScreen = "/transactionHistoryScreen";
  static const String myWalletScreen = "/myWalletScreen";
  static const String promoCodeScreen = "/promoCodeScreen";
  static const String manageAddressScreen = "/manageAddressScreen";
  static const String paymentScreen = "/paymentScreen";
  static const String orderSuccessScreen = "/orderSuccessScreen";
  static const String favoriteScreen = "/favoriteScreen";
  static const String verifyOTPScreen = "/verifyOTPScreen";
 static const String privacyPolicyScreen = 'privacy_policy';

  static String currentRoute = splash;
  static String previouscustomerRoute = splash;
  static const String aboutUsScreen = "/aboutUsScreen";
static const String termsScreen = "/terms";
static const String PRIVACY_POLICY = 'privacy_policy';



  static Route? onGenerateRouted(RouteSettings routeSettings) {

    previouscustomerRoute = currentRoute;
    currentRoute = routeSettings.name ?? "";
    log("CURRENT ROUTE $currentRoute");
    switch (routeSettings.name) {
      case qatarMosquesScreen:
  // Optionally, pass a flag via arguments if you need (e.g., isFromCheckout)
  final bool isFromCheckout = (routeSettings.arguments as bool?) ?? false;
  return MaterialPageRoute(
    builder: (context) => BlocProvider<FetchMosquesCubit>(
      create: (context) => FetchMosquesCubit()..fetchMosques(),
      child: QatarMosques(isFromCheckout: isFromCheckout),
    ),
  );

case privacyPolicyScreen:
  return PrivacyScreen.route(routeSettings);


case aboutUsScreen:
  return MaterialPageRoute(
    builder: (context) => AboutUs(
      title: 'About Us', // 👈 Use plain text here
    ),
  );
case termsScreen:
  return TermsAndConditions.route(routeSettings);
// ✅ Correct


      case splash:
        return Splash.route(routeSettings);
      case dashboardScreen:
         return MaterialPageRoute(builder: (_) => Dashboard());
      case notificationListScreen:
        return NotificationList.route(routeSettings);
      case loginScreen:
        return LoginScreen.route(routeSettings);
      case sendOTPScreen:
        return SendOtp.route(routeSettings);
      case productDetails:
        return ProductDetail.route(routeSettings);
     case Routers.mostNeededMosquesScreen:
  return MaterialPageRoute(
    builder: (context) => BlocProvider<FetchMosquesCubit>(
      create: (_) => FetchMosquesCubit()..fetchMosques(),
      child: MostNeededMosques(),
    ),
  );
 // ✅ Correct





case wateringFeedingScreen:
  return MaterialPageRoute(builder: (_) => WateringFeeding());

case iftarScreen:
  return MaterialPageRoute(builder: (_) => Iftar());  // ✅ Correct


      case saleSectionScreen:
        return SaleSectionScreen.route(routeSettings);
      case sectionListScreen:
        return SectionListScreen.route(routeSettings);
      case setPassScreen:
        return SetPass.route(routeSettings);
      case signupScreen:
        return SignUp.route(routeSettings);
      case faqProductScreen:
        return FaqsProduct.route(routeSettings);
     case productListScreen:
  final Map? arguments = routeSettings.arguments as Map?;
  return MaterialPageRoute(
    builder: (context) => ProductListScreen(
      id: arguments?['id'],
      dis: arguments?['dis'],
      tag: arguments?['tag'],
      fromSeller: arguments?['fromSeller'],
      brandId: arguments?['brandId'],
      maxDis: arguments?['maxDis'],
      minDis: arguments?['minDis'],
      name: arguments?['name'],
    ),
  );

      case subCategoryScreen:
        return SubCategoryScreen.route(routeSettings);
      case searchScreen:
        return SearchScreen.route(routeSettings);
      case myOrderScreen:
        return MyOrder.route(routeSettings);
      case transactionHistoryScreen:
        return TransactionHistory.route(routeSettings);
      case myWalletScreen:
        return MyWalletScreen.route(routeSettings);
      case promoCodeScreen:
        return PromoCodeScreen.route(routeSettings);
     
      case paymentScreen:
        return Payment.route(routeSettings);
      case orderSuccessScreen:
        return OrderSuccess.route(routeSettings);
      case favoriteScreen:
        return Favorite.route(routeSettings);
      case verifyOTPScreen:
        return VerifyOtp.route(routeSettings);
      case introSliderScreen:
        return IntroSlider.route(routeSettings);
     default:
  return MaterialPageRoute(
    builder: (context) {
      return const Scaffold(
        body: Center(
          child: Text("No page found"),
        ),
      );
    },
  );

    }
  }
}
