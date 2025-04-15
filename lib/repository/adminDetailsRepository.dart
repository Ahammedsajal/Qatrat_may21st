import 'dart:core';
import 'package:customer/Helper/ApiBaseHelper.dart';
import 'package:customer/Helper/String.dart';
import 'package:customer/Model/searchAdmin.dart';
import 'package:customer/ui/widgets/ApiException.dart';

class AdminDetailRepository {
  Future<List<SearchedAdmin>> searchAdmin({
    required Map<String, dynamic> parameter,
  }) async {
    try {
      final result = await ApiBaseHelper().postAPICall(searchAdminApi, parameter);
      if (result['error']) {
        throw ApiException(result['message'] ?? 'Failed to get sellers');
      }
      return ((result['data'] ?? []) as List)
          .map((seller) => SearchedAdmin.fromJson(Map.from(seller ?? {})))
          .toList();
    } on Exception catch (e) {
      throw ApiException(e.toString());
    }
  }
}
