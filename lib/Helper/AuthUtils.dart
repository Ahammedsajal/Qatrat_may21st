import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:customer/Provider/UserProvider.dart';
import 'package:customer/utils/Hive/hive_utils.dart'; // Adjust if path differs
import 'package:customer/utils/Hive/hive_keys.dart'; // Adjust if path differs

class AuthUtils {
  static final Logger _log = Logger('AuthUtils');

  static Future<String?> refreshJwtToken(BuildContext context) async {
    _log.info('Attempting to refresh JWT token');
    final userProvider = context.read<UserProvider>();
    final currentToken = HiveUtils.getJWT();
    if (currentToken == null) {
      _log.warning('No current JWT token found');
      return null;
    }
    try {
      final response = await http.post(
        Uri.parse('https://www.qatratkheir.com/auth/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $currentToken',
        },
        body: jsonEncode({
          'user_id': userProvider.userId,
        }),
      );
      final data = jsonDecode(response.body);
      _log.info('Refresh Token Response: $data');
      if (response.statusCode == 200 && data['error'] == false) {
        final newToken = data['token'];
        await HiveUtils.setJWT(newToken); // Note: Changed from saveJWT to setJWT
        _log.info('New JWT token saved');
        return newToken;
      } else {
        _log.warning('Token refresh failed: ${data['message']}');
        return null;
      }
    } catch (e) {
      _log.severe('Refresh Token Error: $e');
      return null;
    }
  }
}