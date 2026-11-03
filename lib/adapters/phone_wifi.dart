import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/check_items.dart';
import '../domain/home_wifi.dart';
import '../ports/ports.dart';

/// Android reports a lost connection straight away, even with the screen off,
/// and it needs no Wi-Fi scan. Reading the name needs the location permission.
class PhoneWifi implements WifiSource {
  /// Still on Wi-Fi with a name that can't be read sends nothing, so it can't
  /// look like leaving.
  @override
  Stream<String?> get changes =>
      Connectivity().onConnectivityChanged.asyncExpand((r) async* {
        if (!r.contains(ConnectivityResult.wifi)) {
          yield null;
          return;
        }
        final name = cleanNetworkName(await NetworkInfo().getWifiName());
        if (name != null) yield name;
      });

  @override
  Future<String?> current() async {
    final now = await Connectivity().checkConnectivity();
    if (!now.contains(ConnectivityResult.wifi)) return null;
    return cleanNetworkName(await NetworkInfo().getWifiName());
  }
}

/// Android puts quotes around the name, and gives a placeholder when it hides it.
String? cleanNetworkName(String? raw) {
  if (raw == null) return null;
  final name = raw.length >= 2 && raw.startsWith('"') && raw.endsWith('"')
      ? raw.substring(1, raw.length - 1)
      : raw;
  return name.isEmpty || name == '<unknown ssid>' ? null : name;
}

/// Uses the uncached API, because the service and screens run in separate
/// isolates.
class PrefsHomeWifi implements HomeWifiStore {
  static const _key = 'home_wifi';
  final _prefs = SharedPreferencesAsync();

  @override
  Future<HomeWifi?> read() async => parseHome(await _prefs.getString(_key));

  @override
  Future<void> write(HomeWifi? value) => value == null
      ? _prefs.remove(_key)
      : _prefs.setString(_key, encodeHome(value));
}

class PrefsHomeState implements StateStore {
  static const _key = 'home_state';
  final _prefs = SharedPreferencesAsync();

  @override
  Future<String?> read() => _prefs.getString(_key);

  @override
  Future<void> write(String value) => _prefs.setString(_key, value);
}

class PrefsCheckItems implements CheckItemStore {
  static const _key = 'check_items';
  final _prefs = SharedPreferencesAsync();

  @override
  Future<List<CheckItem>> read() async =>
      parseCheckItems(await _prefs.getString(_key));

  @override
  Future<void> write(List<CheckItem> items) =>
      _prefs.setString(_key, encodeCheckItems(items));
}
