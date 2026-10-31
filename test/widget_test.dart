import 'package:flutter_test/flutter_test.dart';
import 'package:geo_alert/main.dart';

void main() {
  testWidgets('app starts', (tester) async {
    await tester.pumpWidget(const GeoAlertApp());
    expect(find.text('Geo Alert'), findsOneWidget);
  });
}
