import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _phoneNumberKey = 'phone_number';
  static const _subscriptionIdKey = 'subscription_id';
  static const _restartTextKey = 'restart_text';
  static const _stopTextKey = 'stop_text';
  static const _startTextKey = 'start_text';
  static const _restartText2Key = 'restart_text_2';
  static const _stopText2Key = 'stop_text_2';
  static const _startText2Key = 'start_text_2';
  static const _swapCommands1Key = 'swap_commands_1';
  static const _swapCommands2Key = 'swap_commands_2';
  static const _adminPasswordKey = 'admin_password';
  static const _user1PhoneKey = 'user1_phone';
  static const _user2PhoneKey = 'user2_phone';
  static const _user3PhoneKey = 'user3_phone';

  static const defaultAdminPassword = '123456';

  static const defaultRestartText = 'ON1SEC20';
  static const defaultStopText = 'OFF1';
  static const defaultStartText = 'ON1';
  static const defaultRestartText2 = 'ON2SEC20';
  static const defaultStopText2 = 'OFF2';
  static const defaultStartText2 = 'ON2';

  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String get phoneNumber => _prefs.getString(_phoneNumberKey) ?? '';
  Future<void> setPhoneNumber(String value) =>
      _prefs.setString(_phoneNumberKey, value);

  int get subscriptionId => _prefs.getInt(_subscriptionIdKey) ?? -1;
  Future<void> setSubscriptionId(int value) =>
      _prefs.setInt(_subscriptionIdKey, value);

  String get restartText =>
      _prefs.getString(_restartTextKey) ?? defaultRestartText;
  Future<void> setRestartText(String value) =>
      _prefs.setString(_restartTextKey, value);

  String get stopText => _prefs.getString(_stopTextKey) ?? defaultStopText;
  Future<void> setStopText(String value) =>
      _prefs.setString(_stopTextKey, value);

  String get startText => _prefs.getString(_startTextKey) ?? defaultStartText;
  Future<void> setStartText(String value) =>
      _prefs.setString(_startTextKey, value);

  String get restartText2 =>
      _prefs.getString(_restartText2Key) ?? defaultRestartText2;
  Future<void> setRestartText2(String value) =>
      _prefs.setString(_restartText2Key, value);

  String get stopText2 =>
      _prefs.getString(_stopText2Key) ?? defaultStopText2;
  Future<void> setStopText2(String value) =>
      _prefs.setString(_stopText2Key, value);

  String get startText2 =>
      _prefs.getString(_startText2Key) ?? defaultStartText2;
  Future<void> setStartText2(String value) =>
      _prefs.setString(_startText2Key, value);

  bool get swapCommands1 => _prefs.getBool(_swapCommands1Key) ?? false;
  Future<void> setSwapCommands1(bool value) =>
      _prefs.setBool(_swapCommands1Key, value);

  bool get swapCommands2 => _prefs.getBool(_swapCommands2Key) ?? false;
  Future<void> setSwapCommands2(bool value) =>
      _prefs.setBool(_swapCommands2Key, value);

  String get adminPassword =>
      _prefs.getString(_adminPasswordKey) ?? defaultAdminPassword;
  Future<void> setAdminPassword(String value) =>
      _prefs.setString(_adminPasswordKey, value);

  String get user1Phone => _prefs.getString(_user1PhoneKey) ?? '';
  Future<void> setUser1Phone(String value) =>
      _prefs.setString(_user1PhoneKey, value);

  String get user2Phone => _prefs.getString(_user2PhoneKey) ?? '';
  Future<void> setUser2Phone(String value) =>
      _prefs.setString(_user2PhoneKey, value);

  String get user3Phone => _prefs.getString(_user3PhoneKey) ?? '';
  Future<void> setUser3Phone(String value) =>
      _prefs.setString(_user3PhoneKey, value);
}
