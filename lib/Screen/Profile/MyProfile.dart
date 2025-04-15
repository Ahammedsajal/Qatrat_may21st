import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:customer/Helper/ApiBaseHelper.dart';
import 'package:customer/Helper/Color.dart';
import 'package:customer/Helper/Session.dart';
import 'package:customer/Helper/String.dart';
import 'package:customer/Helper/routes.dart';
import 'package:customer/Provider/CartProvider.dart';
import 'package:customer/Provider/FavoriteProvider.dart';
import 'package:customer/Provider/SettingProvider.dart';
import 'package:customer/Provider/UserProvider.dart';
import 'package:customer/Screen/customer_Support.dart';
import 'package:customer/Screen/Faqs.dart';
import 'package:customer/Screen/HomePage.dart';
import 'package:customer/Screen/Privacy_Policy.dart';
import 'package:customer/Screen/Profile/widget/editProfileBottomSheet.dart';
import 'package:customer/Screen/ReferEarn.dart';
import 'package:customer/app/languages.dart';
import 'package:customer/app/routes.dart';
import '../about_us.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';
import '../PrivacyScreen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Helper/Constant.dart';
import '../../../Provider/Theme.dart';
import '../../../main.dart';
import '../../../ui/styles/DesignConfig.dart';
import '../../../ui/styles/Validators.dart';
import '../../../ui/widgets/AppBtn.dart';
import '../../../utils/Hive/hive_utils.dart';


class MyProfile extends StatefulWidget {
  const MyProfile({super.key});
  @override
  State<StatefulWidget> createState() => StateProfile();
}

class StateProfile extends State<MyProfile> with TickerProviderStateMixin {
  final InAppReview _inAppReview = InAppReview.instance;
  var isDarkTheme;
  bool isDark = false;
  late ThemeNotifier themeNotifier;
  Languages languages = Languages();
  late List<String> langCode = languages.codesString();
  List<String?> themeList = [];
  late List<String?> languageList = languages.getNameList();
  late List<String?> sublanguageList = languages.getSubNameList();
  final GlobalKey<FormState> _formkey1 = GlobalKey<FormState>();
  int? selectLan;
  int? curTheme;
  String? curPass;
  String? newPass;
  String? confPass;
  String? pass;
  String? mob;
  final GlobalKey<FormState> _changePwdKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _changeUserDetailsKey = GlobalKey<FormState>();
  final confirmpassController = TextEditingController();
  final newpassController = TextEditingController();
  final passwordController = TextEditingController();
  final passController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  String? currentPwd;
  String? newPwd;
  String? confirmPwd;
  FocusNode confirmPwdFocus = FocusNode();
  File? image;
  bool _isNetworkAvail = true;
  late Function sheetSetState;
  bool countDownComplete = false;
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  final ScrollController _scrollBottomBarController = ScrollController();
  bool isLoading = false;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  Animation? buttonSqueezeanimation1;
  AnimationController? buttonController1;
  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      _getSaved();
      buttonController1 = AnimationController(
          duration: const Duration(milliseconds: 2000), vsync: this,);
      buttonSqueezeanimation1 = Tween(
        begin: deviceWidth! * 0.7,
        end: 50.0,
      ).animate(CurvedAnimation(
        parent: buttonController1!,
        curve: const Interval(
          0.0,
          0.150,
        ),
      ),);
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
    });
    super.initState();
  }

  _getSaved() async {
    final SettingProvider settingsProvider =
        Provider.of<SettingProvider>(context, listen: false);
    mob = await settingsProvider.getPrefrence(MOBILE) ?? '';
    context
        .read<UserProvider>()
        .setUserId(await settingsProvider.getPrefrence(ID) ?? '');
    nameController.text = context.read<UserProvider>().curUserName;
    emailController.text = context.read<UserProvider>().email;
    mobileController.text = context.read<UserProvider>().mob;
    print("mobile controller***${mobileController.text}");
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? get = prefs.getString(APP_THEME);
    curTheme = themeList.indexOf(get == '' || get == DEFAULT_SYSTEM
        ? getTranslated(context, 'SYSTEM_DEFAULT')
        : get == LIGHT
            ? getTranslated(context, 'LIGHT_THEME')
            : getTranslated(context, 'DARK_THEME'),);
    final String getlng = await settingsProvider.getPrefrence(LAGUAGE_CODE) ?? '';
    selectLan = langCode.indexOf(getlng == '' ? "en" : getlng);
    if (mounted) setState(() {});
  }

  _getHeader() {
    return Padding(
        padding: const EdgeInsetsDirectional.only(bottom: 10.0, top: 10),
        child: Container(
          padding: const EdgeInsetsDirectional.only(
            start: 10.0,
          ),
          child: Row(
            children: [
              Selector<UserProvider, String>(
                  selector: (_, provider) => provider.profilePic,
                  builder: (context, profileImage, child) {
                    return getUserImage(
                        profileImage, () => openEditBottomSheet(context),);
                  },),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Selector<UserProvider, String>(
                      selector: (_, provider) => provider.curUserName,
                      builder: (context, userName, child) {
                        nameController = TextEditingController(text: userName);
                        return Text(
                          userName == ""
                              ? getTranslated(context, 'GUEST')!
                              : userName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(
                                color: Theme.of(context).colorScheme.fontColor,
                              ),
                        );
                      },),
                  Selector<UserProvider, String>(
                      selector: (_, provider) => provider.mob,
                      builder: (context, userMobile, child) {
                        mobileController =
                            TextEditingController(text: userMobile);
                        return userMobile != ""
                            ? Text(
                                userMobile,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
                                        fontWeight: FontWeight.normal,),
                              )
                            : Container(
                                height: 0,
                              );
                      },),
                  Selector<UserProvider, String>(
                      selector: (_, provider) => provider.email,
                      builder: (context, userEmail, child) {
                        emailController =
                            TextEditingController(text: userEmail);
                        return userEmail != ""
                            ? Text(
                                userEmail,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
                                        fontWeight: FontWeight.normal,),
                              )
                            : Container(
                                height: 0,
                              );
                      },),
                  Consumer<UserProvider>(builder: (context, userProvider, _) {
                    return userProvider.curUserName == ""
                        ? Padding(
                            padding: const EdgeInsetsDirectional.only(top: 7),
                            child: InkWell(
                              child: Text(
                                  getTranslated(context, 'LOGIN_REGISTER_LBL')!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primarytheme,
                                        decoration: TextDecoration.underline,
                                      ),),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  Routers.loginScreen,
                                  arguments: {
                                    "isPop": true,
                                    "classType": const MyProfile(),
                                  },
                                );
                              },
                            ),)
                        : const SizedBox.shrink();
                  },),
                ],
              ),
            ],
          ),
        ),);
  }

  List<Widget> getLngList(BuildContext ctx) {
    return languageList
        .asMap()
        .map(
          (index, element) => MapEntry(
              index,
              InkWell(
                onTap: () {
                  if (mounted) {
                    selectLan = index;
                    _changeLan(langCode[index], ctx);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 25.0,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selectLan == index
                                    ? Theme.of(context).colorScheme.primarytheme
                                    : Theme.of(ctx).colorScheme.white,
                                border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primarytheme,),),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: selectLan == index
                                  ? Icon(
                                      Icons.check,
                                      size: 17.0,
                                      color: Theme.of(ctx).colorScheme.white,
                                    )
                                  : Icon(
                                      Icons.check_box_outline_blank,
                                      size: 17.0,
                                      color: Theme.of(ctx).colorScheme.white,
                                    ),
                            ),
                          ),
                          Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 30.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    languageList[index]!,
                                    style: Theme.of(ctx)
                                        .textTheme
                                        .titleSmall!
                                        .copyWith(
                                            color: Theme.of(ctx)
                                                .colorScheme
                                                .lightBlack,),
                                  ),
                                  Text(
                                    sublanguageList[index]!,
                                    style: Theme.of(ctx)
                                        .textTheme
                                        .titleSmall!
                                        .copyWith(
                                            color: Theme.of(ctx)
                                                .colorScheme
                                                .lightBlack,),
                                  ),
                                ],
                              ),),
                        ],
                      ),
                    ],
                  ),
                ),
              ),),
        )
        .values
        .toList();
  }

  Future<void> _changeLan(String language, BuildContext ctx) async {
    final Locale locale = await setLocale(language);
    MyApp.setLocale(ctx, locale);
  }

  Future<void> setUpdateUser(String userID,
      [oldPwd, newPwd, username, userEmail, userMob,]) async {
    final apiBaseHelper = ApiBaseHelper();
    final data = {USER_ID: userID};
    if ((oldPwd != "") && (newPwd != "")) {
      data[OLDPASS] = oldPwd;
      data[NEWPASS] = newPwd;
    }
    if (username != "") {
      data[USERNAME] = username;
    }
    if (userEmail != "") {
      data[EMAIL] = userEmail;
    }
    if (userMob != "") {
      data[MOBILE] = userMob;
    }
    print("profile data****$data");
    final Map<String, dynamic> result =
        await apiBaseHelper.postAPICall(getUpdateUserApi, data);
    print("profileupdate--result-->$result");
    final bool error = result["error"];
    final String? msg = result["message"];
    await buttonController1!.reverse();
    Navigator.of(context).pop();
    if (!error) {
      final settingProvider =
          Provider.of<SettingProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (username != "") {
        setState(() {
          settingProvider.setPrefrence(USERNAME, username);
          userProvider.setName(username);
        });
      }
      if (userEmail != "") {
        setState(() {
          settingProvider.setPrefrence(EMAIL, userEmail);
          userProvider.setEmail(userEmail);
        });
      }
      if (userMob != "") {
        setState(() {
          settingProvider.setPrefrence(MOBILE, userMob);
          userProvider.setMobile(userMob);
        });
      }
      setSnackbar(getTranslated(context, 'USER_UPDATE_MSG')!, context);
    } else {
      setSnackbar(msg!, context);
    }
    context.read<UserProvider>().setProgress(false);
  }

  _getDrawer() {
    return ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      children: <Widget>[
        
        
       
         _getDrawerItem(getTranslated(context, 'ABOUT_LBL')!,
            'assets/images/pro_aboutus.svg',),
             _getDrawerItem(getTranslated(context, 'CONTACT_LBL')!,
            'assets/images/pro_contact_us.svg',),
       // if (context.read<UserProvider>().userId == "") const SizedBox.shrink() else _getDrawerItem(getTranslated(context, 'MYTRANSACTION')!,
          //      'assets/images/pro_th.svg',),
        if (disableDarkTheme == false) ...{
          _getDrawerItem(getTranslated(context, 'CHANGE_THEME_LBL')!,
              'assets/images/pro_theme.svg',),
        },
        _getDrawerItem(getTranslated(context, 'CHANGE_LANGUAGE_LBL')!,
            'assets/images/pro_language.svg',),
        if (context.read<UserProvider>().userId == "" ||
                context.read<UserProvider>().loginType != PHONE_TYPE) const SizedBox.shrink() else _getDrawerItem(getTranslated(context, 'CHANGE_PASS_LBL')!,
                'assets/images/pro_pass.svg',),
        
        if (context.read<UserProvider>().userId == "") const SizedBox.shrink() else _getDrawerItem(getTranslated(context, 'customer_SUPPORT')!,
                'assets/images/pro_customersupport.svg',),
        
       
       
        _getDrawerItem(
            getTranslated(context, 'FAQS')!, 'assets/images/pro_faq.svg',),
        _getDrawerItem(
            getTranslated(context, 'PRIVACY')!, 'assets/images/pro_pp.svg',),
        _getDrawerItem(
            getTranslated(context, 'TERM')!, 'assets/images/pro_tc.svg',),
       
       
        _getDrawerItem(
            getTranslated(context, 'RATE_US')!, 'assets/images/pro_rateus.svg',),
        _getDrawerItem(getTranslated(context, 'SHARE_APP')!,
            'assets/images/pro_share.svg',),
        if (context.read<UserProvider>().userId == "") const SizedBox.shrink() else _getDrawerItem(getTranslated(context, 'DEL_ACC_LBL')!, ''),
        if (context.read<UserProvider>().userId == "") const SizedBox.shrink() else _getDrawerItem(getTranslated(context, 'LOGOUT')!,
                'assets/images/pro_logout.svg',),
        const SizedBox(
          height: 45,
        ),
      ],
    );
  }

  _getDrawerItem(String title, String img) {
    return Card(
      elevation: 0,
      child: ListTile(
        trailing: Icon(
          Icons.navigate_next,
          color: Theme.of(context).colorScheme.blackInverseInDarkTheme,
        ),
        dense: false,
        leading: title == getTranslated(context, 'DEL_ACC_LBL')
            ? Icon(
                Icons.delete,
                size: 25,
                color: Theme.of(context).colorScheme.primarytheme,
              )
            : SvgPicture.asset(
                img,
                height: 25,
                width: 25,
                colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.primarytheme,
                    BlendMode.srcIn,),
              ),
        title: Text(
          title,
          style: TextStyle(
              color: Theme.of(context).colorScheme.lightBlack,
              fontSize: 15,
              fontWeight: FontWeight.normal,),
        ),
        onTap: () {
          if (title == getTranslated(context, 'MY_ORDERS_LBL')) {
            Navigator.pushNamed(context, Routers.myOrderScreen);
          } else if (title == getTranslated(context, 'MYTRANSACTION')) {
            Navigator.pushNamed(context, Routers.transactionHistoryScreen);
          }  else if (title == getTranslated(context, 'YOUR_PROM_CO')) {
            Navigator.pushNamed(context, Routers.promoCodeScreen,
                arguments: {"from": "Profile"},);
          } else if (title == getTranslated(context, 'MANAGE_ADD_LBL')) {
            Navigator.pushNamed(context, Routers.manageAddressScreen,
                arguments: {
                  "home": true,
                },);
          } else if (title == getTranslated(context, 'CONTACT_LBL')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'CONTACT_LBL'),
                  ),
                ),);
          } else if (title == getTranslated(context, 'CHAT')) {
            Routes.navigateToConverstationListScreen(context);
          } else if (title == getTranslated(context, 'customer_SUPPORT')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (context) => const customerSupport(),),);
          } else if (title == getTranslated(context, 'TERM')) {
           Navigator.pushNamed(context, Routers.termsScreen, arguments: {
  'title': getTranslated(context, 'TERM'),
});



        } else if (title == getTranslated(context, 'PRIVACY')) {
  Navigator.pushNamed(
  context,
  Routers.privacyPolicyScreen,
  arguments: {
    'title': getTranslated(context, 'PRIVACY'),
    'type': PRIVACY_POLICY,
  },
);

}

 else if (title == getTranslated(context, 'RATE_US')) {
            _openStoreListing();
          } else if (title == getTranslated(context, 'SHARE_APP')) {
            final str =
                "$appName\n\n${getTranslated(context, 'APPFIND')}$androidLink$packageName\n\n ${getTranslated(context, 'IOSLBL')}\n$iosLink";
            Share.share(str,
                sharePositionOrigin: Rect.fromLTWH(
                    0,
                    0,
                    MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height / 2,),);
          } else if (title == getTranslated(context, 'ABOUT_LBL')) {
           Navigator.push(
  context,
  CupertinoPageRoute(
    builder: (context) => AboutUs(
      title: getTranslated(context, 'ABOUT_LBL'),
    ),
  ),
);

          } else if (title == getTranslated(context, 'SHIPPING_PO_LBL')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'SHIPPING_PO_LBL'),
                  ),
                ),);
          } else if (title == getTranslated(context, 'RETURN_PO_LBL')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'RETURN_PO_LBL'),
                  ),
                ),);
          } else if (title == getTranslated(context, 'FAQS')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => Faqs(
                    title: getTranslated(context, 'FAQS'),
                  ),
                ),);
          } else if (title == getTranslated(context, 'CHANGE_THEME_LBL')) {
            openChangeThemeBottomSheet();
          } else if (title == getTranslated(context, 'LOGOUT')) {
            logOutDailog(context);
          } else if (title == getTranslated(context, 'CHANGE_PASS_LBL')) {
            openChangePasswordBottomSheet();
          } else if (title == getTranslated(context, 'CHANGE_LANGUAGE_LBL')) {
            openChangeLanguageBottomSheet();
          } else if (title == getTranslated(context, 'DEL_ACC_LBL')) {
            _showDialog();
          }
        },
      ),
    );
  }

  void changeVal() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        if (!countDownComplete) {
          sheetSetState(() {
            countDownComplete = true;
          });
        }
      }
    });
  }

  _showDialog() async {
    changeVal();
    await showGeneralDialog(
        barrierColor: Theme.of(context).colorScheme.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          return Transform.scale(
            scale: a1.value,
            child: Opacity(opacity: a1.value, child: deleteConfirmDailog()),
          );
        },
        barrierDismissible: true,
        barrierLabel: '',
        context: context,
        pageBuilder: (context, animation1, animation2) {
          return const SizedBox.shrink();
        },).then((value) {
      if (countDownComplete) {
        sheetSetState(() {
          countDownComplete = false;
        });
      }
    });
  }

  deleteConfirmDailog() {
    int from = 0;
    return AlertDialog(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),),
      title: Text(
        getTranslated(context, 'DEL_YR_ACC_LBL')!,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
      ),
      content: StatefulBuilder(builder: (context, StateSetter setStater) {
        sheetSetState = setStater;
        return Form(
          key: _formkey1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                from == 0
                    ? getTranslated(context, 'DEL_WHOLE_TXT_LBL')!
                    : getTranslated(context, 'ADD_PASS_DEL_LBL')!,
                textAlign: TextAlign.center,
                style: Theme.of(this.context)
                    .textTheme
                    .titleSmall!
                    .copyWith(color: Theme.of(context).colorScheme.fontColor),
              ),
              if (from == 1)
                Padding(
                    padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),),
                      height: 50,
                      child: TextFormField(
                        controller: passController,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: Theme.of(context).colorScheme.fontColor,),
                        onSaved: (val) {
                          setStater(() {
                            pass = val;
                          });
                        },
                        validator: (val) => validatePass(
                            val!,
                            getTranslated(context, 'PWD_REQUIRED'),
                            getTranslated(context, 'PASSWORD_VALIDATION'),
                            from: 123,),
                        enabled: true,
                        textAlign: TextAlign.left,
                        decoration: InputDecoration(
                          errorMaxLines: 4,
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.gray,),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10.0),
                            ),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                            borderRadius: BorderRadius.all(
                              Radius.circular(10.0),
                            ),
                          ),
                          contentPadding:
                              const EdgeInsets.fromLTRB(15.0, 10.0, 10, 10.0),
                          border: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                            borderRadius: BorderRadius.all(
                              Radius.circular(10.0),
                            ),
                          ),
                          fillColor: Theme.of(context).colorScheme.gray,
                          filled: true,
                          isDense: true,
                          hintText: getTranslated(context, 'PASSHINT_LBL'),
                          hintStyle:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .fontColor
                                        .withOpacity(0.7),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w400,
                                    fontStyle: FontStyle.normal,
                                  ),
                        ),
                      ),
                    ),),
              Padding(
                padding: const EdgeInsets.only(bottom: 15.0, top: 20),
                child: from == 0
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                  padding: const EdgeInsetsDirectional.only(
                                      top: 10, bottom: 10, start: 20, end: 20,),
                                  height: 40,
                                  alignment: FractionalOffset.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(5.0),),
                                  ),
                                  child: Text(getTranslated(context, 'CANCEL')!,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall!
                                          .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor,
                                            fontWeight: FontWeight.bold,
                                          ),),),),
                          CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: countDownComplete
                                  ? () {
                                      print(
                                          "login type***${context.read<UserProvider>().loginType}",);
                                      if (context
                                              .read<UserProvider>()
                                              .loginType ==
                                          PHONE_TYPE) {
                                        setStater(() {
                                          from = 1;
                                        });
                                      } else {
                                        final User? currentUser =
                                            FirebaseAuth.instance.currentUser;
                                        print("currentUser is:$currentUser");
                                        if (currentUser != null) {
                                          currentUser
                                              .delete()
                                              .then((value) async {
                                            Navigator.of(context,
                                                    rootNavigator: true,)
                                                .pop(true);
                                            setDeleteSocialAcc();
                                          });
                                        } else {
                                          Navigator.of(context,
                                                  rootNavigator: true,)
                                              .pop(true);
                                          setSnackbar(
                                              getTranslated(
                                                  context, 'RELOGIN_REQ',)!,
                                              context,);
                                        }
                                      }
                                    }
                                  : null,
                              child: Container(
                                  padding: const EdgeInsetsDirectional.only(
                                      top: 10, bottom: 10, start: 20, end: 20,),
                                  height: 40,
                                  alignment: FractionalOffset.center,
                                  decoration: BoxDecoration(
                                    color: countDownComplete
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primarytheme
                                        : Theme.of(context)
                                            .colorScheme
                                            .lightWhite,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(5.0),),
                                  ),
                                  child: Text(
                                      getTranslated(context, 'CONFIRM')!,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall!
                                          .copyWith(
                                            color: countDownComplete
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .white
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .lightBlack,
                                            fontWeight: FontWeight.bold,
                                          ),),),),
                        ],
                      )
                    : InkWell(
                        onTap: () {
                          final form = _formkey1.currentState!;
                          form.save();
                          if (form.validate()) {
                            setState(() {
                              isLoading = true;
                            });
                            Navigator.of(context, rootNavigator: true)
                                .pop(true);
                            setDeleteAcc();
                          }
                        },
                        child: Container(
                            margin: EdgeInsetsDirectional.only(
                                top: 10,
                                bottom: 10,
                                start: deviceWidth! / 5.3,
                                end: deviceWidth! / 5.3,),
                            height: 40,
                            alignment: FractionalOffset.center,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primarytheme,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(5.0)),
                            ),
                            child: Text(getTranslated(context, 'DEL_ACC_LBL')!,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall!
                                    .copyWith(
                                      color:
                                          Theme.of(context).colorScheme.white,
                                      fontWeight: FontWeight.bold,
                                    ),),),),
              ),
            ],
          ),
        );
      },),
    );
  }

  Future<void> setDeleteSocialAcc() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        apiBaseHelper.postAPICall(deleteSocialAccApi, {}).then((getdata) {
          final bool error = getdata["error"];
          final String? msg = getdata["message"];
          if (!error) {
            setSnackbar(msg!, context);
            final SettingProvider settingProvider =
                Provider.of<SettingProvider>(context, listen: false);
            context.read<FavoriteProvider>().setFavlist([]);
            context.read<CartProvider>().setCartlist([]);
            settingProvider.clearUserSession(context);
            Future.delayed(Duration.zero, () {
              Navigator.pushNamedAndRemoveUntil(
                  context,
                  Routers.loginScreen,
                  arguments: {"isPop": false},
                  (route) => false,);
            });
            setState(() {
              isLoading = false;
            });
          } else {
            setState(() {
              isLoading = false;
            });
            setSnackbar(msg!, context);
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        },);
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else if (mounted) {
      setState(() {
        _isNetworkAvail = false;
      });
    }
  }

  Future<void> setDeleteAcc() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        final parameter = {
          USER_ID: context.read<UserProvider>().userId,
          PASSWORD: passController.text.trim(),
          MOBILE: mob,
        };
        apiBaseHelper.postAPICall(setDeleteAccApi, parameter).then((getdata) {
          final bool error = getdata["error"];
          final String? msg = getdata["message"];
          if (!error) {
            setSnackbar(msg!, context);
            passController.clear();
            final SettingProvider settingProvider =
                Provider.of<SettingProvider>(context, listen: false);
            context.read<FavoriteProvider>().setFavlist([]);
            context.read<CartProvider>().setCartlist([]);
            settingProvider.clearUserSession(context);
            Future.delayed(Duration.zero, () {
              Navigator.pushNamedAndRemoveUntil(
                  context,
                  Routers.loginScreen,
                  arguments: {"isPop": false},
                  (route) => false,);
            });
            setState(() {
              isLoading = false;
            });
          } else {
            setState(() {
              isLoading = false;
            });
            setSnackbar(msg!, context);
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        },);
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else if (mounted) {
      setState(() {
        _isNetworkAvail = false;
      });
    }
  }

  List<Widget> themeListView(BuildContext ctx) {
    return themeList
        .asMap()
        .map(
          (index, element) => MapEntry(
              index,
              InkWell(
                onTap: () {
                  _updateState(index, ctx);
                  Navigator.pop(ctx);
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 25.0,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: curTheme == index
                                    ? Theme.of(ctx).colorScheme.primarytheme
                                    : Theme.of(ctx).colorScheme.white,
                                border: Border.all(
                                    color: Theme.of(ctx)
                                        .colorScheme
                                        .primarytheme,),),
                            child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: curTheme == index
                                    ? Icon(
                                        Icons.check,
                                        size: 17.0,
                                        color: Theme.of(ctx).colorScheme.white,
                                      )
                                    : Icon(
                                        Icons.check_box_outline_blank,
                                        size: 17.0,
                                        color: Theme.of(ctx).colorScheme.white,
                                      ),),
                          ),
                          Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 15.0,
                              ),
                              child: Text(
                                themeList[index]!,
                                style: Theme.of(ctx)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                        color: Theme.of(ctx)
                                            .colorScheme
                                            .lightBlack,),
                              ),),
                        ],
                      ),
                    ],
                  ),
                ),
              ),),
        )
        .values
        .toList();
  }

  _updateState(int position, BuildContext ctx) {
    curTheme = position;
    onThemeChanged(themeList[position]!, ctx);
  }

  Future<void> onThemeChanged(
    String value,
    BuildContext ctx,
  ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (value == getTranslated(ctx, 'SYSTEM_DEFAULT')) {
      themeNotifier.setThemeMode(ThemeMode.system);
      prefs.setString(APP_THEME, DEFAULT_SYSTEM);
      final brightness =
          SchedulerBinding.instance.platformDispatcher.platformBrightness;
      if (mounted) {
        isDark = brightness == Brightness.dark;
        if (isDark) {
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
        } else {
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
        }
      }
    } else if (value == getTranslated(ctx, 'LIGHT_THEME')) {
      themeNotifier.setThemeMode(ThemeMode.light);
      prefs.setString(APP_THEME, LIGHT);
      if (mounted) {
        isDark = false;
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
      }
    } else if (value == getTranslated(ctx, 'DARK_THEME')) {
      themeNotifier.setThemeMode(ThemeMode.dark);
      prefs.setString(APP_THEME, DARK);
      if (mounted) {
        isDark = true;
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
      }
    }
    ISDARK = isDark.toString();
  }

  Future<void> _openStoreListing() => _inAppReview.openStoreListing(
        appStoreId: appStoreId,
        microsoftStoreId: 'microsoftStoreId',
      );
  logOutDailog(BuildContext context) async {
    await dialogAnimate(
        context,
        AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(5.0)),),
          content: Text(
            getTranslated(this.context, 'LOGOUTTXT')!,
            style: Theme.of(this.context)
                .textTheme
                .titleMedium!
                .copyWith(color: Theme.of(this.context).colorScheme.fontColor),
          ),
          actions: <Widget>[
            TextButton(
                child: Text(
                  getTranslated(this.context, 'NO')!,
                  style: Theme.of(this.context).textTheme.titleSmall!.copyWith(
                      color: Theme.of(this.context).colorScheme.lightBlack,
                      fontWeight: FontWeight.bold,),
                ),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },),
            TextButton(
                child: Text(
                  getTranslated(this.context, 'YES')!,
                  style: Theme.of(this.context).textTheme.titleSmall!.copyWith(
                      color: Theme.of(this.context).colorScheme.fontColor,
                      fontWeight: FontWeight.bold,),
                ),
                onPressed: () async {
                  final SettingProvider settingProvider =
                      Provider.of<SettingProvider>(context, listen: false);
                  context.read<FavoriteProvider>().setFavlist([]);
                  context.read<CartProvider>().setCartlist([]);
                  HiveUtils.clearUserBox();
                  Navigator.of(context, rootNavigator: true).pop(true);
                  if (context.read<UserProvider>().loginType != PHONE_TYPE) {
                    signOut(context.read<UserProvider>().loginType);
                  }
                  settingProvider.clearUserSession(context);
                },),
          ],
        ),);
  }

  Future<void> signOut(String type) async {
    _firebaseAuth.signOut();
    if (type == GOOGLE_TYPE) {
      _googleSignIn.signOut();
    } else {
      _firebaseAuth.signOut();
    }
  }

  @override
  void dispose() {
    passController.dispose();
    buttonController!.dispose();
    buttonController1!.dispose();
    _scrollBottomBarController.removeListener(() {});
    _scrollBottomBarController.dispose();
    confirmpassController.dispose();
    emailController.dispose();
    mobileController.dispose();
    nameController.dispose();
    newpassController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    hideAppbarAndBottomBarOnScroll(_scrollBottomBarController, context);
    themeList = [
      getTranslated(context, 'SYSTEM_DEFAULT'),
      getTranslated(context, 'LIGHT_THEME'),
      getTranslated(context, 'DARK_THEME'),
    ];
    themeNotifier = Provider.of<ThemeNotifier>(context);
    return Scaffold(
        body: SafeArea(
        child: Consumer<UserProvider>(builder: (context, data, child) {
      return _isNetworkAvail
          ? Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),),
                  controller: _scrollBottomBarController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _getHeader(),
                      _getDrawer(),
                    ],
                  ),
                ),
                showCircularProgress(context, isLoading,
                    Theme.of(context).colorScheme.primarytheme,),
              ],
            )
          : noInternet(context);
    },),),);
  }

  Future<void> _playAnimation(AnimationController ctrl) async {
    try {
      await ctrl.forward();
    } on TickerCanceled {
      return;

    }
  }

  Widget noInternet(BuildContext context) {
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
            _playAnimation(buttonController!);
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

  Widget getUserImage(String profileImage, VoidCallback? onBtnSelected) {
    return InkWell(
        child: Stack(
          children: <Widget>[
            Container(
              margin: const EdgeInsetsDirectional.only(end: 20),
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Theme.of(context).colorScheme.white,),),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100.0),
                child:
                    Consumer<UserProvider>(builder: (context, userProvider, _) {
                  return userProvider.profilePic != ''
                      ? networkImageCommon(userProvider.profilePic, 64, false,
                          height: 64, width: 64,)
                      : imagePlaceHolder(62, context);
                },),
              ),
            ),
            if (context.read<UserProvider>().userId != "")
              Positioned.directional(
                  textDirection: Directionality.of(context),
                  end: 20,
                  bottom: 5,
                  child: Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primarytheme,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(20),
                        ),
                        border: Border.all(
                            color: Theme.of(context).colorScheme.primarytheme,),),
                    child: Icon(
                      Icons.edit,
                      color: Theme.of(context).colorScheme.white,
                      size: 10,
                    ),
                  ),),
          ],
        ),
        onTap: () {
          if (mounted) {
            if (context.read<UserProvider>().userId != "") onBtnSelected!();
          }
        },);
  }

  openChangeUserDetailsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(40.0), topRight: Radius.circular(40.0),),),
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return const EditProfileBottomSheet();
      },
    );
  }

  openEditBottomSheet(BuildContext context) {
    return openChangeUserDetailsBottomSheet(context);
  }


  Future<void> setProfilePic(File image) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        final request = http.MultipartRequest("POST", getUpdateUserApi);
        request.headers.addAll(headers);
        request.fields[USER_ID] = context.read<UserProvider>().userId;
        final mimeType = lookupMimeType(image.path);
        final extension = mimeType!.split("/");
        final pic = await http.MultipartFile.fromPath(
          IMAGE,
          image.path,
          contentType: MediaType('image', extension[1]),
        );
        request.files.add(pic);
        final response = await request.send();
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final getdata = json.decode(responseString);
        final bool error = getdata["error"];
        final String? msg = getdata['message'];
        if (!error) {
          final data = getdata["data"];
          var image;
          image = data[IMAGE];
          final settingProvider =
              Provider.of<SettingProvider>(context, listen: false);
          settingProvider.setPrefrence(IMAGE, image!);
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          userProvider.setProfilePic(image!);
          setSnackbar(getTranslated(context, 'PROFILE_UPDATE_MSG')!, context);
        } else {
          setSnackbar(msg!, context);
        }
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

  Widget setNameField() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.white,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            child: TextFormField(
              style: Theme.of(context)
                  .textTheme
                  .titleSmall!
                  .copyWith(color: Theme.of(context).colorScheme.fontColor),
              controller: nameController,
              decoration: InputDecoration(
                  label: Text(getTranslated(context, "NAME_LBL")!),
                  fillColor: Theme.of(context).colorScheme.white,
                  border: InputBorder.none,),
              validator: (val) => validateUserName(
                  val!,
                  getTranslated(context, 'USER_REQUIRED'),
                  getTranslated(context, 'USER_LENGTH'),),
            ),
          ),
        ),
      );
  Widget setEmailField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: TextFormField(
            style: Theme.of(context)
                .textTheme
                .titleSmall!
                .copyWith(color: Theme.of(context).colorScheme.fontColor),
            readOnly: (context.read<UserProvider>().loginType != GOOGLE_TYPE)
                ? false
                : true,
            controller: emailController,
            decoration: InputDecoration(
                label: Text(getTranslated(context, "EMAILHINT_LBL")!),
                fillColor: Theme.of(context).colorScheme.white,
                border: InputBorder.none,),
            validator: (val) => validateEmail(
                val!,
                getTranslated(context, 'EMAIL_REQUIRED'),
                getTranslated(context, 'VALID_EMAIL'),),
          ),
        ),
      ),
    );
  }

  Widget setMobileField() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.white,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            child: TextFormField(
              readOnly: context.read<UserProvider>().loginType != PHONE_TYPE
                  ? false
                  : true,
              controller: mobileController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: Theme.of(context)
                  .textTheme
                  .titleSmall!
                  .copyWith(color: Theme.of(context).colorScheme.fontColor),
              decoration: InputDecoration(
                labelText: getTranslated(context, "MOBILEHINT_LBL"),
                fillColor: Theme.of(context).colorScheme.white,
                border: InputBorder.none,
              ),
              validator: (val) => validateMob(
                val!,
                getTranslated(context, 'MOB_REQUIRED'),
                getTranslated(context, 'VALID_MOB'),
                check: false,
              ),
            ),
          ),
        ),
      );
  Widget saveButton(String title, VoidCallback? onBtnSelected) {
    return Padding(
        padding:
            const EdgeInsetsDirectional.only(start: 8.0, end: 8.0, top: 15.0),
        child: AppBtn(
            title: title,
            btnAnim: buttonSqueezeanimation1,
            btnCntrl: buttonController1,
            onBtnSelected: onBtnSelected,),);
  }

  Future<bool> validateAndSave(GlobalKey<FormState> key) async {
    final form = key.currentState!;
    form.save();
    if (form.validate()) {
      _playAnimation(buttonController1!);
      context.read<UserProvider>().setProgress(true);
      if (key == _changePwdKey) {
        await setUpdateUser(context.read<UserProvider>().userId,
            passwordController.text, newpassController.text, "", "", "",);
        passwordController.clear();
        newpassController.clear();
        passwordController.clear();
        confirmpassController.clear();
      } else if (key == _changeUserDetailsKey) {
        print("change details***${mobileController.text}");
        setUpdateUser(context.read<UserProvider>().userId, "", "",
            nameController.text, emailController.text, mobileController.text,);
      }
      return true;
    }
    return false;
  }

  void openChangePasswordBottomSheet() {
    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0),),),
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return Wrap(
            children: [
              Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,),
                  child:
                      Consumer<UserProvider>(builder: (context, provider, _) {
                    return Form(
                      key: _changePwdKey,
                      child: Column(
                        children: [
                          bottomSheetHandle(context),
                          bottomsheetLabel("CHANGE_PASS_LBL", context),
                          setCurrentPasswordField(),
                          setForgotPwdLable(),
                          newPwdField(),
                          confirmPwdField(),
                          saveButton(
                              getTranslated(context, "SAVE_LBL")!,
                              !provider.getProgress
                                  ? () {
                                      validateAndSave(_changePwdKey);
                                    }
                                  : () {},),
                        ],
                      ),
                    );
                  },),),
            ],
          );
        },);
  }

  void openChangeLanguageBottomSheet() {
    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0),),),
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return Wrap(
            children: [
              Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,),
                child: Column(
                  children: [
                    bottomSheetHandle(context),
                    bottomsheetLabel("CHOOSE_LANGUAGE_LBL", context),
                    SingleChildScrollView(
                      child: Column(
                          children: getLngList(context),),
                    ),
                  ],
                ),
              ),
            ],
          );
        },);
  }

  void openChangeThemeBottomSheet() {
    themeList = [
      getTranslated(context, 'SYSTEM_DEFAULT'),
      getTranslated(context, 'LIGHT_THEME'),
      getTranslated(context, 'DARK_THEME'),
    ];
    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0),),),
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return Wrap(
            children: [
              Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,),
                child: Form(
                  key: _changePwdKey,
                  child: Column(
                    children: [
                      bottomSheetHandle(context),
                      bottomsheetLabel("CHOOSE_THEME_LBL", context),
                      SingleChildScrollView(
                        child: Column(
                          children: themeListView(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },);
  }

  Widget setCurrentPasswordField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: TextFormField(
            style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
            controller: passwordController,
            obscureText: true,
            obscuringCharacter: "*",
            decoration: InputDecoration(
                errorMaxLines: 4,
                label: Text(getTranslated(context, "CUR_PASS_LBL")!),
                fillColor: Theme.of(context).colorScheme.white,
                border: InputBorder.none,),
            onSaved: (String? value) {
              currentPwd = value;
            },
            validator: (val) => validatePass(
                val!,
                getTranslated(context, 'PWD_REQUIRED'),
                getTranslated(context, 'PASSWORD_VALIDATION'),),
          ),
        ),
      ),
    );
  }

  Widget setForgotPwdLable() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: InkWell(
          child: Text(getTranslated(context, "FORGOT_PASSWORD_LBL")!),
          onTap: () {
            Navigator.pushNamed(context, Routers.sendOTPScreen, arguments: {
              "title": getTranslated(context, 'FORGOT_PASS_TITLE'),
            },);
          },
        ),
      ),
    );
  }

  Widget newPwdField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: TextFormField(
            style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
            controller: newpassController,
            obscureText: true,
            obscuringCharacter: "*",
            decoration: InputDecoration(
                errorMaxLines: 4,
                label: Text(getTranslated(context, "NEW_PASS_LBL")!),
                fillColor: Theme.of(context).colorScheme.white,
                border: InputBorder.none,),
            onSaved: (String? value) {
              newPwd = value;
            },
            validator: (val) => validatePass(
                val!,
                getTranslated(context, 'PWD_REQUIRED'),
                getTranslated(context, 'PASSWORD_VALIDATION'),),
          ),
        ),
      ),
    );
  }

  Widget confirmPwdField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: TextFormField(
            style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
            controller: confirmpassController,
            focusNode: confirmPwdFocus,
            obscureText: true,
            obscuringCharacter: "*",
            decoration: InputDecoration(
                label: Text(getTranslated(context, "CONFIRMPASSHINT_LBL")!),
                fillColor: Theme.of(context).colorScheme.white,
                border: InputBorder.none,),
            validator: (value) {
              if (value!.isEmpty) {
                return getTranslated(context, 'CON_PASS_REQUIRED_MSG');
              }
              if (value != newPwd) {
                confirmpassController.text = "";
                confirmPwdFocus.requestFocus();
                return getTranslated(context, 'CON_PASS_NOT_MATCH_MSG');
              } else {
                return null;
              }
            },
          ),
        ),
      ),
    );
  }
}
