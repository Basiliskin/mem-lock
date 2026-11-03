import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../ports/ports.dart';

class _Step {
  const _Step(
    this.title,
    this.text, {
    this.permission,
    this.why,
    this.openLabel,
    this.open,
  });

  final String title;
  final String text;
  final SetupPermission? permission;
  final String? why;
  final String? openLabel;
  final WidgetBuilder? open;
}

/// One question per screen. Nothing starts watching until the last step.
class SetupScreen extends StatefulWidget {
  const SetupScreen({
    super.key,
    required this.gate,
    required this.host,
    required this.store,
    required this.activityCheck,
    required this.quietPlaces,
    this.homeWifi,
    required this.reminderOptions,
    required this.onDone,
  });

  final PermissionGate gate;
  final BackgroundHost host;
  final SetupStore store;
  final ActivityAvailability activityCheck;
  final WidgetBuilder quietPlaces;

  /// When set, marking the home Wi-Fi replaces marking a Quiet Place.
  final WidgetBuilder? homeWifi;
  final WidgetBuilder reminderOptions;
  final VoidCallback onDone;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> with WidgetsBindingObserver {
  List<_Step> get _steps => [
    _Step(context.l10n.setupWelcomeTitle, context.l10n.setupWelcomeText),
    _Step(
      context.l10n.setupLocationTitle,
      context.l10n.setupLocationText,
      permission: SetupPermission.location,
      why: context.l10n.setupWhyLocation,
    ),
    _Step(
      context.l10n.setupNotificationsTitle,
      context.l10n.setupNotificationsText,
      permission: SetupPermission.notifications,
      why: context.l10n.setupWhyNotifications,
    ),
    _Step(
      context.l10n.setupActivityTitle,
      context.l10n.setupActivityText,
      permission: SetupPermission.activity,
      why: context.l10n.setupWhyActivity,
    ),
    _Step(
      context.l10n.setupBatteryTitle,
      context.l10n.setupBatteryText,
      permission: SetupPermission.battery,
      why: context.l10n.setupWhyBattery,
    ),
    _Step(context.l10n.setupPhoneTitle, context.l10n.setupPhoneText),
    if (widget.homeWifi case final home?)
      _Step(
        context.l10n.setupHomeTitle,
        context.l10n.setupHomeText,
        openLabel: context.l10n.setupOpenHome,
        open: home,
      )
    else
      _Step(
        context.l10n.setupQuietTitle,
        context.l10n.setupQuietText,
        openLabel: context.l10n.setupOpenQuiet,
        open: widget.quietPlaces,
      ),
    _Step(
      context.l10n.setupOptionsTitle,
      context.l10n.setupSilentText,
      openLabel: context.l10n.setupChangeOptions,
      open: widget.reminderOptions,
    ),
    _Step(context.l10n.setupDoneTitle, context.l10n.setupDoneText),
  ];

  int _index = 0;
  PermissionState _state = PermissionState.denied;
  bool _blockedTap = false;
  bool _startFailed = false;
  bool _busy = false;
  bool _noRideDetection = false;

  _Step get _step => _steps[_index];
  bool get _isLast => _index == _steps.length - 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkActivity();
  }

  /// A failing check makes no claim about the phone.
  Future<void> _checkActivity() async {
    bool available;
    try {
      available = await widget.activityCheck.isAvailable();
    } on Object {
      available = true;
    }
    if (mounted && !available) setState(() => _noRideDetection = true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Picks up a permission granted in the phone's settings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _recheck();
  }

  Future<void> _recheck() async {
    final permission = _step.permission;
    if (permission == null) return;
    await _apply(permission, () => widget.gate.check(permission));
  }

  Future<void> _apply(
    SetupPermission permission,
    Future<PermissionState> Function() action,
  ) async {
    PermissionState state;
    try {
      state = await action();
    } on Object {
      state = PermissionState.denied;
    }
    if (mounted && _step.permission == permission) {
      setState(() {
        _state = state;
        if (state == PermissionState.granted) _blockedTap = false;
      });
    }
  }

  void _go(int index) {
    setState(() {
      _index = index;
      _state = PermissionState.denied;
      _blockedTap = false;
      _startFailed = false;
    });
    _recheck();
  }

  void _next() {
    if (_step.permission != null && _state != PermissionState.granted) {
      setState(() => _blockedTap = true);
      return;
    }
    _go(_index + 1);
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _startFailed = false;
    });
    bool started;
    try {
      started = await widget.host.start();
      if (started) await widget.store.markDone();
    } on Object {
      started = false;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _startFailed = !started;
    });
    if (started) widget.onDone();
  }

  Widget _button(String text, VoidCallback? onTap, {bool primary = false}) =>
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: primary
              ? FilledButton(
                  onPressed: onTap,
                  child: Text(text, style: const TextStyle(fontSize: 20)),
                )
              : OutlinedButton(
                  onPressed: onTap,
                  child: Text(text, style: const TextStyle(fontSize: 20)),
                ),
        ),
      );

  Widget _note(String text) => Semantics(
    liveRegion: true,
    child: Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      color: const Color(0xFFFFF3C4),
      child: Text(text, style: const TextStyle(fontSize: 20)),
    ),
  );

  List<Widget> _permissionPart(_Step step) {
    final permission = step.permission!;
    return switch (_state) {
      PermissionState.granted => [
        Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            context.l10n.setupAllowed,
            style: TextStyle(fontSize: 20),
          ),
        ),
      ],
      PermissionState.denied => [
        _button(
          context.l10n.setupAllow,
          () => _apply(permission, () => widget.gate.request(permission)),
          primary: true,
        ),
        _note(step.why!),
      ],
      PermissionState.permanentlyDenied => [
        _button(
          context.l10n.setupOpenSettings,
          () => widget.gate.openSettings(),
          primary: true,
        ),
        _note(step.why!),
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final step = _step;
    final open = step.open;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      context.l10n.setupProgress(_index + 1, _steps.length),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      header: true,
                      liveRegion: true,
                      child: Text(
                        step.title,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(step.text, style: const TextStyle(fontSize: 20)),
                    if (step.permission != null) ..._permissionPart(step),
                    if (_noRideDetection &&
                        step.permission == SetupPermission.activity)
                      _note(context.l10n.setupNoRideDetection),
                    if (open != null)
                      _button(
                        step.openLabel!,
                        () =>
                            Navigator.of(context)
                                .push(MaterialPageRoute<void>(builder: open)),
                      ),
                    if (_blockedTap) _note(context.l10n.setupBlocked),
                    if (_startFailed) _note(context.l10n.startFailed),
                  ],
                ),
              ),
              _button(
                _isLast ? context.l10n.setupStart : context.l10n.setupNext,
                _busy ? null : (_isLast ? _start : _next),
                primary: true,
              ),
              if (_index > 0)
                _button(
                  context.l10n.setupBack,
                  _busy ? null : () => _go(_index - 1),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
