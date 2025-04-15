import 'dart:core';
import 'package:customer/Helper/ApiBaseHelper.dart';
import 'package:customer/ui/widgets/ApiException.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Helper/Constant.dart';
import '../Helper/String.dart';
import '../Model/Notification_Model.dart';

class NotificationRepository {
  static Future<Map<String, dynamic>> fetchNotification({
    required Map<String, dynamic> parameter,
  }) async {
    try {
      final notificationList =
          await ApiBaseHelper().postAPICall(getNotificationApi, parameter);
      return {
        'totalNoti': notificationList['total'].toString(),
        'notiList': (notificationList['data'] as List)
            .map((notidata) => NotificationModel.fromJson(notidata))
            .toList(),
      };
    } on Exception catch (e) {
      throw ApiException('$errorMesaage$e');
    }
  }

  static Future<void> addChatNotification({required String message}) async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    await sharedPreferences.reload();
    final List<String> notificationMessages = sharedPreferences
            .getStringList(queueNotificationOfChatMessagesSharedPrefKey) ??
        List.from([]);
    notificationMessages.add(message);
    await sharedPreferences.setStringList(
        queueNotificationOfChatMessagesSharedPrefKey, notificationMessages,);
  }

  static Future<void> clearChatNotifications() async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    await sharedPreferences.reload();
    sharedPreferences
        .setStringList(queueNotificationOfChatMessagesSharedPrefKey, []);
  }

  static Future<List<String>> getChatNotifications() async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    await sharedPreferences.reload();
    final List<String> notificationMessages = sharedPreferences
            .getStringList(queueNotificationOfChatMessagesSharedPrefKey) ??
        List.from([]);
    return notificationMessages;
  }
}
