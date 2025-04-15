import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:customer/Provider/CartProvider.dart';
import 'package:customer/Provider/UserProvider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../Helper/Color.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../Helper/cart_var.dart';
import '../Model/Model.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/widgets/AppBtn.dart';
import '../ui/widgets/PaymentRadio.dart';
import '../ui/widgets/SimBtn.dart';
import '../ui/widgets/SimpleAppBar.dart';
import '../utils/blured_router.dart';
import 'HomePage.dart';

class Payment extends StatefulWidget {
  final Function update;
  final String? msg;

  static route(RouteSettings settings) {
    final Map? arguments = settings.arguments as Map?;
    return BlurredRouter(
      builder: (context) {
        return Payment(
          arguments?['update'],
          arguments?['msg'],
        );
      },
    );
  }

  const Payment(this.update, this.msg, {super.key});

  @override
  State<StatefulWidget> createState() {
    return StatePayment();
  }
}

List<Model> timeSlotList = [];
String? allowDay;
bool codAllowed = true;
String? bankName;
String? bankNo;
String? acName;
String? acNo;
String? exDetails;

class StatePayment extends State<Payment> with TickerProviderStateMixin {
  bool _isLoading = true; // Tracks loading state
  String? startingDate;   // Start date for time slots
  late bool cod;          // Cash on Delivery availability
  late bool skipcash;     // SkipCash availability

  List<RadioModel> timeModel = [];    // Time slot options
  List<RadioModel> payModel = [];     // Payment method options
  List<RadioModel> timeModelList = []; // Additional time slot list (unused here)
  List<String?> paymentMethodList = []; // List of payment method names
  List<String> paymentIconList = [
    'assets/images/cod_payment.svg',    // Icon for COD
    'assets/images/skipcash.svg',       // Icon for SkipCash (ensure asset exists)
  ];

  Animation? buttonSqueezeanimation;    // Animation for button press
  AnimationController? buttonController; // Controller for button animation
  bool _isNetworkAvail = true;          // Network availability flag

  @override
  void initState() {
    super.initState();
    _getdateTime(); // Fetch payment and time slot settings
    timeSlotList.length = 0; // Clear time slot list initially

    // Initialize payment methods after context is available
    Future.delayed(Duration.zero, () {
      paymentMethodList = [
        getTranslated(context, 'COD_LBL'),     // Cash on Delivery
        getTranslated(context, 'SKIPCASH_LBL'), // SkipCash
      ];
    });

    // Show message if provided
    if (widget.msg != null && widget.msg!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => setSnackbar(widget.msg!, context));
    }

    // Setup button animation
    buttonController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(CurvedAnimation(
      parent: buttonController!,
      curve: const Interval(0.0, 0.150),
    ));
  }

  @override
  void dispose() {
    buttonController!.dispose(); // Clean up animation controller
    super.dispose();
  }

  // Play button animation
  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {
      log('Animation canceled');
    }
  }

  // Widget to display when there's no internet
  Widget noInternet(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          noIntImage(), // Placeholder for no internet image
          noIntText(context), // Placeholder for no internet text
          noIntDec(context), // Placeholder for no internet description
          AppBtn(
            title: getTranslated(context, 'TRY_AGAIN_INT_LBL'),
            btnAnim: buttonSqueezeanimation,
            btnCntrl: buttonController,
            onBtnSelected: () async {
              _playAnimation();
              Future.delayed(const Duration(seconds: 2)).then((_) async {
                _isNetworkAvail = await isNetworkAvailable();
                if (_isNetworkAvail) {
                  _getdateTime(); // Retry fetching data
                } else {
                  await buttonController!.reverse();
                  if (mounted) setState(() {});
                }
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: Platform.isAndroid ? false : true,
      child: Scaffold(
        appBar: getSimpleAppBar(
          getTranslated(context, 'PAYMENT_METHOD_LBL')!,
          context,
        ),
        body: _isNetworkAvail
            ? _isLoading
                ? getProgress(context) // Show loading indicator
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 5,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Wallet balance section
                                Consumer<UserProvider>(
                                  builder: (context, userProvider, _) {
                                    return Card(
                                      elevation: 0,
                                      child: userProvider.curBalance != "0" &&
                                              userProvider.curBalance.isNotEmpty &&
                                              userProvider.curBalance != ""
                                          ? Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                              child: CheckboxListTile(
                                                dense: true,
                                                contentPadding: const EdgeInsets.all(0),
                                                value: isUseWallet,
                                                onChanged: (bool? value) {
                                                  if (mounted) {
                                                    setState(() {
                                                      isUseWallet = value;
                                                      if (value!) {
                                                        if ((isStorePickUp == "false"
                                                                ? (totalPrice + deliveryCharge)
                                                                : totalPrice) <=
                                                            double.parse(userProvider.curBalance)) {
                                                          remWalBal = double.parse(userProvider.curBalance) -
                                                              (isStorePickUp == "false"
                                                                  ? (totalPrice + deliveryCharge)
                                                                  : totalPrice);
                                                          usedBalance = (isStorePickUp == "false"
                                                              ? (totalPrice + deliveryCharge)
                                                              : totalPrice);
                                                          paymentMethod = "Wallet";
                                                          isPayLayShow = false;
                                                        } else {
                                                          remWalBal = 0;
                                                          usedBalance = double.parse(userProvider.curBalance);
                                                          isPayLayShow = true;
                                                        }
                                                        totalPrice = (isStorePickUp == "false"
                                                            ? ((totalPrice + deliveryCharge) - usedBalance)
                                                            : (totalPrice - usedBalance));
                                                      } else {
                                                        totalPrice = totalPrice +
                                                            (isStorePickUp == "false"
                                                                ? (usedBalance - deliveryCharge)
                                                                : usedBalance);
                                                        remWalBal = double.parse(userProvider.curBalance);
                                                        paymentMethod = null;
                                                        selectedMethod = null;
                                                        usedBalance = 0;
                                                        isPayLayShow = true;
                                                      }
                                                      widget.update();
                                                    });
                                                  }
                                                },
                                                title: Text(
                                                  getTranslated(context, 'USE_WALLET')!,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium!
                                                      .copyWith(
                                                        color: Theme.of(context).colorScheme.fontColor,
                                                      ),
                                                ),
                                                subtitle: Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                  child: Text(
                                                    isUseWallet!
                                                        ? "${getTranslated(context, 'REMAIN_BAL')!} : ${getPriceFormat(context, remWalBal)!}"
                                                        : "${getTranslated(context, 'TOTAL_BAL')!} : ${getPriceFormat(context, double.parse(userProvider.curBalance))!}",
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      color: Theme.of(context).colorScheme.black,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    );
                                  },
                                ),
                                // Time slot selection for non-digital products
                                if (context.read<CartProvider>().cartList[0].productList![0].productType != 'digital_product')
                                  isTimeSlot! &&
                                          (isLocalDelCharge == null || isLocalDelCharge!) &&
                                          IS_LOCAL_ON != '0'
                                      ? Card(
                                          elevation: 0,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Text(
                                                  getTranslated(context, 'PREFERED_TIME')!,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium!
                                                      .copyWith(
                                                        color: Theme.of(context).colorScheme.fontColor,
                                                      ),
                                                ),
                                              ),
                                              const Divider(),
                                              Container(
                                                height: 90,
                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                                child: ListView.builder(
                                                  shrinkWrap: true,
                                                  scrollDirection: Axis.horizontal,
                                                  itemCount: int.parse(allowDay!),
                                                  itemBuilder: (context, index) {
                                                    return dateCell(index);
                                                  },
                                                ),
                                              ),
                                              const Divider(),
                                              ListView.builder(
                                                shrinkWrap: true,
                                                physics: const NeverScrollableScrollPhysics(),
                                                itemCount: timeModel.length,
                                                itemBuilder: (context, index) {
                                                  return timeSlotItem(index);
                                                },
                                              ),
                                            ],
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                // Payment method selection (COD and SkipCash only)
                                if (isPayLayShow!)
                                  Card(
                                    elevation: 0,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            getTranslated(context, 'SELECT_PAYMENT')!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium!
                                                .copyWith(
                                                  color: Theme.of(context).colorScheme.fontColor,
                                                ),
                                          ),
                                        ),
                                        const Divider(),
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: paymentMethodList.length,
                                          itemBuilder: (context, index) {
                                            if (index == 0 &&
                                                cod &&
                                                context
                                                        .read<CartProvider>()
                                                        .cartList[0]
                                                        .productList![0]
                                                        .productType !=
                                                    'digital_product') {
                                              return paymentItem(index); // COD
                                            } else if (index == 1 && skipcash) {
                                              return paymentItem(index); // SkipCash
                                            } else {
                                              return const SizedBox.shrink();
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  const SizedBox.shrink(),
                              ],
                            ),
                          ),
                        ),
                        // Done button
                        SimBtn(
                          width: 0.8,
                          height: 35,
                          title: getTranslated(context, 'DONE'),
                          onBtnSelected: () {
                            if (paymentMethod == null || paymentMethod!.isEmpty) {
                              setSnackbar(getTranslated(context, 'payWarning')!, context);
                            } else if (context.read<CartProvider>().cartList[0].productList![0].productType != 'digital_product' &&
                                isTimeSlot! &&
                                (isLocalDelCharge == null || isLocalDelCharge!) &&
                                int.parse(allowDay!) > 0 &&
                                (selDate == null || selDate!.isEmpty) &&
                                IS_LOCAL_ON != '0') {
                              setSnackbar(getTranslated(context, 'dateWarning')!, context);
                            } else if (context.read<CartProvider>().cartList[0].productList![0].productType != 'digital_product' &&
                                isTimeSlot! &&
                                (isLocalDelCharge == null || isLocalDelCharge!) &&
                                timeSlotList.isNotEmpty &&
                                (selTime == null || selTime!.isEmpty) &&
                                IS_LOCAL_ON != '0') {
                              setSnackbar(getTranslated(context, 'timeWarning')!, context);
                            } else {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ],
                    ),
                  )
            : noInternet(context),
      ),
    );
  }

  // Date selection widget
  Widget dateCell(int index) {
    final DateTime today = DateTime.parse(startingDate!);
    return InkWell(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: selectedDate == index ? Theme.of(context).colorScheme.primarytheme : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('EEE').format(today.add(Duration(days: index))),
              style: TextStyle(
                color: selectedDate == index
                    ? Theme.of(context).colorScheme.white
                    : Theme.of(context).colorScheme.lightBlack2,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Text(
                DateFormat('dd').format(today.add(Duration(days: index))),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selectedDate == index
                      ? Theme.of(context).colorScheme.white
                      : Theme.of(context).colorScheme.lightBlack2,
                ),
              ),
            ),
            Text(
              DateFormat('MMM').format(today.add(Duration(days: index))),
              style: TextStyle(
                color: selectedDate == index
                    ? Theme.of(context).colorScheme.white
                    : Theme.of(context).colorScheme.lightBlack2,
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        final DateTime date = today.add(Duration(days: index));
        if (mounted) selectedDate = index;
        selectedTime = null;
        selTime = null;
        selDate = DateFormat('yyyy-MM-dd').format(date);
        timeModel.clear();
        final DateTime cur = DateTime.now();
        final DateTime tdDate = DateTime(cur.year, cur.month, cur.day);
        if (date == tdDate) {
          if (timeSlotList.isNotEmpty) {
            for (int i = 0; i < timeSlotList.length; i++) {
              final DateTime cur = DateTime.now();
              final String time = timeSlotList[i].lastTime!;
              final DateTime last = DateTime(
                cur.year,
                cur.month,
                cur.day,
                int.parse(time.split(':')[0]),
                int.parse(time.split(':')[1]),
                int.parse(time.split(':')[2]),
              );
              if (cur.isBefore(last)) {
                timeModel.add(RadioModel(
                  isSelected: i == selectedTime ? true : false,
                  name: timeSlotList[i].name,
                  img: '',
                ));
              }
            }
          }
        } else {
          if (timeSlotList.isNotEmpty) {
            for (int i = 0; i < timeSlotList.length; i++) {
              timeModel.add(RadioModel(
                isSelected: i == selectedTime ? true : false,
                name: timeSlotList[i].name,
                img: '',
              ));
            }
          }
        }
        setState(() {});
      },
    );
  }

  // Fetch payment and time slot settings from API
  Future<void> _getdateTime() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      timeSlotList.clear();
      try {
        final parameter = {
          TYPE: PAYMENT_METHOD,
          USER_ID: context.read<UserProvider>().userId,
        };
        apiBaseHelper.postAPICall(getSettingApi, parameter).then(
          (getdata) async {
            final bool error = getdata["error"];
            if (!error) {
              final data = getdata["data"];
              final timeSlot = data["time_slot_config"];
              allowDay = timeSlot["allowed_days"];
              isTimeSlot = timeSlot["is_time_slots_enabled"] == "1" ? true : false;
              startingDate = timeSlot["starting_date"];
              codAllowed = data["is_cod_allowed"] == 1 ? true : false;
              final timeSlots = data["time_slots"];
              timeSlotList = (timeSlots as List).map((timeSlots) => Model.fromTimeSlot(timeSlots)).toList();

              if (timeSlotList.isNotEmpty) {
                for (int i = 0; i < timeSlotList.length; i++) {
                  if (selectedDate != null) {
                    final DateTime today = DateTime.parse(startingDate!);
                    final DateTime date = today.add(Duration(days: selectedDate!));
                    final DateTime cur = DateTime.now();
                    final DateTime tdDate = DateTime(cur.year, cur.month, cur.day);
                    if (date == tdDate) {
                      final DateTime cur = DateTime.now();
                      final String time = timeSlotList[i].lastTime!;
                      final DateTime last = DateTime(
                        cur.year,
                        cur.month,
                        cur.day,
                        int.parse(time.split(':')[0]),
                        int.parse(time.split(':')[1]),
                        int.parse(time.split(':')[2]),
                      );
                      if (cur.isBefore(last)) {
                        timeModel.add(RadioModel(
                          isSelected: i == selectedTime ? true : false,
                          name: timeSlotList[i].name,
                          img: '',
                        ));
                      }
                    } else {
                      timeModel.add(RadioModel(
                        isSelected: i == selectedTime ? true : false,
                        name: timeSlotList[i].name,
                        img: '',
                      ));
                    }
                  } else {
                    timeModel.add(RadioModel(
                      isSelected: i == selectedTime ? true : false,
                      name: timeSlotList[i].name,
                      img: '',
                    ));
                  }
                }
              }

              final payment = data["payment_method"];
              log("payments $payment");
              cod = codAllowed ? payment["cod_method"] == "1" ? true : false : false;
              skipcash = payment["skipcash_payment_method"] == "1" ? true : false; // Check SkipCash availability

              // Populate payment model with COD and SkipCash
              for (int i = 0; i < paymentMethodList.length; i++) {
                payModel.add(RadioModel(
                  isSelected: i == selectedMethod ? true : false,
                  name: paymentMethodList[i],
                  img: paymentIconList[i],
                ));
              }
            } else {
              log("Error fetching payment settings");
            }
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onError: (error) {
            setSnackbar(error.toString(), context);
          },
        );
      } on TimeoutException catch (_) {
        log("Timeout while fetching payment settings");
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  // Time slot selection widget
  Widget timeSlotItem(int index) {
    return InkWell(
      onTap: () {
        if (mounted) {
          setState(() {
            selectedTime = index;
            selTime = timeModel[selectedTime!].name;
            for (final element in timeModel) {
              element.isSelected = false;
            }
            timeModel[index].isSelected = true;
            widget.update();
          });
        }
      },
      child: RadioItem(timeModel[index]),
    );
  }

  // Payment method selection widget (COD and SkipCash only)
 

  Widget paymentItem(int index) {
    return InkWell(
      onTap: () {
        if (mounted) {
          setState(() {
            if (IS_SHIPROCKET_ON == "1") {
              if (isUseWallet == true) {
                totalPrice = totalPrice + (usedBalance - deliveryCharge);
                isUseWallet = false;
                usedBalance = 0;
              }
              if (index == 1 && cod) {
                deliveryCharge = codDeliverChargesOfShipRocket;
              } else {
                deliveryCharge = prePaidDeliverChargesOfShipRocket;
              }
            }
            selectedMethod = index;
            paymentMethod = paymentMethodList[selectedMethod!];
            for (final element in payModel) {
              element.isSelected = false;
            }
            payModel[index].isSelected = true;
            widget.update();
          });
        }
      },
      child: RadioItem(payModel[index]),
    );
  }
}
