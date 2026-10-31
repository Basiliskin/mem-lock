import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_alert/l10n/strings.dart';
import 'package:geo_alert/ports/ports.dart';
import 'package:geo_alert/ui/main_screen.dart';

class FakeHost implements BackgroundHost {
  FakeHost({this.running = false, this.startWorks = true});
  bool running;
  bool startWorks;
  int starts = 0;
  @override
  Future<bool> isRunning() async => running;
  @override
  Future<bool> start() async {
    starts++;
    running = startWorks;
    return startWorks;
  }
}

Future<void> show(WidgetTester t, BackgroundHost host) async {
  await t.pumpWidget(MaterialApp(home: MainScreen(host: host)));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('AC-8.4: a running service shows protecting', (t) async {
    await show(t, FakeHost(running: true));
    expect(find.text(Strings.protecting), findsOneWidget);
    expect(find.text(Strings.nothingToDo), findsOneWidget);
    expect(find.text(Strings.enable), findsNothing);
  });

  testWidgets('a stopped service never claims protection', (t) async {
    await show(t, FakeHost());
    expect(find.text(Strings.notProtecting), findsOneWidget);
    expect(find.text(Strings.protecting), findsNothing);
    expect(find.text(Strings.enable), findsOneWidget);
  });

  testWidgets('enabling starts the service and updates status', (t) async {
    final host = FakeHost();
    await show(t, host);
    await t.tap(find.text(Strings.enable));
    await t.pumpAndSettle();
    expect(host.starts, 1);
    expect(find.text(Strings.protecting), findsOneWidget);
  });

  testWidgets('a failed start says so and still offers the button', (t) async {
    await show(t, FakeHost(startWorks: false));
    await t.tap(find.text(Strings.enable));
    await t.pumpAndSettle();
    expect(find.text(Strings.notProtecting), findsOneWidget);
    expect(find.text(Strings.startFailed), findsOneWidget);
    expect(find.text(Strings.enable), findsOneWidget);
  });
}
