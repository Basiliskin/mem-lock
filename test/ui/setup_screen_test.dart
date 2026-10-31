import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_alert/l10n/strings.dart';
import 'package:geo_alert/ports/ports.dart';
import 'package:geo_alert/ui/app_root.dart';
import 'package:geo_alert/ui/setup_screen.dart';

class FakeGate implements PermissionGate {
  final states = {
    for (final p in SetupPermission.values) p: PermissionState.denied,
  };
  PermissionState onRequest = PermissionState.granted;
  bool throws = false;
  int settingsOpened = 0;
  final requested = <SetupPermission>[];
  @override
  Future<PermissionState> check(SetupPermission p) async => states[p]!;
  @override
  Future<PermissionState> request(SetupPermission p) async {
    if (throws) throw StateError('plugin');
    requested.add(p);
    return states[p] = onRequest;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;
}

class FakeHost implements BackgroundHost {
  bool works = true;
  int starts = 0;
  @override
  Future<bool> isRunning() async => starts > 0 && works;
  @override
  Future<bool> start() async {
    starts++;
    return works;
  }
}

class FakeSetup implements SetupStore {
  bool done = false;
  bool failRead = false;
  @override
  Future<bool> isDone() async {
    if (failRead) throw StateError('disk');
    return done;
  }

  @override
  Future<void> markDone() async => done = true;
}

void main() {
  late FakeGate gate;
  late FakeHost host;
  late FakeSetup store;
  late bool finished;

  setUp(() {
    gate = FakeGate();
    host = FakeHost();
    store = FakeSetup();
    finished = false;
  });

  Future<void> show(WidgetTester t) async {
    await t.pumpWidget(
      MaterialApp(
        home: SetupScreen(
          gate: gate,
          host: host,
          store: store,
          quietPlaces: (_) => const Text('quiet-screen'),
          reminderOptions: (_) => const Text('options-screen'),
          onDone: () => finished = true,
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> tap(WidgetTester t, String text) async {
    await t.tap(find.text(text));
    await t.pumpAndSettle();
  }

  Future<void> toPermission(WidgetTester t) async {
    await show(t);
    await tap(t, Strings.setupNext);
  }

  Future<void> throughAll(WidgetTester t) async {
    await show(t);
    await tap(t, Strings.setupNext);
    for (var i = 0; i < 4; i++) {
      await tap(t, Strings.setupAllow);
      await tap(t, Strings.setupNext);
    }
    for (var i = 0; i < 3; i++) {
      await tap(t, Strings.setupNext);
    }
  }

  testWidgets('AC-7.1: finishing starts watching with no further action', (
    t,
  ) async {
    await throughAll(t);
    expect(find.text(Strings.setupDoneTitle), findsOneWidget);
    expect(host.starts, 0);
    await tap(t, Strings.setupStart);
    expect(host.starts, 1);
    expect(store.done, isTrue);
    expect(finished, isTrue);
  });

  testWidgets('AC-7.2: guides through all four permissions in order', (
    t,
  ) async {
    await throughAll(t);
    expect(gate.requested, [
      SetupPermission.location,
      SetupPermission.notifications,
      SetupPermission.activity,
      SetupPermission.battery,
    ]);
  });

  testWidgets('a failed start stays in setup and says so', (t) async {
    host.works = false;
    await throughAll(t);
    await tap(t, Strings.setupStart);
    expect(store.done, isFalse);
    expect(finished, isFalse);
    expect(find.text(Strings.startFailed), findsOneWidget);
  });

  testWidgets('AC-7.3: a refusal explains and blocks Next, without crashing', (
    t,
  ) async {
    gate.onRequest = PermissionState.denied;
    await toPermission(t);
    await tap(t, Strings.setupAllow);
    expect(find.text(Strings.setupWhyLocation), findsOneWidget);
    await tap(t, Strings.setupNext);
    expect(find.text(Strings.setupLocationTitle), findsOneWidget);
    expect(find.text(Strings.setupBlocked), findsOneWidget);
  });

  testWidgets('AC-7.3: a permanent refusal leads to system settings', (
    t,
  ) async {
    gate.onRequest = PermissionState.permanentlyDenied;
    await toPermission(t);
    await tap(t, Strings.setupAllow);
    await tap(t, Strings.setupOpenSettings);
    expect(gate.settingsOpened, 1);
  });

  testWidgets('a failing plugin counts as a refusal', (t) async {
    gate.throws = true;
    await toPermission(t);
    await tap(t, Strings.setupAllow);
    expect(find.text(Strings.setupAllow), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('coming back from settings rechecks the permission', (t) async {
    await toPermission(t);
    gate.states[SetupPermission.location] = PermissionState.granted;
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pumpAndSettle();
    expect(find.text(Strings.setupAllowed), findsOneWidget);
  });

  testWidgets('a permission already granted needs no tap', (t) async {
    gate.states[SetupPermission.location] = PermissionState.granted;
    await toPermission(t);
    await tap(t, Strings.setupNext);
    expect(find.text(Strings.setupNotificationsTitle), findsOneWidget);
  });

  testWidgets('Back returns a step, and the first step has none', (t) async {
    await show(t);
    expect(find.text(Strings.setupBack), findsNothing);
    await tap(t, Strings.setupNext);
    await tap(t, Strings.setupBack);
    expect(find.text(Strings.setupWelcomeTitle), findsOneWidget);
  });

  testWidgets(
    'AC-7.4 and AC-3.5: states the phone advice and silent behaviour',
    (t) async {
      await throughAll(t);
      await tap(t, Strings.setupBack);
      await tap(t, Strings.setupBack);
      await tap(t, Strings.setupBack);
      expect(find.text(Strings.setupPhoneText), findsOneWidget);
      expect(Strings.setupPhoneText, contains('забытой сумке'));
      await tap(t, Strings.setupNext);
      await tap(t, Strings.setupNext);
      expect(find.text(Strings.setupSilentText), findsOneWidget);
    },
  );

  testWidgets('the Reminder step opens the options screen', (t) async {
    await throughAll(t);
    await tap(t, Strings.setupBack);
    await tap(t, Strings.setupChangeOptions);
    expect(find.text('options-screen'), findsOneWidget);
  });

  testWidgets('the Quiet Place step opens the list screen', (t) async {
    await throughAll(t);
    await tap(t, Strings.setupBack);
    await tap(t, Strings.setupBack);
    await tap(t, Strings.setupOpenQuiet);
    expect(find.text('quiet-screen'), findsOneWidget);
  });

  group('AppRoot', () {
    Future<void> root(WidgetTester t) async {
      await t.pumpWidget(
        MaterialApp(
          home: AppRoot(
            store: store,
            setup: (done) =>
                TextButton(onPressed: done, child: const Text('setup')),
            main: (_) => const Text('main'),
          ),
        ),
      );
      await t.pumpAndSettle();
    }

    testWidgets('a fresh install shows setup, then main', (t) async {
      await root(t);
      await tap(t, 'setup');
      expect(find.text('main'), findsOneWidget);
    });

    testWidgets('finished setup goes straight to main', (t) async {
      store.done = true;
      await root(t);
      expect(find.text('main'), findsOneWidget);
    });

    testWidgets('an unreadable flag shows setup, not a crash', (t) async {
      store.failRead = true;
      await root(t);
      expect(find.text('setup'), findsOneWidget);
    });
  });
}
