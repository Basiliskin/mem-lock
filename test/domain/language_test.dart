import 'package:flutter_test/flutter_test.dart';
import 'package:leavecheck/domain/language.dart';

void main() {
  test('AC-13.1: follows a Russian or English phone', () {
    expect(resolveLanguage(null, 'ru'), AppLanguage.ru);
    expect(resolveLanguage(null, 'en'), AppLanguage.en);
  });

  test('AC-13.2: any other phone language gives English', () {
    expect(resolveLanguage(null, 'de'), AppLanguage.en);
    expect(resolveLanguage(null, ''), AppLanguage.en);
  });

  test('AC-13.3: the saved choice beats the phone', () {
    expect(resolveLanguage(AppLanguage.en, 'ru'), AppLanguage.en);
    expect(resolveLanguage(AppLanguage.ru, 'de'), AppLanguage.ru);
  });
}
