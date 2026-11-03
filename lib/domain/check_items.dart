import 'dart:convert';

/// The built-in things the Wearer is asked about after leaving home.
enum BuiltInItem { keys, wallet, phone, glasses, gas, door }

/// One thing to check. A built-in item has [builtIn]; one the Helper added has
/// [text] instead.
class CheckItem {
  const CheckItem.builtIn(BuiltInItem this.builtIn, {this.on = true})
    : text = null;
  const CheckItem.custom(String this.text, {this.on = true}) : builtIn = null;

  final BuiltInItem? builtIn;
  final String? text;
  final bool on;

  CheckItem withOn(bool value) => builtIn != null
      ? CheckItem.builtIn(builtIn!, on: value)
      : CheckItem.custom(text!, on: value);
}

const defaultCheckItems = [
  CheckItem.builtIn(BuiltInItem.keys),
  CheckItem.builtIn(BuiltInItem.wallet),
  CheckItem.builtIn(BuiltInItem.phone),
  CheckItem.builtIn(BuiltInItem.glasses, on: false),
  CheckItem.builtIn(BuiltInItem.gas),
  CheckItem.builtIn(BuiltInItem.door),
];

String encodeCheckItems(List<CheckItem> items) => jsonEncode([
  for (final i in items)
    {'builtIn': i.builtIn?.name, 'text': i.text, 'on': i.on},
]);

/// Nothing saved or unreadable text gives the defaults, so the check always
/// has something to ask.
List<CheckItem> parseCheckItems(String? text) {
  if (text == null) return defaultCheckItems;
  try {
    return [
      for (final m in jsonDecode(text) as List<dynamic>)
        if ((m as Map<String, dynamic>)['builtIn'] case final String name)
          CheckItem.builtIn(
            BuiltInItem.values.byName(name),
            on: m['on'] as bool,
          )
        else
          CheckItem.custom(m['text'] as String, on: m['on'] as bool),
    ];
  } on FormatException {
    return defaultCheckItems;
  } on TypeError {
    return defaultCheckItems;
  } on ArgumentError {
    return defaultCheckItems;
  }
}
