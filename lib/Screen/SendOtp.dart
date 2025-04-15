import 'dart:async';
import 'package:customer/Helper/Constant.dart';
import 'package:customer/Helper/String.dart';
import 'package:customer/Provider/SettingProvider.dart';
import 'package:customer/Screen/Privacy_Policy.dart';
import 'package:customer/app/routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';
import '../Helper/Color.dart';
import '../Helper/Session.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/styles/Validators.dart';
import '../ui/widgets/AppBtn.dart';
import '../ui/widgets/BehaviorWidget.dart';
import '../utils/Hive/hive_utils.dart';
import '../utils/blured_router.dart';
import 'HomePage.dart';
import 'Verify_Otp.dart';

class SendOtp extends StatefulWidget {
  String? title;
  static route(RouteSettings settings) {
    final Map? arguments = settings.arguments as Map?;
    return BlurredRouter(
      builder: (context) {
        return SendOtp(
          title: arguments?['title'],
        );
      },
    );
  }

  SendOtp({super.key, this.title});
  @override
  _SendOtpState createState() => _SendOtpState();
}

class _SendOtpState extends State<SendOtp> with TickerProviderStateMixin {
  bool visible = false;
  final mobileController = TextEditingController();
  final ccodeController = TextEditingController();
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  String? mobile;
  String? id;
  String? countrycode;
  String? countryName;
  String? mobileno;
  bool _isNetworkAvail = true;
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool acceptTnC = true;
  Future<void> validateAndSubmit() async {
    if (validateAndSave()) {
      if (widget.title != getTranslated(context, 'SEND_OTP_TITLE')) {
        _playAnimation();
        checkNetwork();
      } else {
        if (acceptTnC) {
          _playAnimation();
          checkNetwork();
        } else {
          setSnackbar(getTranslated(context, 'TnCNOTACCEPTED')!, context);
        }
      }
    }
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {
      return;

    }
  }

  Future<void> checkNetwork() async {
    final bool avail = await isNetworkAvailable();
    if (avail) {
      getVerifyUser();
    } else {
      Future.delayed(const Duration(seconds: 2)).then((_) async {
        if (mounted) {
          setState(() {
            _isNetworkAvail = false;
          });
        }
        await buttonController!.reverse();
      });
    }
  }

  bool validateAndSave() {
    final form = _formkey.currentState!;
    form.save();
    if (form.validate()) {
      if (mobileController.text.trim().isEmpty) {
        setSnackbar(getTranslated(context, 'MOB_REQUIRED')!, context);
        return false;
      }
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  Widget noInternet(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: kToolbarHeight),
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

  Future<void> getVerifyUser() async {
    try {
      final data = {
        MOBILE: mobile,
        "is_forgot_password":
            (widget.title == getTranslated(context, 'FORGOT_PASS_TITLE')
                    ? 1
                    : 0)
                .toString(),
      };
      apiBaseHelper.postAPICall(getVerifyUserApi, data).then((getdata) async {
        final bool? error = getdata["error"];
        final String? msg = getdata["message"];
        await buttonController!.reverse();
        final SettingProvider settingsProvider =
            Provider.of<SettingProvider>(context, listen: false);
        if (widget.title == getTranslated(context, 'SEND_OTP_TITLE')) {
          if (!error!) {
            setSnackbar(msg!, context);
            Future.delayed(const Duration(seconds: 1)).then((_) {
              Navigator.push(
                  context,
                  CupertinoPageRoute(
                      builder: (context) => VerifyOtp(
                            mobileNumber: mobile!,
                            countryCode: countrycode,
                            title: getTranslated(context, 'SEND_OTP_TITLE'),
                          ),),);
            });
          } else {
            setSnackbar(msg!, context);
          }
        }
        if (widget.title == getTranslated(context, 'FORGOT_PASS_TITLE')) {
          if (!error!) {
            Future.delayed(const Duration(seconds: 1)).then((_) {
              Navigator.push(
                  context,
                  CupertinoPageRoute(
                      builder: (context) => VerifyOtp(
                            mobileNumber: mobile!,
                            countryCode: countrycode,
                            title: getTranslated(context, 'FORGOT_PASS_TITLE'),
                          ),),);
            });
          } else {
            setSnackbar(getTranslated(context, 'FIRSTSIGNUP_MSG')!, context);
          }
        }
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      },);
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      await buttonController!.reverse();
    }
    return;
  }

  createAccTxt() {
    return Padding(
        padding: const EdgeInsets.only(
          top: 30.0,
        ),
        child: Align(
          child: Text(
            widget.title == getTranslated(context, 'SEND_OTP_TITLE')
                ? getTranslated(context, 'CREATE_ACC_LBL')!
                : getTranslated(context, 'FORGOT_PASSWORDTITILE')!,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.bold,),
          ),
        ),);
  }

  Widget verifyCodeTxt() {
    return Padding(
        padding: const EdgeInsets.only(top: 15.0, bottom: 20.0),
        child: Align(
          child: Text(
            getTranslated(context, 'SEND_VERIFY_CODE_LBL')!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: Theme.of(context).colorScheme.fontColor,
                  fontWeight: FontWeight.normal,
                ),
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            maxLines: 1,
          ),
        ),);
  }

  setCodeWithMono() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 15, end: 15),
      child: IntlPhoneField(
        style: Theme.of(context).textTheme.titleSmall!.copyWith(
            color: Theme.of(context).colorScheme.fontColor,
            fontWeight: FontWeight.normal,),
        controller: mobileController,
        decoration: InputDecoration(
          hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: Theme.of(context).colorScheme.fontColor.withOpacity(0.6),
              fontWeight: FontWeight.normal,),
          hintText: getTranslated(context, 'MOBILEHINT_LBL'),
          border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(10),),
          fillColor: Theme.of(context).colorScheme.white,
          filled: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        ),
        initialCountryCode: defaultCountryCode,
        onSaved: (phoneNumber) {
          setState(() {
            countrycode =
                phoneNumber!.countryCode.replaceFirst('+', '');
            mobile = phoneNumber.number;
          });
        },
        onCountryChanged: (country) {
          setState(() {
            countrycode = country.dialCode;
          });
        },
        autofocus: true,
        validator: (val) => validateMobIntl(
            val,
            getTranslated(context, 'MOB_REQUIRED'),
            getTranslated(context, 'VALID_MOB'),),
        onChanged: (phone) {},
        showDropdownIcon: false,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        flagsButtonMargin: const EdgeInsets.only(left: 20, right: 20),
        pickerDialogStyle: PickerDialogStyle(
          countryNameStyle:
              TextStyle(color: Theme.of(context).colorScheme.fontColor),
          padding: const EdgeInsets.only(left: 10, right: 10),
        ),
      ),
    );
  }

  Widget setMono() {
    return TextFormField(
        keyboardType: TextInputType.number,
        controller: mobileController,
        style: Theme.of(context).textTheme.titleSmall!.copyWith(
            color: Theme.of(context).colorScheme.fontColor,
            fontWeight: FontWeight.normal,),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (val) => validateMob(
            val!,
            getTranslated(context, 'MOB_REQUIRED'),
            getTranslated(context, 'VALID_MOB'),),
        onSaved: (String? value) {
          mobile = value;
        },
        decoration: InputDecoration(
          hintText: getTranslated(context, 'MOBILEHINT_LBL'),
          hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: Theme.of(context).colorScheme.fontColor,
              fontWeight: FontWeight.normal,),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          focusedBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.primarytheme),
            borderRadius: BorderRadius.circular(7.0),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.lightBlack2),
            borderRadius: BorderRadius.circular(7.0),
          ),
        ),);
  }

  Widget verifyBtn() {
    return AppBtn(
        title: widget.title == getTranslated(context, 'SEND_OTP_TITLE')
            ? getTranslated(context, 'SEND_OTP')!.toUpperCase()
            : getTranslated(context, 'CONTINUE')!.toUpperCase(),
        btnAnim: buttonSqueezeanimation,
        btnCntrl: buttonController,
        onBtnSelected: () async {
          FocusScope.of(context).requestFocus(FocusNode());
          validateAndSubmit();
        },);
  }

  getSignUpText() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
          bottom: 20.0, start: 25.0, end: 25.0, top: 20.0,),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(getTranslated(context, 'ALREADY_HAVE_AN_ACC')!,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.fontColor,
                  fontWeight: FontWeight.bold,),),
          InkWell(
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                    context,
                    Routers.loginScreen,
                    arguments: {"isPop": false},
                    (route) => false,);
              },
              child: Text(
                getTranslated(context, 'SIGNIN_LBL')!,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.primarytheme,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold,),
              ),),
        ],
      ),
    );
  }

  Widget termAndPolicyTxt() {
    return widget.title == getTranslated(context, 'SEND_OTP_TITLE')
        ? Padding(
            padding: const EdgeInsets.only(
              top: 250,
              left: 40.0,
              right: 40.0,
            ),
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
                              text:
                                  getTranslated(context, 'CONTINUE_AGREE_LBL'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
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
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
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
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
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
                                        title:
                                            getTranslated(context, 'PRIVACY'),
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
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
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
          )
        : const SizedBox.shrink();
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
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: _isNetworkAvail
            ? Stack(
                children: [
                  backBtn(),
                  getLogo(),
                  getLoginContainer(),
                ],
              )
            : noInternet(context),);
  }

  getLoginContainer() {
    return Positioned.directional(
      start: MediaQuery.of(context).size.width * 0.025,
      end: MediaQuery.of(context).size.width * 0.025,
      top: MediaQuery.of(context).size.height * 0.25,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        widget.title == getTranslated(context, 'SEND_OTP_TITLE')
                            ? getTranslated(context, 'SIGN_UP_LBL')!
                            : getTranslated(context, 'FORGOT_PASSWORDTITILE')!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  verifyCodeTxt(),
                  setCodeWithMono(),
                  const SizedBox(
                    height: 10,
                  ),
                  verifyBtn(),
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

  Widget getLogo() {
    return Positioned(
      left: (MediaQuery.of(context).size.width / 2) - (150 / 2),
      top: (MediaQuery.of(context).size.height * 0.11) - 40,
      
      child: SizedBox(
        width: 150,
        height: 150,
        child: Image.asset(
          "assets/images/logo.PNG",
          ),
      ),
    );
  }
}

String getToken() {
  return HiveUtils.getJWT() ?? "";
}

Map<String, String> get headers => {
      "Authorization": 'Bearer ${getToken()}',
    };
