import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart' as dio_;
import 'package:customer/ui/widgets/ApiException.dart';
import 'package:http/http.dart';
import 'Constant.dart';
import 'Session.dart';

class ApiBaseHelper {
  final dio_.Dio dio = dio_.Dio();
  Future<void> downloadFile(
      {required String url,
      required dio_.CancelToken cancelToken,
      required String savePath,
      required Function updateDownloadedPercentage,}) async {
    try {
      final dio_.Dio dio = dio_.Dio();
      await dio.download(url, savePath, cancelToken: cancelToken,
          onReceiveProgress: (count, total) {
        updateDownloadedPercentage((count / total) * 100);
      },);
    } on dio_.DioException catch (e) {
      if (e.type == dio_.DioExceptionType.connectionError) {
        throw ApiException('No Internet connection');
      }
      throw ApiException('Failed to download file');
    } catch (e) {
      throw Exception('Failed to download file');
    }
  }

  Future<dynamic> postAPICall(Uri url, Map param) async {
    var responseJson;
    try {
      final response = await post(url,
              body: param.isNotEmpty ? param : null, headers: headers,)
          .timeout(const Duration(seconds: timeOut));
      print("param****$param****$url");
      print("respon****${response.statusCode}");
      responseJson = _response(response);
      print("respon****$responseJson");
      log("responjson** $url $param ----**$responseJson");
    } on SocketException {
      throw FetchDataException('No Internet connection');
    } on TimeoutException {
      throw FetchDataException('Something went wrong, try again later');
    }
    return responseJson;
  }

  dynamic _response(Response response) {
    switch (response.statusCode) {
      case 200:
        print("Reponse is ${getToken()}");
        final responseJson = json.decode(response.body);
        return responseJson;
      case 400:
        throw BadRequestException(response.body);
      case 401:
      case 403:
        throw UnauthorisedException(response.body);
      case 500:
      default:
        throw FetchDataException(
            'Error occurred while Communication with Server with StatusCode: ${response.statusCode}',);
    }
  }
}

class CustomException implements Exception {
  final _message;
  final _prefix;
  CustomException([this._message, this._prefix]);
  @override
  String toString() {
    return "$_prefix$_message";
  }
}

class FetchDataException extends CustomException {
  FetchDataException([message])
      : super(message, "Error During Communication: ");
}

class BadRequestException extends CustomException {
  BadRequestException([message]) : super(message, "Invalid Request: ");
}

class UnauthorisedException extends CustomException {
  UnauthorisedException([message]) : super(message, "Unauthorised: ");
}

class InvalidInputException extends CustomException {
  InvalidInputException([message]) : super(message, "Invalid Input: ");
}
