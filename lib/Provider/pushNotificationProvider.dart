import 'package:customer/Helper/ApiBaseHelper.dart';
import 'package:customer/Provider/UserProvider.dart';
import 'package:customer/Screen/HomePage.dart';
import 'package:customer/main.dart';
import 'package:customer/ui/widgets/ApiException.dart';
import 'package:customer/utils/Hive/hive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../Helper/String.dart';
import '../Model/Section_Model.dart';
import '../app/routes.dart';
import '../ui/styles/DesignConfig.dart';
import 'SettingProvider.dart';

class PushNotificationProvider extends ChangeNotifier {
  Future<void> registerToken(String? token, BuildContext context) async {
    final SettingProvider settingsProvider =
        Provider.of<SettingProvider>(context, listen: false);
    if (settingsProvider.getPrefrence(FCMTOKEN).toString().trim() != token) {
      final parameter = {
        FCM_ID: token,
      };
      if (context.read<UserProvider>().userId != '') {
        parameter[USER_ID] = context.read<UserProvider>().userId;
      }
      if (HiveUtils.getJWT() != null) {
        await updateFcmID(parameter: parameter).then((value) {
          if (value['error'] == false) {
            settingsProvider.setPrefrence(FCMTOKEN, token!);
          }
        });
      }
    }
  }

  static Future<Map<String, dynamic>> updateFcmID({
    required var parameter,
  }) async {
    try {
      final responseData = await ApiBaseHelper().postAPICall(
        updateFcmApi,
        parameter,
      );
      return responseData ?? {};
    } on Exception catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> getProduct(String id, int index, int secPos, bool list) async {
    try {
      final parameter = {
        ID: id,
      };
      apiBaseHelper.postAPICall(getProductApi, parameter).then((getdata) {
        final bool error = getdata["error"];
        if (!error) {
          final data = getdata["data"];
          List<Product> items = [];
          items = (data as List).map((data) => Product.fromJson(data)).toList();
          currentHero = notifyHero;
          Navigator.pushNamed(
              navigatorKey.currentContext!, Routers.productDetails,
              arguments: {
                "index": int.parse(id),
                "id": items[0].id!,
                "secPos": secPos,
                "list": list,
              },);
        }
      }, onError: (error) {
        setSnackbar(error.toString(), navigatorKey.currentContext!);
      },);
    } on Exception {
      return;

    }
  }
}
