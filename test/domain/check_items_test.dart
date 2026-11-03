import 'package:flutter_test/flutter_test.dart';
import 'package:leavecheck/domain/check_items.dart';

void main() {
  test('items survive saving, with their on/off and custom text', () {
    final items = [
      const CheckItem.builtIn(BuiltInItem.gas, on: false),
      const CheckItem.custom('Umbrella'),
    ];
    final back = parseCheckItems(encodeCheckItems(items));
    expect(back.first.builtIn, BuiltInItem.gas);
    expect(back.first.on, isFalse);
    expect(back.last.text, 'Umbrella');
    expect(back.last.on, isTrue);
  });

  test('nothing saved or bad text gives the defaults', () {
    expect(parseCheckItems(null), defaultCheckItems);
    expect(parseCheckItems('{bad'), defaultCheckItems);
    expect(
      parseCheckItems('[{"builtIn":"nope","on":true}]'),
      defaultCheckItems,
    );
  });

  test('withOn keeps what the item is', () {
    expect(const CheckItem.custom('Hat').withOn(false).text, 'Hat');
    expect(
      const CheckItem.builtIn(BuiltInItem.keys).withOn(false).builtIn,
      BuiltInItem.keys,
    );
  });
}
