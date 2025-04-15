import 'dart:convert';
import 'dart:io';
import 'package:customer/Helper/routes.dart';
import 'package:customer/Model/message.dart' as msg;
import 'package:customer/Model/personalChatHistory.dart';
import 'package:customer/Provider/SettingProvider.dart';
import 'package:customer/Provider/pushNotificationProvider.dart';
import 'package:customer/Screen/Dashboard.dart';
import 'package:customer/Screen/cart/Cart.dart';
import 'package:customer/cubits/personalConverstationsCubit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Model/FlashSaleModel.dart';
import '../Provider/FlashSaleProvider.dart';
import '../Screen/All_Category.dart';
import '../Screen/Chat.dart';
import '../Screen/customer_Support.dart';
import '../Screen/FlashSaleProductList.dart';
import '../Screen/HomePage.dart';
import '../Screen/Splash.dart';
import '../app/routes.dart';
import '../main.dart';
import '../ui/styles/DesignConfig.dart';
import 'Constant.dart';
import 'Session.dart';
import 'String.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
FirebaseMessaging messaging = FirebaseMessaging.instance;
backgroundMessage(NotificationResponse notificationResponse) {
  print(
      'notification(${notificationResponse.id}) action tapped: ${notificationResponse.actionId} with payload: ${notificationResponse.payload}',);
  if (notificationResponse.input?.isNotEmpty ?? false) {
    print(
        'notification action tapped with input: ${notificationResponse.input}',);
  }
}

class PushNotificationService {
  late BuildContext context;
  PushNotificationService({required this.context});
  setDeviceToken(
      {bool clearSesssionToken = false, SettingProvider? settingProvider,}) {
    if (clearSesssionToken) {
      settingProvider ??= Provider.of<SettingProvider>(context, listen: false);
      settingProvider.setPrefrence(FCMTOKEN, '');
    }
    messaging.getToken().then(
      (token) async {
         print("FCM Token: $token");
        context.read<PushNotificationProvider>().registerToken(token, context);
      },
    );
  }

  Future initialise() async {
    permission();
    setDeviceToken();
    FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('mipmap/notification');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    final InitializationSettings initializationSettings =
        const InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        print("notification response ${notificationResponse.payload}");
        switch (notificationResponse.notificationResponseType) {
          case NotificationResponseType.selectedNotification:
            selectNotificationPayload(notificationResponse.payload);
            break;
          case NotificationResponseType.selectedNotificationAction:
            print(
                "notification-action-id--->${notificationResponse.actionId}==${notificationResponse.payload}",);
            break;
        }
      },
      onDidReceiveBackgroundNotificationResponse: backgroundMessage,
    );
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final SettingProvider settingsProvider =
          Provider.of<SettingProvider>(context, listen: false);
      if (message.notification != null) {
        final data = message.notification!;
        final title = data.title.toString();
        final body = data.body.toString();
        final image = message.data['image'] ?? '';
        final type = message.data['type'] ?? '';
        var id = '';
        id = message.data['type_id'] ?? '';
        final urlLink = message.data['link'] ?? '';
        if (type == 'chat') {
          final messages = jsonDecode(message.data['message']) as List;
          String payload = '';
          if (messages.isNotEmpty) {
            payload = jsonEncode(messages.first);
          }
          if (converstationScreenStateKey.currentState?.mounted ?? false) {
            final state = converstationScreenStateKey.currentState!;
            if (state.widget.isGroup) {
              if (messages.isNotEmpty) {
                if (state.widget.groupDetails?.groupId !=
                    messages.first['to_id']) {
                } else {
                  state.addMessage(
                      message: msg.Message.fromJson(messages.first),);
                }
              }
            } else {
              if (messages.isNotEmpty) {
                if (state.widget.personalChatHistory?.getOtherUserId() !=
                    messages.first['from_id']) {
                  generateChatLocalNotification(
                      title: title, body: body, payload: payload,);
                  context
                      .read<PersonalConverstationsCubit>()
                      .updateUnreadMessageCounter(
                        userId: messages.first['from_id'].toString(),
                      );
                } else {
                  state.addMessage(
                      message: msg.Message.fromJson(messages.first),);
                }
              }
            }
          } else {
            generateChatLocalNotification(
                title: title, body: body, payload: payload,);
            if (messages.isNotEmpty) {
              if (messages.first['type'] == 'person') {
                context
                    .read<PersonalConverstationsCubit>()
                    .updateUnreadMessageCounter(
                      userId: messages.first['from_id'].toString(),
                    );
              } else {}
            }
          }
        } else if (type == "ticket_status") {
          Navigator.push(
              context,
              CupertinoPageRoute(
                  builder: (context) => const customerSupport(),),);
        } else if (type == "ticket_message") {
          if (CUR_TICK_ID == id) {
            if (chatstreamdata != null) {
              var parsedJson = json.decode(message.data['chat']);
              parsedJson = parsedJson[0];
              final Map<String, dynamic> sendata = {
                "id": parsedJson[ID],
                "title": parsedJson[TITLE],
                "message": parsedJson[MESSAGE],
                "user_id": parsedJson[USER_ID],
                "name": parsedJson[NAME],
                "date_created": parsedJson[DATE_CREATED],
                "attachments": parsedJson["attachments"],
              };
              final chat = {};
              chat["data"] = sendata;
              if (parsedJson[USER_ID] != settingsProvider.userId) {
                chatstreamdata!.sink.add(jsonEncode(chat));
              }
            }
          } else {
            if (image != null && image != 'null' && image != '') {
              generateImageNotication(title, body, image, type, id, urlLink);
            } else {
              generateSimpleNotication(title, body, type, id, urlLink);
            }
          }
        } else if (image != null && image != 'null' && image != '') {
          generateImageNotication(title, body, image, type, id, urlLink);
        } else {
          generateSimpleNotication(title, body, type, id, urlLink);
        }
      }
    });
    messaging.getInitialMessage().then((RemoteMessage? message) async {
      if (message != null) {
        print("message******${message.data}");
        final bool back = await Provider.of<SettingProvider>(context, listen: false)
            .getPrefrenceBool(ISFROMBACK);
        if (back) {
          final type = message.data['type'] ?? '';
          var id = '';
          id = message.data['type_id'] ?? '';
          final String urlLink = message.data['link'] ?? "";
          print("URL is $urlLink and type is $type");
          if (type == "products") {
            context.read<PushNotificationProvider>().getProduct(id, 0, 0, true);
          } else if (type == 'chat') {
            _onTapChatNotification(message: message);
          } else if (type == "categories") {
            Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (context) => const AllCategory(),),);
          } else if (type == "wallet") {
            Navigator.pushNamed(context, Routers.myWalletScreen);
          } else if (type == 'order' || type == 'place_order') {
            Navigator.pushNamed(context, Routers.myOrderScreen);
          } else if (type == "ticket_message") {
            Navigator.push(
              context,
              CupertinoPageRoute(
                  builder: (context) => Chat(
                        id: id,
                        status: "",
                      ),),
            );
          } else if (type == "ticket_status") {
            Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (context) => const customerSupport(),),);
          } else if (type == "notification_url") {
            print("here we are");
            final String url = urlLink;
            try {
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url),
                    mode: LaunchMode.externalApplication,);
              } else {
                throw 'Could not launch $url';
              }
            } catch (e) {
              throw 'Something went wrong';
            }
          } else if (type == "flash_sale") {
            getFlashSale(id);
          } else {
            Navigator.push(context,
                CupertinoPageRoute(builder: (context) => const Splash()),);
          }
          Provider.of<SettingProvider>(context, listen: false)
              .setPrefrenceBool(ISFROMBACK, false);
        }
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      print("message on opened app listen******${message.data}");
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final type = message.data['type'] ?? '';
      var id = '';
      String urlLink = '';
      try {
        id = message.data['type_id'] ?? '';
        urlLink = message.data['link'];
      } catch (_) {}
      if (type == "products") {
        context.read<PushNotificationProvider>().getProduct(id, 0, 0, true);
      } else if (type == 'chat') {
        _onTapChatNotification(message: message);
      } else if (type == "categories") {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (context) => const AllCategory()),
        );
      } else if (type == "wallet") {
        Navigator.pushNamed(context, Routers.myWalletScreen);
      } else if (type == 'order' || type == 'place_order') {
        Navigator.pushNamed(context, Routers.myOrderScreen);
      } else if (type == "ticket_message") {
        Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) => Chat(
                    id: id,
                    status: "",
                  ),),
        );
      } else if (type == "ticket_status") {
        Navigator.push(context,
            CupertinoPageRoute(builder: (context) => const customerSupport()),);
      } else if (type == "notification_url") {
        final String url = urlLink;
        try {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url),
                mode: LaunchMode.externalApplication,);
          } else {
            throw 'Could not launch $url';
          }
        } catch (e) {
          throw 'Something went wrong';
        }
      } else if (type == "flash_sale") {
        getFlashSale(id);
      } else if (type == "cart") {
        Navigator.push(
            context,
            CupertinoPageRoute(
                builder: (context) => const Cart(fromBottom: false),),);
      } else {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => MyApp(sharedPreferences: prefs),
          ),
        );
      }
      Provider.of<SettingProvider>(context, listen: false)
          .setPrefrenceBool(ISFROMBACK, false);
    });
  }

  Future<void> generateChatLocalNotification(
      {required String title,
      required String body,
      required String payload,}) async {
    if (Platform.isAndroid) {
      const androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id',
        'your channel name',
        channelDescription: 'your channel description',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );
      const iosDetail = DarwinNotificationDetails();
      const platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosDetail,
      );
      await flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        platformChannelSpecifics,
        payload: 'chat,$payload',
      );
    }
  }

  Future<void> permission() async {
    await messaging.requestPermission(
      
    );
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> myBackgroundMessageHandler(RemoteMessage message) async {
    print("openNotification:background>${message.data}");
    setPrefrenceBool(ISFROMBACK, true);
    await Firebase.initializeApp();
  }

  Future<String> _downloadAndSaveImage(String url, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final response = await http.get(Uri.parse(url));
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  Future<void> generateImageNotication(String title, String msg, String image,
      String type, String id, String url,) async {
    if (Platform.isAndroid) {
      final largeIconPath = await _downloadAndSaveImage(image, 'largeIcon');
      final bigPicturePath = await _downloadAndSaveImage(image, 'bigPicture');
      final bigPictureStyleInformation = BigPictureStyleInformation(
          FilePathAndroidBitmap(bigPicturePath),
          hideExpandedLargeIcon: true,
          contentTitle: title,
          htmlFormatContentTitle: true,
          summaryText: msg,
          htmlFormatSummaryText: true,);
      final androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'big text channel id', 'big text channel name',
          channelDescription: 'big text channel description',
          largeIcon: FilePathAndroidBitmap(largeIconPath),
          styleInformation: bigPictureStyleInformation,);
      final platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
          0, title, msg, platformChannelSpecifics,
          payload: "$type,$id,$url",);
    }
  }

  DarwinNotificationDetails darwinNotificationDetails =
      const DarwinNotificationDetails(
    categoryIdentifier: "",
  );
  Future<void> generateSimpleNotication(
      String title, String msg, String type, String id, String url,) async {
    if (Platform.isAndroid) {
      const androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'your channel id', 'your channel name',
          channelDescription: 'your channel description',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',);
      final platformChannelSpecifics = NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: darwinNotificationDetails,);
      await flutterLocalNotificationsPlugin.show(
          0, title, msg, platformChannelSpecifics,
          payload: "$type,$id,$url",);
    }
  }

  selectNotificationPayload(String? payload) async {
    if (payload != null) {
      print("all details $payload");
      final List<String> pay = payload.split(",");
      print("pay is $pay");
      print("payload ${pay[0]}");
      if (pay[0] == "products") {
        context.read<PushNotificationProvider>().getProduct(pay[1], 0, 0, true);
      } else if (pay[0] == 'chat') {
        final whatWeNeed = payload.replaceFirst('${pay[0]},', '');
        if (converstationScreenStateKey.currentState?.mounted ?? false) {
          Navigator.of(context).pop();
        }
        final message = msg.Message.fromJson(jsonDecode(whatWeNeed));
        Routes.navigateToConverstationScreen(
            context: context,
            isGroup: false,
            personalChatHistory: PersonalChatHistory(
                unreadMsg: '1',
                opponentUserId: message.fromId,
                opponentUsername: message.sendersName,
                image: message.picture,),);
      } else if (pay[0] == "categories") {
        Future.delayed(Duration.zero, () {
          if (Dashboard.dashboardScreenKey.currentState != null) {
            Dashboard.dashboardScreenKey.currentState!.changeTabPosition(1);
          }
        });
      } else if (pay[0] == "wallet") {
        Navigator.pushNamed(context, Routers.myWalletScreen);
      } else if (pay[0] == 'order' || pay[0] == 'place_order') {
        Navigator.pushNamed(context, Routers.myOrderScreen);
      } else if (pay[0] == "ticket_message") {
        Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) => Chat(
                    id: pay[1],
                    status: "",
                  ),),
        );
      } else if (pay[0] == "ticket_status") {
        Navigator.push(context,
            CupertinoPageRoute(builder: (context) => const customerSupport()),);
      } else if (pay[0] == "notification_url") {
        final String url = pay[2];
        try {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url),
                mode: LaunchMode.externalApplication,);
          } else {
            throw 'Could not launch $url';
          }
        } catch (e) {
          throw 'Something went wrong';
        }
      } else if (pay[0] == "flash_sale") {
        getFlashSale(pay[1]);
      } else if (pay[0] == "cart") {
        Navigator.push(
            context,
            CupertinoPageRoute(
                builder: (context) => const Cart(fromBottom: false),),);
      } else {
        Navigator.push(context,
            CupertinoPageRoute(builder: (context) => const Splash()),);
      }
    }
  }

  void _onTapChatNotification({required RemoteMessage message}) {
    if (converstationScreenStateKey.currentState?.mounted ?? false) {
      Navigator.of(context).pop();
    }
    final messages = jsonDecode(message.data['message']) as List;
    if (messages.isEmpty) {
      return;
    }
    final messageDetails =
        msg.Message.fromJson(jsonDecode(json.encode(messages.first)));
    Routes.navigateToConverstationScreen(
        context: context,
        isGroup: false,
        personalChatHistory: PersonalChatHistory(
            unreadMsg: '1',
            opponentUserId: messageDetails.fromId,
            opponentUsername: messageDetails.sendersName,
            image: messageDetails.picture,),);
  }

  void getFlashSale(String id) {
    try {
      apiBaseHelper.postAPICall(getFlashSaleApi, {}).then((getdata) {
        final bool error = getdata["error"];
        context.read<FlashSaleProvider>().removeSaleList();
        if (!error) {
          final data = getdata["data"];
          final List<FlashSaleModel> saleList = (data as List)
              .map((data) => FlashSaleModel.fromJson(data))
              .toList();
          context.read<FlashSaleProvider>().setSaleList(saleList);
          final int index = saleList.indexWhere((element) => element.id == id);
          Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => FlashProductList(
                  index: index,
                ),
              ),);
        }
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      },);
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }
}
