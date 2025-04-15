import 'dart:async';
import 'package:customer/Helper/Color.dart';
import 'package:customer/Provider/SettingProvider.dart';
import 'package:customer/Screen/HomePage.dart';
import 'package:customer/ui/widgets/BehaviorWidget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../app/routes.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/widgets/AppBtn.dart';
import '../utils/blured_router.dart';

class VerifyOtp extends StatefulWidget {
  final String? mobileNumber;
  final String? countryCode;
  final String? title;
  static route(RouteSettings settings) {
    final Map? arguments = settings.arguments as Map?;
    return BlurredRouter(
      builder: (context) {
        return VerifyOtp(
          mobileNumber: arguments?['mobileNumber'],
          title: arguments?['title'],
          countryCode: arguments?['countryCode'],
        );
      },
    );
  }

  const VerifyOtp(
      {super.key,
      required String this.mobileNumber,
      this.countryCode,
      this.title,});
  @override
  _MobileOTPState createState() => _MobileOTPState();
}

class _MobileOTPState extends State<VerifyOtp> with TickerProviderStateMixin {
  final dataKey = GlobalKey();
  String? password;
  String? otp;
  bool isCodeSent = false;
  String _verificationId = '';
  String signature = "";
  bool _isClickable = false;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  @override
  void initState() {
    super.initState();
    getUserDetails();
    getSingature();
    _onVerifyCode();
    Future.delayed(const Duration(seconds: 60)).then((_) {
      _isClickable = true;
    });
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

  Future<void> getSingature() async {
    signature = await SmsAutoFill().getAppSignature;
    SmsAutoFill().listenForCode;
  }

  getUserDetails() async {
    if (mounted) setState(() {});
  }

  Future<void> checkNetworkOtp() async {
    final bool avail = await isNetworkAvailable();
    if (avail) {
      if (_isClickable) {
        _onVerifyCode();
      } else {
        setSnackbar(getTranslated(context, 'OTPWR')!, context);
      }
    } else {
      if (mounted) setState(() {});
      Future.delayed(const Duration(seconds: 60)).then((_) async {
        final bool avail = await isNetworkAvailable();
        if (avail) {
          if (_isClickable) {
            _onVerifyCode();
          } else {
            setSnackbar(getTranslated(context, 'OTPWR')!, context);
          }
        } else {
          await buttonController!.reverse();
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
        }
      });
    }
  }

  Widget verifyBtn() {
    return AppBtn(
      title: getTranslated(context, 'VERIFY_AND_PROCEED')!.toUpperCase(),
      btnAnim: buttonSqueezeanimation,
      btnCntrl: buttonController,
      onBtnSelected: () async {
        FocusScope.of(context).requestFocus(FocusNode());
        _onFormSubmitted();
      },
    );
  }

  Future<void> _onVerifyCode() async {
    if (mounted) {
      setState(() {
        isCodeSent = true;
      });
    }
    verificationCompleted(AuthCredential phoneAuthCredential) {
      _firebaseAuth
          .signInWithCredential(phoneAuthCredential)
          .then((UserCredential value) {
        if (value.user != null) {
          final SettingProvider settingsProvider =
              Provider.of<SettingProvider>(context, listen: false);
          setSnackbar(getTranslated(context, 'OTPMSG')!, context);
          if (widget.title == getTranslated(context, 'SEND_OTP_TITLE')) {
            Future.delayed(const Duration(seconds: 2)).then((_) {
              settingsProvider.setPrefrence(MOBILE, widget.mobileNumber!);
              settingsProvider.setPrefrence(COUNTRY_CODE, widget.countryCode!);
              Navigator.pushReplacementNamed(context, Routers.signupScreen);
            });
          } else if (widget.title ==
              getTranslated(context, 'FORGOT_PASS_TITLE')) {
            Future.delayed(const Duration(seconds: 2)).then((_) {
              settingsProvider.setPrefrence(MOBILE, widget.mobileNumber!);
              settingsProvider.setPrefrence(COUNTRY_CODE, widget.countryCode!);
              Navigator.pushNamed(context, Routers.setPassScreen,
                  arguments: {"mobileNumber": widget.mobileNumber!},);
            });
          }
        } else {
          setSnackbar(getTranslated(context, 'OTPERROR')!, context);
        }
      }).catchError((error) {
        setSnackbar(error.toString(), context);
      });
    }

    verificationFailed(FirebaseAuthException authException) {
      if (mounted) {
        setState(() {
          isCodeSent = false;
        });
      }
    }

    codeSent(String? verificationId, [int? forceResendingToken]) async {
      _verificationId = verificationId!;
      if (mounted) {
        setState(() {
          _verificationId = verificationId;
        });
      }
    }

    codeAutoRetrievalTimeout(String? verificationId) {
      _verificationId = verificationId!;
      if (mounted) {
        setState(() {
          _isClickable = true;
          _verificationId = verificationId;
        });
      }
    }

    if (isFirebaseAuth!) {
      await _firebaseAuth.verifyPhoneNumber(
          phoneNumber: "+${widget.countryCode}${widget.mobileNumber}",
          timeout: const Duration(seconds: 60),
          verificationCompleted: verificationCompleted,
          verificationFailed: verificationFailed,
          codeSent: codeSent,
          codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,);
    }
  }

  Future<void> _onFormSubmitted() async {
    final String code = otp!.trim();
    if (code.length == 6) {
      _playAnimation();
      if (isFirebaseAuth!) {
        final AuthCredential authCredential = PhoneAuthProvider.credential(
            verificationId: _verificationId, smsCode: code,);
        _firebaseAuth
            .signInWithCredential(authCredential)
            .then((UserCredential value) async {
          if (value.user != null) {
            final SettingProvider settingsProvider =
                Provider.of<SettingProvider>(context, listen: false);
            await buttonController!.reverse();
            setSnackbar(getTranslated(context, 'OTPMSG')!, context);
            settingsProvider.setPrefrence(MOBILE, widget.mobileNumber!);
            settingsProvider.setPrefrence(COUNTRY_CODE, widget.countryCode!);
            if (widget.title == getTranslated(context, 'SEND_OTP_TITLE')) {
              Future.delayed(const Duration(seconds: 2)).then((_) {
                Navigator.pushReplacementNamed(context, Routers.signupScreen);
              });
            } else if (widget.title ==
                getTranslated(context, 'FORGOT_PASS_TITLE')) {
              Future.delayed(const Duration(seconds: 2)).then((_) {
                Navigator.pushNamed(context, Routers.setPassScreen,
                    arguments: {"mobileNumber": widget.mobileNumber!},);
              });
            }
          } else {
            setSnackbar(getTranslated(context, 'OTPERROR')!, context);
            await buttonController!.reverse();
          }
        }).catchError((error) async {
          setSnackbar(getTranslated(context, 'WRONGOTP')!, context);
          await buttonController!.reverse();
        });
      } else {
        final response = await apiBaseHelper.postAPICall(
            verifyOtp, {"mobile": widget.mobileNumber, "otp": code},);
        if (!response['error']) {
          final SettingProvider settingsProvider =
              Provider.of<SettingProvider>(context, listen: false);
          await buttonController!.reverse();
          setSnackbar(getTranslated(context, 'OTPMSG')!, context);
          settingsProvider.setPrefrence(MOBILE, widget.mobileNumber!);
          settingsProvider.setPrefrence(COUNTRY_CODE, widget.countryCode!);
          if (widget.title == getTranslated(context, 'SEND_OTP_TITLE')) {
            Future.delayed(const Duration(seconds: 2)).then((_) {
              Navigator.pushReplacementNamed(context, Routers.signupScreen);
            });
          } else if (widget.title ==
              getTranslated(context, 'FORGOT_PASS_TITLE')) {
            Future.delayed(const Duration(seconds: 2)).then((_) {
              Navigator.pushNamed(context, Routers.setPassScreen,
                  arguments: {"mobileNumber": widget.mobileNumber!},);
            });
          }
        } else {
          setSnackbar(getTranslated(context, 'OTPERROR')!, context);
          await buttonController!.reverse();
        }
      }
    } else {
      setSnackbar(getTranslated(context, 'ENTEROTP')!, context);
    }
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {
      return;

    }
  }

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  monoVarifyText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(getTranslated(context, 'MOBILE_NUMBER_VARIFICATION')!,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,),),
      ),
    );
  }

  otpText() {
    return Padding(
        padding:
            const EdgeInsetsDirectional.only(top: 15.0, bottom: 5.0, start: 12),
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
            getTranslated(context, 'SENT_VERIFY_CODE_TO_NO_LBL')!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.normal,),
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            maxLines: 1,
          ),
        ),);
  }

  mobText() {
    return Padding(
      padding:
          const EdgeInsetsDirectional.only(bottom: 20.0, end: 12.0, start: 12),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text("+${widget.countryCode}-${widget.mobileNumber}",
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.normal,),),
      ),
    );
  }

  Widget otpLayout() {
    return Padding(
      padding:
          const EdgeInsetsDirectional.only(bottom: 20.0, end: 12.0, start: 12),
      child: PinFieldAutoFill(
          decoration: BoxLooseDecoration(
            bgColorBuilder:
                FixedColorBuilder(Theme.of(context).colorScheme.white),
            gapSpace: 10,
            hintText: '000000',
            hintTextStyle: TextStyle(
              fontSize: 20,
              color: Theme.of(context).colorScheme.lightBlack2,
            ),
            textStyle: TextStyle(
                fontSize: 20, color: Theme.of(context).colorScheme.fontColor,),
            strokeColorBuilder:
                FixedColorBuilder(Theme.of(context).colorScheme.white),
          ),
          currentCode: otp,
          onCodeChanged: (String? code) {
            otp = code;
          },
          onCodeSubmitted: (String code) {
            otp = code;
          },),
    );
  }

  Widget resendText() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
          bottom: 30.0, start: 25.0, end: 25.0, top: 10.0,),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            getTranslated(context, 'DIDNT_GET_THE_CODE')!,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.bold,),
          ),
          InkWell(
              onTap: () async {
                await buttonController!.reverse();
                if (isFirebaseAuth == true) {
                  checkNetworkOtp();
                } else {
                  final response = await apiBaseHelper.postAPICall(
                      resendOtpApi, {"mobile": "${widget.mobileNumber}"},);
                  final getdata = response;
                  if (getdata['error']) {
                    setSnackbar(getdata['message'], context);
                    setState(() {
                      isCodeSent = false;
                    });
                  } else {
                    setState(() {
                      isCodeSent = true;
                    });
                    setSnackbar(getTranslated(context, "otpsendSuccessfully")!,
                        context,);
                  }
                }
              },
              child: Text(
                getTranslated(context, 'RESEND_OTP')!,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.primarytheme,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold,),
              ),),
        ],
      ),
    );
  }

  expandedBottomView() {
    return Expanded(
      flex: 6,
      child: Container(
        alignment: Alignment.bottomCenter,
        child: ScrollConfiguration(
            behavior: MyBehavior(),
            child: SingleChildScrollView(
              child: Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),),
                margin:
                    const EdgeInsetsDirectional.only(start: 20.0, end: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    monoVarifyText(),
                    otpText(),
                    mobText(),
                    otpLayout(),
                    const SizedBox(
                      height: 10,
                    ),
                    verifyBtn(),
                    resendText(),
                  ],
                ),
              ),
            ),),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            backBtn(),
            getLoginContainer(),
          ],
        ),);
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
                  monoVarifyText(),
                  otpText(),
                  mobText(),
                  otpLayout(),
                  const SizedBox(
                    height: 10,
                  ),
                  verifyBtn(),
                  resendText(),
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
      left: (MediaQuery.of(context).size.width / 2) - 50,
      top: (MediaQuery.of(context).size.height * 0.2) - 50,
      child: SizedBox(
        width: 100,
        height: 100,
        child: SvgPicture.asset(getThemeColor(context)),
      ),
    );
  }
}
