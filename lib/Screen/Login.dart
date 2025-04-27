import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:customer/Helper/Constant.dart';
import 'package:customer/Helper/SqliteData.dart';
import 'package:customer/Helper/String.dart';
import 'package:customer/Provider/FavoriteProvider.dart';
import 'package:customer/Provider/SettingProvider.dart';
import 'package:customer/Provider/UserProvider.dart';
import 'package:customer/Screen/Dashboard.dart';
import 'package:customer/app/routes.dart';
import 'package:customer/utils/Hive/hive_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../Helper/Color.dart';
import '../Helper/PushNotificationService.dart';
import '../Helper/Session.dart';
import '../Model/Section_Model.dart';
import '../Provider/CartProvider.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/styles/Validators.dart';
import '../ui/widgets/ApiException.dart';
import '../ui/widgets/AppBtn.dart';
import '../ui/widgets/BehaviorWidget.dart';
import '../utils/blured_router.dart';
import 'HomePage.dart';
import 'Privacy_Policy.dart';
import 'package:customer/Screen/cart/Cart.dart';
import 'package:customer/Helper/SqliteData.dart';
import 'package:country_code_picker/country_code_picker.dart';


class LoginScreen extends StatefulWidget {
  final Widget? classType;
  final bool isPop;
  final bool? isRefresh;
  static route(RouteSettings settings) {
    final Map? arguments = settings.arguments as Map?;
    return BlurredRouter(
      builder: (context) {
        return LoginScreen(
          isPop: arguments?['isPop'],
          isRefresh: arguments?['isRefresh'],
          classType: arguments?['classType'],
        );
      },
    );
  }

  const LoginScreen({
    super.key,
    this.classType,
    this.isRefresh,
    required this.isPop,
  });
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginScreen> with TickerProviderStateMixin {
  final mobileController =
      TextEditingController(text: isDemoApp ? "" : "");
  final passwordController =
      TextEditingController(text: isDemoApp ? "" : "");
      String? selectedCountryCode = "+974"; // or your default code

  String? countryName;
  FocusNode? passFocus;
  FocusNode? monoFocus = FocusNode();
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();

  bool visible = false;
  double originalPrice = 0.0;
  String? password;
  String? mobile;
  String? username;
  String? email;
  String? id;
  String? mobileno;
  String? city;
  String? area;
  String? pincode;
  String? address;
  String? latitude;
  String? longitude;
  String? image;
  String? loginType;
  List<String> productIds = [];
  bool _isNetworkAvail = true;
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  AnimationController? _animationController;
  DatabaseHelper db = DatabaseHelper();
  bool acceptTnC = true;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool socialLoginLoading = false;
  bool? googleLogin;
  bool? appleLogin;
  bool isShowPass = true;
  @override
  void initState() {
    super.initState();
    getSetting();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500),);
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
    _animationController!.dispose();
    buttonController!.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }


  void getSetting() {
    try {
      apiBaseHelper.postAPICall(getSettingApi, {}).then((getdata) async {
        final bool error = getdata["error"];
        final String? msg = getdata["message"];
        if (!error) {
          final data = getdata["data"]["system_settings"][0];
          print("data****${getdata["data"]["system_settings"][0]}");
          setState(() {
            googleLogin = data[GOOGLE_LOGIN] == 1 ? true : false;
            appleLogin = data[APPLE_LOGIN] == 1 ? true : false;
          });
        } else {
          setSnackbar(msg!, context);
        }
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      },);
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {
      return;

    }
  }

  Future<void> onTapSignIn() async {
    if (validateAndSave()) {
      _playAnimation();
      checkNetwork();
    }
  }
Future<void> _getOfflineCart() async {
  // Assuming you have access to your DatabaseHelper instance `db` and a list 'productIds'
  productIds = (await db.getCart())!;
  // Add any additional logic needed to update your CartProvider or local variables
  // For example, you might load full product details from the API if needed.
}

  Future<void> checkNetwork() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      signInProcess();
    } else {
      Future.delayed(const Duration(seconds: 2)).then((_) async {
        await buttonController!.reverse();
        if (mounted) {
          setState(() {
            _isNetworkAvail = false;
          });
        }
      });
    }
  }

  bool validateAndSave() {
    final form = _formkey.currentState!;
    form.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }

  Widget noInternet(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.only(top: kToolbarHeight),
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
              _isNetworkAvail = await isNetworkAvailable();
              if (_isNetworkAvail) {
                Navigator.pushReplacement(
                    context,
                    CupertinoPageRoute(
                        builder: (BuildContext context) => super.widget,),);
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



Widget setCountryCodeAndMobile() {
  return Container(
    width: MediaQuery.of(context).size.width * 0.85,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.lightBlack2.withOpacity(0.3),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ===== COUNTRY CODE PICKER =====
        Theme(
          data: Theme.of(context).copyWith(
            dialogBackgroundColor: Theme.of(context).dialogBackgroundColor,
          ),
          child: CountryCodePicker(
            onChanged: (countryCode) {
              setState(() {
                selectedCountryCode = countryCode.dialCode!;
              });
            },
            initialSelection: 'QA', // Set Qatar as default
            favorite: const ['+974', 'QA'],
            showFlag: true,
            showDropDownButton: true,
            showOnlyCountryWhenClosed: false,
            alignLeft: false,
            flagWidth: 16,
            padding: EdgeInsets.zero,
            textStyle: TextStyle(
              color: Theme.of(context).colorScheme.fontColor,
              fontSize: 12,
            ),
            dialogTextStyle: TextStyle(
              color: colors.darkColor,
              fontSize: 14,
            ),
            searchStyle: TextStyle(
              color: colors.darkColor,
              fontSize: 14,
            ),
          ),
        ),

        // Vertical Divider
        Container(
          height: 30,
          width: 1,
          color: Theme.of(context).colorScheme.fontColor.withOpacity(0.5),
          margin: const EdgeInsets.symmetric(horizontal: 10),
        ),

        // ===== MOBILE INPUT FIELD =====
        Expanded(
          child: TextFormField(
            controller: mobileController,
            keyboardType: TextInputType.phone,
            style: TextStyle(
              color: Theme.of(context).colorScheme.fontColor,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: getTranslated(context, 'ENTER_MOBILE_NUMBER') ?? 'Enter mobile number',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.fontColor.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}




  Future<void> signInProcess() async {
final phoneWithCode = mobileController.text.trim(); 
    final data = {MOBILE: phoneWithCode, PASSWORD: password};
    print("PARAMS ARE $data");
    apiBaseHelper.postAPICall(getUserLoginApi, data).then((getdata) async {
      final bool error = getdata["error"];
      final String? msg = getdata["message"];
      print("PARAMS ARE ${getdata['token']}");
      await buttonController!.reverse();
      if (!error) {
        await HiveUtils.setJWT(getdata['token']);
        setSnackbar(msg!, context);
        final i = getdata["data"][0];
        id = i[ID];
        username = i[USERNAME];
        email = i[EMAIL];
        mobile = i[MOBILE];
        city = i[CITY];
        area = i[AREA];
        address = i[ADDRESS];
        pincode = i[pinCodeOrCityNameKey];
        latitude = i[LATITUDE];
        longitude = i[LONGITUDE];
        image = i[IMAGE];
        loginType = i[TYPE];
        final SettingProvider settingProvider =
            Provider.of<SettingProvider>(context, listen: false);
        settingProvider.setPrefrenceBool(ISFIRSTTIME, true);
        settingProvider.saveUserDetail(id!, username, email, mobile, city, area,
            address, pincode, latitude, longitude, image, loginType, context,);
        Future.delayed(Duration.zero, () {
          PushNotificationService(context: context).setDeviceToken(
              clearSesssionToken: true, settingProvider: settingProvider,);
        });
        offFavAdd().then((value) {
         
          context.read<FavoriteProvider>().setFavlist([]);
          offCartAdd().then((value) {
           
            offSaveAdd().then((value) {
             
              if (widget.isPop) {
                if (widget.isRefresh != null) {
                  Navigator.pop(context, 'refresh');
                } else {
                 _getFav(context).whenComplete(() {
  _getOfflineCart().whenComplete(() {
    Future.delayed(const Duration(seconds: 2)).whenComplete(() {
      Navigator.of(context).pop();
    });
  });
});

                }
              } else {
                Navigator.pushAndRemoveUntil(context,
                    BlurredRouter(builder: (BuildContext context) {
                  Dashboard.dashboardScreenKey = GlobalKey<HomePageState>();
                  return widget.classType ??
                      Dashboard(
                        key: Dashboard.dashboardScreenKey,
                      );
                },), (route) => false,);
              }
            });
          });
        });
      } else {
        setSnackbar(msg!, context);
      }
    }, onError: (error) {
      setSnackbar(error.toString(), context);
    },);
  }

  Future _getFav(BuildContext context) async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        if (context.read<UserProvider>().userId != "") {
          final Map parameter = {
            USER_ID: context.read<UserProvider>().userId,
          };
          apiBaseHelper.postAPICall(getFavApi, parameter).then((getdata) {
            final bool error = getdata["error"];
            final String? msg = getdata["message"];
            if (!error) {
              final data = getdata["data"];
              final List<Product> tempList =
                  (data as List).map((data) => Product.fromJson(data)).toList();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<FavoriteProvider>().setFavlist(tempList);
              });
            } else {
              if (msg != 'No Favourite(s) Product Are Added') {
                setSnackbar(msg!, context);
              }
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<FavoriteProvider>().setLoading(false);
            });
          }, onError: (error) {
            setSnackbar(error.toString(), context);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<FavoriteProvider>().setLoading(false);
            });
          },);
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<FavoriteProvider>().setLoading(false);
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isNetworkAvail = false;
          });
        }
      }
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  Future<void> _getCart(String save, BuildContext context) async {
  try {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      // Use offline logic: if there are locally stored product IDs, load their details.
      if (productIds.isNotEmpty) {
        try {
          final parameter = {
            "product_variant_ids": productIds.join(',')
          };
          apiBaseHelper.postAPICall(getProductApi, parameter).then((getdata) async {
            final bool error = getdata["error"];
            if (!error) {
              final data = getdata["data"];
              // Clear the current cart list and reset the total price.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<CartProvider>().setCartlist([]);
                originalPrice = 0;
              });
              // Parse the returned data as a list of Product objects.
              final List<Product> productList = (data as List)
                  .map((data) => Product.fromJson(data))
                  .toList();
              List<SectionModel> offlineCartList = [];
              // Loop through each product and its variant list.
              for (int i = 0; i < productList.length; i++) {
                for (int j = 0; j < productList[i].prVarientList!.length; j++) {
                  // If the variant id exists in the local list, retrieve the quantity.
                  if (productIds.contains(productList[i].prVarientList![j].id)) {
                    final String qty = (await db.checkCartItemExists(
                      productList[i].id!,
                      productList[i].prVarientList![j].id!,
                    ))!;
                    final List<Product> prList = [];
                    productList[i].prVarientList![j].cartCount = qty;
                    prList.add(productList[i]);
                    offlineCartList.add(
                      SectionModel(
                        id: productList[i].id,
                        varientId: productList[i].prVarientList![j].id,
                        qty: qty,
                        productList: prList,
                      ),
                    );
                    // Calculate the total price for this item.
                    double price = double.parse(productList[i].prVarientList![j].disPrice!);
                    if (price == 0) {
                      price = double.parse(productList[i].prVarientList![j].price!);
                    }
                    final double total = price * int.parse(qty);
                    originalPrice += total;
                  }
                }
              }
              // Update the CartProvider and UserProvider with the offline cart list.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<CartProvider>().setCartlist(offlineCartList);
                context.read<UserProvider>().setCartCount(offlineCartList.length.toString());
              });
            }
          }, onError: (error) {
            setSnackbar(error.toString(), context);
          });
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
        }
      } else {
        // No locally stored product IDs; clear the cart.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<CartProvider>().setCartlist([]);
          context.read<UserProvider>().setCartCount("0");
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  } on FormatException catch (e) {
    setSnackbar(e.message, context);
  }
}


  Future<void> offFavAdd() async {
    final List favOffList = await db.getOffFav();
    if (favOffList.isNotEmpty) {
      for (int i = 0; i < favOffList.length; i++) {
        _setFav(favOffList[i]["PID"]);
      }
    }
  }

  _setFav(String pid) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        final parameter = {
          USER_ID: context.read<UserProvider>().userId,
          PRODUCT_ID: pid,
        };
        apiBaseHelper.postAPICall(setFavoriteApi, parameter).then((getdata) {
          final bool error = getdata["error"];
          final String? msg = getdata["message"];
          if (!error) {
          } else {
            setSnackbar(msg!, context);
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        },);
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  Future<void> offCartAdd() async {
    final List cartOffList = await db.getOffCart();
    if (cartOffList.isNotEmpty) {
      for (int i = 0; i < cartOffList.length; i++) {
        addToCartCheckout(cartOffList[i]["VID"], cartOffList[i]["QTY"]);
      }
    }
  }

  Future<void> addToCartCheckout(String varId, String qty) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        final parameter = {
          PRODUCT_VARIENT_ID: varId,
          USER_ID: context.read<UserProvider>().userId,
          QTY: qty,
        };
        apiBaseHelper.postAPICall(manageCartApi, parameter).then((getdata) {
          final bool error = getdata["error"];
          if (!error) {
          } else {}
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        },);
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      if (mounted) _isNetworkAvail = false;
      setState(() {});
    }
  }

  Future<void> offSaveAdd() async {
    final List saveOffList = await db.getOffSaveLater();
    if (saveOffList.isNotEmpty) {
      for (int i = 0; i < saveOffList.length; i++) {
        saveForLater(saveOffList[i]["VID"], saveOffList[i]["QTY"]);
      }
    }
  }

  saveForLater(String vid, String qty) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        final parameter = {
          PRODUCT_VARIENT_ID: vid,
          USER_ID: context.read<UserProvider>().userId,
          QTY: qty,
          SAVE_LATER: "1",
        };
        apiBaseHelper.postAPICall(manageCartApi, parameter).then((getdata) {
          final bool error = getdata["error"];
          final String? msg = getdata["message"];
          if (!error) {
          } else {
            setSnackbar(msg!, context);
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        },);
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  signInTxt() {
    return Padding(
        padding: const EdgeInsetsDirectional.only(
          top: 30.0,
        ),
        child: Align(
          child: Text(
            getTranslated(context, 'SIGNIN_LBL')!,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.bold,),
          ),
        ),);
  }

  setMobileNo() {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0)),
      width: MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.only(
        top: 15.0,
      ),
      child: TextFormField(
        onFieldSubmitted: (v) {
          FocusScope.of(context).requestFocus(monoFocus);
        },
        keyboardType: TextInputType.text,
        controller: mobileController,
        style: TextStyle(
          color: Theme.of(context).colorScheme.fontColor,
          fontWeight: FontWeight.normal,
        ),
        enabled: true,
        focusNode: monoFocus,
        textInputAction: TextInputAction.next,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (val) => validateMob(
            val!,
            getTranslated(context, 'MOB_REQUIRED'),
            getTranslated(context, 'VALID_MOB'),),
        onSaved: (String? value) {
          mobile = value;
        },
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.person,
            color: Theme.of(context).colorScheme.fontColor,
            size: 20,
          ),
          counter: const SizedBox(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 5,
          ),
          hintText: getTranslated(context, 'MOBILEHINT_LBL'),
          hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: Theme.of(context).colorScheme.fontColor,
              fontWeight: FontWeight.normal,),
          filled: true,
          fillColor: Theme.of(context).colorScheme.lightBlack2.withOpacity(0.3),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  setPass() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.only(
        top: 12.0,
      ),
      child: TextFormField(
        onFieldSubmitted: (v) {
          FocusScope.of(context).requestFocus(passFocus);
        },
        keyboardType: TextInputType.text,
        obscureText: isShowPass,
        controller: passwordController,
        style: TextStyle(
            color: Theme.of(context).colorScheme.fontColor,
            fontWeight: FontWeight.normal,),
        enabled: true,
        focusNode: passFocus,
        textInputAction: TextInputAction.next,
        validator: (val) => validatePass(
            val!,
            getTranslated(context, 'PWD_REQUIRED'),
            getTranslated(context, 'PASSWORD_VALIDATION'),
            from: 1,),
        onSaved: (String? value) {
          password = value;
        },
        decoration: InputDecoration(
          errorMaxLines: 2,
          prefixIcon: SvgPicture.asset(
            "assets/images/password.svg",
            colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.fontColor, BlendMode.srcIn,),
          ),
          suffixIcon: InkWell(
            onTap: () {
              setState(
                () {
                  isShowPass = !isShowPass;
                },
              );
            },
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 10.0),
              child: Icon(
                !isShowPass ? Icons.visibility : Icons.visibility_off,
                color: Theme.of(context).colorScheme.fontColor.withOpacity(0.4),
                size: 22,
              ),
            ),
          ),
          hintText: getTranslated(context, "PASSHINT_LBL"),
          hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: Theme.of(context).colorScheme.fontColor,
              fontWeight: FontWeight.normal,),
          filled: true,
          fillColor: Theme.of(context).colorScheme.lightBlack2.withOpacity(0.3),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          suffixIconConstraints:
              const BoxConstraints(minWidth: 40, maxHeight: 20),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 40, maxHeight: 20),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  forgetPass() {
    return Padding(
        padding:
            const EdgeInsetsDirectional.only(start: 25.0, end: 25.0, top: 13.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  Routers.sendOTPScreen,
                  arguments: {
                    "title": getTranslated(context, 'FORGOT_PASS_TITLE'),
                  },
                );
              },
              child: Text(getTranslated(context, 'FORGOT_PASSWORD_LBL')!,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.fontColor,
                      fontWeight: FontWeight.normal,),),
            ),
          ],
        ),);
  }

  getSignUpText() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
          bottom: 20.0, start: 25.0, end: 25.0, top: 10.0,),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(getTranslated(context, 'DONT_HAVE_AN_ACC')!,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.fontColor,
                  fontWeight: FontWeight.bold,),),
          InkWell(
              onTap: () {
                Navigator.pushNamed(context, Routers.sendOTPScreen, arguments: {
                  "title": getTranslated(context, 'SEND_OTP_TITLE'),
                },);
              },
              child: Text(
                getTranslated(context, 'SIGN_UP_LBL')!,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.primarytheme,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold,),
              ),),
        ],
      ),
    );
  }

  loginBtn() {
    return AppBtn(
      title: getTranslated(context, 'SIGNIN_LBL')!.toUpperCase(),
      btnAnim: buttonSqueezeanimation,
      btnCntrl: buttonController,
      onBtnSelected: () async {
        FocusScope.of(context).requestFocus(FocusNode());
        onTapSignIn();
      },
    );
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    resizeToAvoidBottomInset: true,
    body: _isNetworkAvail
        ? Stack(
            children: [
              // A base container to cover the full screen, making the stack occupy the whole view.
              SingleChildScrollView(
                child: Container(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                ),
              ),
              // Positioned widgets
              backBtn(),
              getLogo(),
              getLoginContainer(),
              if (socialLoginLoading)
                Center(
                  child: showCircularProgress(
                    context,
                    socialLoginLoading,
                    Theme.of(context).colorScheme.primarytheme,
                  ),
                ),
            ],
          )
        : noInternet(context),
  );
}



  backBtn() {
    return Positioned(
      top: 34.0,
      child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: shadow(),
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () => Navigator.of(context).pop(),
              child: Center(
                child: Icon(
                  Icons.keyboard_arrow_left,
                  color: Theme.of(context).colorScheme.fontColor,
                  size: 35,
                ),
              ),
            ),
          ),),
    );
  }

  getLoginContainer() {
    return Positioned.directional(
      start: MediaQuery.of(context).size.width * 0.025,
      end: MediaQuery.of(context).size.width * 0.025,
      top: MediaQuery.of(context).size.height * 0.15,
      textDirection: Directionality.of(context),
      child: Container(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom * 0,),
        child: Form(
          key: _formkey,
          child: ScrollConfiguration(
            behavior: MyBehavior(),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  setSignInLabel(),
                  setSignInDetail(),
                  setCountryCodeAndMobile(),
                  setPass(),
                  forgetPass(),
                  loginBtn(),
                  loginWith(),
                  socialLoginBtn(),
                  const SizedBox(
                    height: 5,
                  ),
                  getSignUpText(),
                  termAndPolicyTxt(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget loginWith() {
    if (googleLogin == true || (Platform.isIOS ? appleLogin == true : false)) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          getTranslated(context, 'OR_LOGIN_WITH_LBL')!,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Theme.of(context).colorScheme.fontColor.withOpacity(0.8),),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget termAndPolicyTxt() {
    if (googleLogin == true || (Platform.isIOS ? appleLogin == true : false)) {
      return Padding(
        padding: const EdgeInsets.only(
            left: 40.0, right: 40.0, top: 60,),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              children: [
                Expanded(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: getTranslated(context, 'CONTINUE_AGREE_LBL'),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(
                                color: Theme.of(context).colorScheme.fontColor,
                                fontWeight: FontWeight.normal,
                              ),
                        ),
                        const WidgetSpan(
                          child: SizedBox(width: 5.0),
                        ),
                        WidgetSpan(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) {
                                    return PrivacyPolicy(
                                      title: getTranslated(context, 'TERM'),
                                    );
                                  },
                                ),
                              );
                            },
                            child: Text(
                              getTranslated(context, 'TERMS_SERVICE_LBL')!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.normal,
                                  ),
                            ),
                          ),
                        ),
                        const WidgetSpan(
                          child: SizedBox(width: 5.0),
                        ),
                        TextSpan(
                          text: getTranslated(context, 'AND_LBL'),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(
                                color: Theme.of(context).colorScheme.fontColor,
                                fontWeight: FontWeight.normal,
                              ),
                        ),
                        const WidgetSpan(
                          child: SizedBox(width: 5.0),
                        ),
                        WidgetSpan(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => PrivacyPolicy(
                                    title: getTranslated(context, 'PRIVACY'),
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              getTranslated(context, 'PRIVACY')!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.normal,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Future<dynamic> loginAuth(
      {required String firebaseId,
      required String name,
      required String email,
      required String type,
      required String mobile,}) async {
    try {
      final body = {
        NAME: name,
        TYPE: type,
      };
      if (mobile != "") {
        body[MOBILE] = mobile;
      }
      if (email != "") {
        body[EMAIL] = email;
      }
      if (firebaseId != "") {
        body[FCM_ID] = firebaseId;
      }
      print("login param****$body");
      final getData = apiBaseHelper.postAPICall(signUpUserApi, body);
      print("getdata******$getData");
      return getData;
    } catch (e) {
      print("auth error");
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future<Map<String, dynamic>> onTapSocialLogin({
    required String type,
  }) async {
    try {
      final result = await socialSignInUser(type: type);
      final user = result['user'] as User;
      final Map<String, dynamic> userDataTest = await loginAuth(
          mobile: user.providerData[0].phoneNumber ?? "",
          email: user.providerData[0].email ?? "",
          firebaseId: user.providerData[0].uid ?? "",
          name: user.providerData[0].displayName ??
              (type == APPLE_TYPE ? "Apple User" : ""),
          type: type,);
      final bool error = userDataTest["error"];
      final String? msg = userDataTest["message"];
      print(":TOKENM ISS $userDataTest");
      await HiveUtils.setJWT(userDataTest['token']);
      setState(() {
        socialLoginLoading = false;
      });
      if (!error) {
        setSnackbar(msg!, context);
        final i = userDataTest["data"];
        id = i[ID];
        username = i[USERNAME];
        email = i[EMAIL];
        mobile = i[MOBILE];
        city = i[CITY];
        area = i[AREA];
        address = i[ADDRESS];
        pincode = i[pinCodeOrCityNameKey];
        latitude = i[LATITUDE];
        longitude = i[LONGITUDE];
        image = i[IMAGE];
        loginType = i[TYPE];
        final SettingProvider settingProvider =
            Provider.of<SettingProvider>(context, listen: false);
        settingProvider.setPrefrenceBool(ISFIRSTTIME, true);
        settingProvider.saveUserDetail(id!, username, email, mobile, city, area,
            address, pincode, latitude, longitude, image, loginType, context,);
        Future.delayed(Duration.zero, () {
          PushNotificationService(context: context).setDeviceToken(
              clearSesssionToken: true, settingProvider: settingProvider,);
        });
        offFavAdd().then((value) {
          db.clearFav();
          context.read<FavoriteProvider>().setFavlist([]);
          offCartAdd().then((value) {
            db.clearCart();
            offSaveAdd().then((value) {
              db.clearSaveForLater();
              if (widget.isPop) {
                if (widget.isRefresh != null) {
                  Navigator.pop(context, 'refresh');
                } else {
                  _getFav(context).whenComplete(() {
                    _getCart("0", context).whenComplete(() {
                      Future.delayed(const Duration(seconds: 2))
                          .whenComplete(() {
                        Navigator.of(context).pop();
                      });
                    });
                  });
                }
              } else {
                Navigator.pushAndRemoveUntil(context,
                    MaterialPageRoute(builder: (BuildContext context) {
                  Dashboard.dashboardScreenKey = GlobalKey<HomePageState>();
                  return widget.classType ??
                      Dashboard(
                        key: Dashboard.dashboardScreenKey,
                      );
                },), (route) => false,);
              }
            });
          });
        });
      } else {
        setSnackbar(msg!, context);
      }
      return userDataTest;
    } catch (e) {
      setState(() {
        socialLoginLoading = false;
      });
      print("login error*****$e");
      signOut(type);
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future<void> signOut(String type) async {
    _firebaseAuth.signOut();
    if (type == GOOGLE_TYPE) {
      _googleSignIn.signOut();
    } else {
      _firebaseAuth.signOut();
    }
  }

  Future<Map<String, dynamic>> socialSignInUser({required String type}) async {
    final Map<String, dynamic> result = {};
    try {
      print("Calling google signin $type");
      if (type == GOOGLE_TYPE) {
        final UserCredential? userCredential = await signInWithGoogle(context);
        print("Calling google signin $userCredential");
        if (userCredential != null) {
          result['user'] = userCredential.user;
        } else {
          throw ApiMessageAndCodeException(
              errorMessage: getTranslated(context, 'somethingMSg')!,);
        }
      } else if (type == APPLE_TYPE) {
        final UserCredential? userCredential = await signInWithApple(context);
        if (userCredential != null) {
          result['user'] = userCredential.user;
        } else {
          throw ApiMessageAndCodeException(
              errorMessage: getTranslated(context, 'somethingMSg')!,);
        }
      }
      print("user result***$result");
      return result;
    } on SocketException catch (_) {
      throw ApiMessageAndCodeException(
          errorMessage: getTranslated(context, 'somethingMSg')!,);
    } on FirebaseAuthException catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    } on PlatformException catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      setSnackbar(getTranslated(context, 'somethingSignMSG')!, context);
      return null;
    }
    final GoogleSignInAuthentication? googleAuth = await (await GoogleSignIn(
      scopes: ["profile", "email"],
    ).signIn())
        ?.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth!.accessToken,
      idToken: googleAuth.idToken,
    );
    final UserCredential userCredential =
        await _firebaseAuth.signInWithCredential(credential);
    return userCredential;
  }

  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<UserCredential?> signInWithApple(BuildContext context) async {
    try {
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );
      final UserCredential authResult =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      print('**********apple id:******$authResult');
      return authResult;
    } on FirebaseAuthException catch (authError) {
      print('**********errror id:******$authError');
      setSnackbar(authError.message!, context);
      return null;
    } on FirebaseException catch (e) {
      setSnackbar(e.toString(), context);
      return null;
    } catch (e) {
      final String errorMessage = e.toString();
      if (errorMessage == "Null check operator used on a null value") {
        setSnackbar(getTranslated(context, 'CANCEL_USER_MSG')!, context);
        return null;
      } else {
        setSnackbar(errorMessage, context);
        return null;
      }
    }
  }

  Widget socialLoginBtn() {
    return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 15),
        child: Column(
          children: [
            if (googleLogin == true)
              InkWell(
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  width: deviceWidth! * 0.85,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: Theme.of(context).colorScheme.white,),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/images/google_button.svg',
                        height: 22,
                        width: 22,
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 15),
                        child: Text(
                            getTranslated(context, 'CONTINUE_WITH_GOOGLE')!,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
                                    fontWeight: FontWeight.normal,),),
                      ),
                    ],
                  ),
                ),
                onTap: () async {
                  _isNetworkAvail = await isNetworkAvailable();
                  if (_isNetworkAvail) {
                    setState(() {
                      socialLoginLoading = true;
                    });
                    onTapSocialLogin(type: GOOGLE_TYPE);
                  } else {
                    Future.delayed(const Duration(seconds: 2)).then((_) async {
                      await buttonController!.reverse();
                      if (mounted) {
                        setState(() {
                          _isNetworkAvail = false;
                        });
                      }
                    });
                  }
                },
              ),
            if (appleLogin == true)
              if (Platform.isIOS)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: InkWell(
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      width: deviceWidth! * 0.85,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: Theme.of(context).colorScheme.white,),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/images/apple_logo.svg',
                            height: 22,
                            width: 22,
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.only(start: 8),
                            child: Text(
                                getTranslated(context, 'CONTINUE_WITH_APPLE')!,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
                                        fontWeight: FontWeight.normal,),),
                          ),
                        ],
                      ),
                    ),
                    onTap: () async {
                      if (acceptTnC) {
                        _isNetworkAvail = await isNetworkAvailable();
                        if (_isNetworkAvail) {
                          setState(() {
                            socialLoginLoading = true;
                          });
                          onTapSocialLogin(type: APPLE_TYPE);
                        } else {
                          Future.delayed(const Duration(seconds: 2))
                              .then((_) async {
                            await buttonController!.reverse();
                            if (mounted) {
                              setState(() {
                                _isNetworkAvail = false;
                              });
                            }
                          });
                        }
                      } else {
                        setSnackbar(
                            getTranslated(context, 'agreeTCFirst')!, context,);
                      }
                    },
                  ),
                ),
          ],
        ),);
  }

  Widget getLogo() {
    return Positioned(
      left: (MediaQuery.of(context).size.width / 2) - (150 / 2),
      top: (MediaQuery.of(context).size.height * 0.11) - 66,
      child: SizedBox(
        width: 150,
        height: 150,
        child: Image.asset(
          "assets/images/logo.PNG",
          ),
      ),
    );
  }

  Widget setSignInLabel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          getTranslated(context, 'SIGNIN_LBL')!,
          style: TextStyle(
            color: Theme.of(context).colorScheme.fontColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget setSignInDetail() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          getTranslated(context, 'SIGNIN_DETAILS')!,
          style: TextStyle(
            color: Theme.of(context).colorScheme.fontColor,
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
