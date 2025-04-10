import 'package:flutter/material.dart';

class CountryCodeProvider extends ChangeNotifier {
  String accountPageCountryCode = '';
  String contactPageCountryCode = '';
  String loginPageCountryCode = '';
  String registerPageCountryCode = '';
  String addEmployeePageCountryCode = '';
  String editEmployeePageCountryCode = '';
  String forgotPasswordPageCountryCode = '';

  void setAllCountryCodes(String code) {
    accountPageCountryCode = code;
    contactPageCountryCode = code;
    loginPageCountryCode = code;
    registerPageCountryCode = code;
    addEmployeePageCountryCode = code;
    editEmployeePageCountryCode = code;
    forgotPasswordPageCountryCode = code;
    notifyListeners();
  }

  void setAccountPageCountryCode(String code) {
    accountPageCountryCode = code;
    notifyListeners();
  }

  void setContactPageCountryCode(String code) {
    contactPageCountryCode = code;
    notifyListeners();
  }

  void setloginPageCountryCode(String code) {
    loginPageCountryCode = code;
    notifyListeners();
  }

  void setRegisterPageCountryCode(String code) {
    registerPageCountryCode = code;
    notifyListeners();
  }

  void setAddEmployeePageCountryCode(String code) {
    addEmployeePageCountryCode = code;
    notifyListeners();
  }

  void setEditEmployeePageCountryCode(String code) {
    editEmployeePageCountryCode = code;
    notifyListeners();
  }

  void setForgotPasswordPageCountryCode(String code) {
    forgotPasswordPageCountryCode = code;
    notifyListeners();
  }
}
