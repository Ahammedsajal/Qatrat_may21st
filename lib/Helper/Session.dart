import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:customer/Model/language_model.dart';
import 'package:customer/app/languages.dart';
import 'package:customer/utils/Hive/hive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/app_Localization.dart';
import 'String.dart';

setPrefrenceBool(String key, bool value) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool(key, value);
}

Future<bool> isNetworkAvailable() async {
  final connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult.contains(ConnectivityResult.mobile)) {
    return true;
  } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
    return true;
  }
  return false;
}

Future<Locale> setLocale(String languageCode) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(LAGUAGE_CODE, languageCode);
  return _locale(languageCode);
}

Future<Locale> getLocale() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String languageCode =
      prefs.getString(LAGUAGE_CODE) ?? Languages().defaultLanguageCode;
  return _locale(languageCode);
}

Locale _locale(String languageCode) {
  final List<Language> supportedLanguages = Languages().supported();
  final Language language = supportedLanguages.firstWhere(
    (element) => element.code == languageCode,
    orElse: () {
      return Languages().getDefaultLanguage();
    },
  );
  return Locale(language.code);
}

String? getTranslated(BuildContext context, String key) {
  return AppLocalization.of(context)!.translate(key) ?? key;
}

String getToken() {
  return HiveUtils.getJWT() ?? "";
}

Map<String, String> get headers => {
      "Authorization": 'Bearer ${getToken()}',
    };
