import 'package:flutter/widgets.dart';

import '../domain/check_items.dart';
import '../l10n/l10n.dart';

String checkItemIcon(CheckItem item) => switch (item.builtIn) {
  BuiltInItem.keys => '🔑',
  BuiltInItem.wallet => '👛',
  BuiltInItem.phone => '📱',
  BuiltInItem.glasses => '👓',
  BuiltInItem.gas => '🔥',
  BuiltInItem.door => '🚪',
  null => '✅',
};

String checkItemLabel(BuildContext context, CheckItem item) {
  final text = context.l10n;
  return switch (item.builtIn) {
    BuiltInItem.keys => text.itemKeys,
    BuiltInItem.wallet => text.itemWallet,
    BuiltInItem.phone => text.itemPhone,
    BuiltInItem.glasses => text.itemGlasses,
    BuiltInItem.gas => text.itemGas,
    BuiltInItem.door => text.itemDoor,
    null => item.text!,
  };
}
