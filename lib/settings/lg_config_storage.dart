import 'package:shared_preferences/shared_preferences.dart';
import 'lg_connection_config.dart';

class LgConfigStorage {
  static const _hostKey = 'lg_host';
  static const _userKey = 'lg_user';
  static const _portKey = 'lg_port';
  static const _passwordKey = 'lg_password';

  static Future<void> save(LgConnectionConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hostKey, config.host);
    await prefs.setString(_userKey, config.username);
    await prefs.setInt(_portKey, config.port);
    await prefs.setString(_passwordKey, config.password);
  }

  static Future<LgConnectionConfig?> load() async {
    final prefs = await SharedPreferences.getInstance();

    final host = prefs.getString(_hostKey);
    final user = prefs.getString(_userKey);
    final port = prefs.getInt(_portKey);
    final password = prefs.getString(_passwordKey);

    if (host == null || user == null || port == null || password == null) {
      return null;
    }

    return LgConnectionConfig(
      host: host,
      username: user,
      port: port,
      password: password,
    );
  }
}
