import 'package:app_user/app/backend/api/api.dart';
import 'package:app_user/app/helper/shared_pref.dart';
import 'package:app_user/app/util/constant.dart';

class CheckoutParser {
  final SharedPreferencesManager sharedPreferencesManager;
  final ApiService apiService;

  CheckoutParser(
      {required this.apiService, required this.sharedPreferencesManager});

  void saveToken(String token) {
    sharedPreferencesManager.putString('token', token);
  }

  void saveUID(String id) {
    sharedPreferencesManager.putString('uid', id);
  }

  bool isLogin() {
    return sharedPreferencesManager.getString('uid') != null &&
            sharedPreferencesManager.getString('uid') != ''
        ? true
        : false;
  }

  String getCurrencyCode() {
    return sharedPreferencesManager.getString('currencyCode') ??
        AppConstants.defaultCurrencyCode;
  }

  String getCurrencySide() {
    return sharedPreferencesManager.getString('currencySide') ??
        AppConstants.defaultCurrencySide;
  }

  String getCurrencySymbol() {
    return sharedPreferencesManager.getString('currencySymbol') ??
        AppConstants.defaultCurrencySymbol;
  }
}
