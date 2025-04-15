part of '../Cart.dart';

Widget noInternet(BuildContext context,
    {required Animation? buttonSqueezeanimation,
    required AnimationController? buttonController,
    required Widget onNetworkNavigationWidget,
    required Function(bool internetAvailable) onButtonClicked,}) {
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
          try {
            await buttonController?.forward();
          } on TickerCanceled {
      return;

          }
          Future.delayed(const Duration(seconds: 2)).then((_) async {
            final bool _isNetworkAvail = await isNetworkAvailable();
            if (_isNetworkAvail) {
            } else {
              await buttonController?.reverse();
            }
            onButtonClicked.call(_isNetworkAvail);
          });
        },
      ),
    ],),
  );
}

Future<void> _getAddress(BuildContext context,
    {required VoidCallback onComplete,
    required Function(bool hasInternet) onInternetState,}) async {
  final bool _isNetworkAvailable = await isNetworkAvailable();
  if (_isNetworkAvailable) {
    onInternetState.call(true);
    try {
      final parameter = {
        USER_ID: context.read<UserProvider>().userId,
      };
      apiBaseHelper.postAPICall(getAddressApi, parameter).then((getdata) {
        final bool error = getdata["error"];
        if (!error) {
          final data = getdata["data"];
          addressList =
              (data as List).map((data) => User.fromAddress(data)).toList();
          if (addressList.length == 1) {
            selectedAddress = 0;
            selAddress = addressList[0].id;
            if (!ISFLAT_DEL) {
              if (totalPrice < double.parse(addressList[0].freeAmt!)) {
                deliveryCharge = double.parse(addressList[0].deliveryCharge!);
              } else {
                deliveryCharge = 0;
              }
            }
          } else {
            for (int i = 0; i < addressList.length; i++) {
              if (addressList[i].isDefault == "1") {
                selectedAddress = i;
                selAddress = addressList[i].id;
                if (!ISFLAT_DEL) {
                  if (totalPrice < double.parse(addressList[i].freeAmt!)) {
                    deliveryCharge =
                        double.parse(addressList[i].deliveryCharge!);
                  } else {
                    deliveryCharge = 0;
                  }
                }
              }
            }
          }
          if (ISFLAT_DEL) {
            if (originalPrice < double.parse(MIN_AMT!)) {
              deliveryCharge = double.parse(CUR_DEL_CHR!);
            } else {
              deliveryCharge = 0;
            }
          }
        } else {
          if (ISFLAT_DEL) {
            if (originalPrice < double.parse(MIN_AMT!)) {
              deliveryCharge = double.parse(CUR_DEL_CHR!);
            } else {
              deliveryCharge = 0;
            }
          }
        }
        onComplete.call();
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      },);
    } on TimeoutException catch (_) {}
  } else {
    onInternetState.call(false);
  }
}

cartEmpty(BuildContext context) {
  return Center(
    child: SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SvgPicture.asset(
          'assets/images/empty_cart.svg',
          colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.primarytheme, BlendMode.srcIn,),
        ),
        Text(getTranslated(context, 'NO_CART')!,
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                color: Theme.of(context).colorScheme.primarytheme,
                fontWeight: FontWeight.normal,),),
        Container(
          padding: const EdgeInsetsDirectional.only(
              top: 30.0, start: 30.0, end: 30.0,),
          child: Text(getTranslated(context, 'CART_DESC')!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).colorScheme.lightBlack2,
                    fontWeight: FontWeight.normal,
                  ),),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 28.0),
          child: CupertinoButton(
            child: Container(
                width: deviceWidth! * 0.7,
                height: 45,
                alignment: FractionalOffset.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primarytheme,
                  borderRadius: const BorderRadius.all(Radius.circular(50.0)),
                ),
                child: Text(getTranslated(context, 'SHOP_NOW')!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: Theme.of(context).colorScheme.white,
                        fontWeight: FontWeight.normal,),),),
            onPressed: () {
  Navigator.pushNamedAndRemoveUntil(
    context,
    Routers.dashboardScreen,
    (Route<dynamic> route) => false,
  );
},


          ),
        ),
      ],),
    ),
  );
}

_imgFromGallery(BuildContext context,
    {required Function(List<File> pickedFiles) onFilePick,}) async {
  try {
    final result = await FilePicker.platform
        .pickFiles(allowMultiple: true, type: FileType.image);
    if (result != null) {
      onFilePick.call(result.paths.map((path) => File(path!)).toList());
    } else {}
  } catch (e) {
    setSnackbar(getTranslated(context, "PERMISSION_NOT_ALLOWED")!, context);
  }
}


