import 'package:flutter_test/flutter_test.dart';
import 'package:leavecheck/adapters/phone_wifi.dart';

void main() {
  test('network names lose quotes, and hidden names read as none', () {
    expect(cleanNetworkName('"Home"'), 'Home');
    expect(cleanNetworkName('Home'), 'Home');
    expect(cleanNetworkName('<unknown ssid>'), isNull);
    expect(cleanNetworkName('""'), isNull);
    expect(cleanNetworkName(null), isNull);
  });
}
