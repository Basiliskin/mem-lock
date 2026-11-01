import 'package:flutter/material.dart';

import '../domain/detection_settings.dart';
import '../l10n/l10n.dart';
import '../ports/ports.dart';

typedef _D = DetectionSettings;

/// How one value is shown and edited. Whole numbers, except vehicle speed,
/// whose recommended value isn't one.
class _Field {
  const _Field({
    required this.min,
    required this.max,
    required this.step,
    required this.recommended,
    this.decimal = false,
  });

  final double min;
  final double max;
  final double step;
  final double recommended;
  final bool decimal;

  double? parse(String text) {
    final clean = text.trim().replaceAll(',', '.');
    final value = decimal ? double.tryParse(clean) : int.tryParse(clean);
    if (value == null) return null;
    final number = value.toDouble();
    return number >= min && number <= max ? number : null;
  }

  /// Moves to the next whole step, so 14.4 goes to 15 or 14.
  double stepped(String text, {required bool up}) {
    final clean = text.trim().replaceAll(',', '.');
    final parsed = double.tryParse(clean);
    final now = parsed == null || !parsed.isFinite ? recommended : parsed;
    final count = up ? (now / step).floor() + 1 : (now / step).ceil() - 1;
    return (count * step).clamp(min, max);
  }
}

String _format(double value) => value == value.truncateToDouble()
    ? value.toInt().toString()
    : value.toString();

final _fields = {
  DetectionValue.stayTime: _Field(
    min: _D.minStayTime.inMinutes.toDouble(),
    max: _D.maxStayTime.inMinutes.toDouble(),
    step: 1,
    recommended: _D.normal.stayTime.inMinutes.toDouble(),
  ),
  DetectionValue.stayArea: const _Field(
    min: _D.minStayMeters,
    max: _D.maxStayMeters,
    step: 5,
    recommended: 75,
  ),
  DetectionValue.vehicleSpeed: const _Field(
    min: _D.minVehicleKmh,
    max: _D.maxVehicleKmh,
    step: 1,
    recommended: _D.recommendedVehicleKmh,
    decimal: true,
  ),
  DetectionValue.walkingTime: _Field(
    min: _D.minWalkingAfterRide.inSeconds.toDouble(),
    max: _D.maxWalkingAfterRide.inSeconds.toDouble(),
    step: 5,
    recommended: _D.recommendedWalkingAfterRide.inSeconds.toDouble(),
  ),
};

double _valueOf(DetectionSettings s, DetectionValue v) => switch (v) {
  DetectionValue.stayTime => s.stayTime.inMinutes.toDouble(),
  DetectionValue.stayArea => s.stayMeters,
  DetectionValue.vehicleSpeed => s.vehicleKmh,
  DetectionValue.walkingTime => s.walkingAfterRide.inSeconds.toDouble(),
};

class AdvancedSettingsScreen extends StatefulWidget {
  const AdvancedSettingsScreen({
    super.key,
    required this.store,
    required this.link,
  });

  final DetectionSettingsStore store;
  final WatcherLink link;

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  final _controllers = {
    for (final v in DetectionValue.values) v: TextEditingController(),
  };
  DetectionSettings? _settings;
  Set<DetectionValue> _invalid = const {};
  List<DetectionValue> _risks = const [];
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    DetectionSettings settings;
    try {
      settings = await widget.store.read();
    } on Object {
      settings = DetectionSettings.normal;
    }
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _show(settings, DetectionValue.values);
    });
  }

  void _show(DetectionSettings s, Iterable<DetectionValue> values) {
    for (final v in values) {
      _controllers[v]!.text = _format(_valueOf(s, v));
    }
  }

  /// Any edit closes the warning and result, so a new value is checked again.
  void _edited() => setState(() {
    _risks = const [];
    _invalid = const {};
    _message = null;
  });

  void _step(DetectionValue v, {required bool up}) {
    final next = _fields[v]!.stepped(_controllers[v]!.text, up: up);
    _controllers[v]!.text = _format(next);
    _edited();
  }

  Future<void> _write(
    DetectionSettings settings,
    String savedMessage,
    Iterable<DetectionValue> show,
  ) async {
    final l10n = context.l10n;
    try {
      await widget.store.write(settings);
      // With no service running, it reads the settings when it next starts.
      widget.link.detectionSettingsChanged();
    } on Object {
      if (mounted) {
        setState(() {
          _risks = const [];
          _message = l10n.saveFailed;
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _show(settings, show);
      _risks = const [];
      _invalid = const {};
      _message = savedMessage;
    });
  }

  Future<void> _save({bool anyway = false}) async {
    final parsed = {
      for (final v in DetectionValue.values)
        v: _fields[v]!.parse(_controllers[v]!.text),
    };
    final invalid = {
      for (final e in parsed.entries)
        if (e.value == null) e.key,
    };
    if (invalid.isNotEmpty) {
      setState(() {
        _invalid = invalid;
        _risks = const [];
        _message = null;
      });
      return;
    }
    final settings = DetectionSettings(
      stayTime: Duration(minutes: parsed[DetectionValue.stayTime]!.toInt()),
      stayMeters: parsed[DetectionValue.stayArea]!,
      vehicleKmh: parsed[DetectionValue.vehicleSpeed]!,
      walkingAfterRide: Duration(
        seconds: parsed[DetectionValue.walkingTime]!.toInt(),
      ),
    );
    if (!anyway && settings.risks.isNotEmpty) {
      setState(() {
        _invalid = const {};
        _risks = settings.risks;
        _message = null;
      });
      return;
    }
    await _write(settings, context.l10n.valuesSaved, DetectionValue.values);
  }

  /// Saves at once and leaves other typed values for Save to check.
  Future<void> _pick(StayChoice choice) => _write(
    _settings!.withChoice(choice),
    context.l10n.valuesSaved,
    const [DetectionValue.stayTime, DetectionValue.stayArea],
  );

  Future<void> _reset() => _write(
    DetectionSettings.normal,
    context.l10n.valuesReset,
    DetectionValue.values,
  );

  String _choiceName(StayChoice? choice) => switch (choice) {
    StayChoice.moreOften => context.l10n.stayMoreOften,
    StayChoice.normal => context.l10n.stayNormal,
    StayChoice.lessOften => context.l10n.stayLessOften,
    null => context.l10n.advancedCustom,
  };

  String _label(DetectionValue v) => switch (v) {
    DetectionValue.stayTime => context.l10n.advancedStayTime,
    DetectionValue.stayArea => context.l10n.advancedStayArea,
    DetectionValue.vehicleSpeed => context.l10n.advancedSpeed,
    DetectionValue.walkingTime => context.l10n.advancedWalking,
  };

  String _unit(DetectionValue v) => switch (v) {
    DetectionValue.stayTime => context.l10n.unitMinutes,
    DetectionValue.stayArea => context.l10n.unitMeters,
    DetectionValue.vehicleSpeed => context.l10n.unitKmh,
    DetectionValue.walkingTime => context.l10n.unitSeconds,
  };

  String _risk(DetectionValue v) => switch (v) {
    DetectionValue.stayTime => context.l10n.riskStayTime,
    DetectionValue.stayArea => context.l10n.riskStayArea,
    DetectionValue.vehicleSpeed => context.l10n.riskSpeed,
    DetectionValue.walkingTime => context.l10n.riskWalking,
  };

  Widget _stepButton(DetectionValue v, {required bool up}) => IconButton(
    iconSize: 32,
    constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
    tooltip: up
        ? context.l10n.increaseValue(_label(v))
        : context.l10n.decreaseValue(_label(v)),
    icon: Icon(up ? Icons.add : Icons.remove),
    onPressed: () => _step(v, up: up),
  );

  Widget _field(DetectionValue v) {
    final field = _fields[v]!;
    final l10n = context.l10n;
    final min = _format(field.min);
    final max = _format(field.max);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_label(v)}, ${_unit(v)}',
            style: const TextStyle(fontSize: 20),
          ),
          Row(
            children: [
              _stepButton(v, up: false),
              Expanded(
                child: TextField(
                  key: ValueKey('field-${v.name}'),
                  controller: _controllers[v],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24),
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: field.decimal,
                  ),
                  decoration: InputDecoration(labelText: _label(v)),
                  onChanged: (_) => _edited(),
                ),
              ),
              _stepButton(v, up: true),
            ],
          ),
          Text(
            l10n.advancedRange(min, max, _unit(v), _format(field.recommended)),
            style: const TextStyle(fontSize: 16),
          ),
          if (_invalid.contains(v))
            Semantics(
              liveRegion: true,
              child: Text(
                l10n.advancedLimit(_label(v), min, max, _unit(v)),
                key: ValueKey('error-${v.name}'),
                style: TextStyle(
                  fontSize: 20,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _preset(StayChoice choice) {
    final chosen = choice == _settings!.exactChoice;
    final name = _choiceName(choice);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        selected: chosen,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: chosen
              ? FilledButton(
                  onPressed: () => _pick(choice),
                  child: Text(name, style: const TextStyle(fontSize: 20)),
                )
              : OutlinedButton(
                  onPressed: () => _pick(choice),
                  child: Text(name, style: const TextStyle(fontSize: 20)),
                ),
        ),
      ),
    );
  }

  Widget _riskWarning() {
    final l10n = context.l10n;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.riskTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            for (final r in _risks)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_risk(r), style: const TextStyle(fontSize: 20)),
              ),
            const SizedBox(height: 12),
            _button(l10n.saveAnyway, () => _save(anyway: true), filled: true),
            _button(l10n.changeValues, _edited),
          ],
        ),
      ),
    );
  }

  Widget _button(String text, VoidCallback onPressed, {bool filled = false}) {
    final child = Text(text, style: const TextStyle(fontSize: 20));
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: filled
            ? FilledButton(onPressed: onPressed, child: child)
            : OutlinedButton(onPressed: onPressed, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = _settings;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.advancedSettings)),
      body: settings == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  l10n.advancedNow(_choiceName(settings.exactChoice)),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 12),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        _message!,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                for (final c in StayChoice.values) _preset(c),
                Text(
                  l10n.advancedPresetHelp,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                for (final v in DetectionValue.values) _field(v),
                if (_risks.isNotEmpty) _riskWarning(),
                if (_risks.isEmpty) ...[
                  _button(l10n.saveValues, _save, filled: true),
                ],
                _button(l10n.resetToRecommended, _reset),
              ],
            ),
    );
  }
}
