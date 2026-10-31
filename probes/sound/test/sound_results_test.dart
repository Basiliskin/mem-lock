import 'package:flutter_test/flutter_test.dart';
import 'package:sound_probe/sound_results.dart';

Trial voice(String phone, Condition c, {bool heard = true, bool felt = true}) =>
    Trial(phone, c, SoundKind.voice, heard: heard, felt: felt);

void main() {
  test('a trial survives a round trip through a log line', () {
    final t = voice('Pixel 7', Condition.silent, heard: false);
    final b = Trial.parse(t.toLine());
    expect(b.phone, 'Pixel 7');
    expect(b.condition, Condition.silent);
    expect(b.kind, SoundKind.voice);
    expect(b.heard, isFalse);
    expect(b.felt, isTrue);
  });

  test('parseTrials skips damaged lines', () {
    final text = '${voice('A', Condition.normal).toLine()}\n{"phone":';
    expect(parseTrials(text), hasLength(1));
  });

  List<Trial> fives(String phone, {int heard = 5}) => [
    for (var i = 0; i < 5; i++)
      voice(phone, Condition.normal, heard: i < heard),
  ];

  group('early FT-5 verdict', () {
    test('passes with 5 of 5 on two phone brands', () {
      expect(voiceVerdict([...fives('A'), ...fives('B')]), Verdict.pass);
    });

    test('fails when any phone misses one, even with enough tries', () {
      expect(
        voiceVerdict([...fives('A'), ...fives('B', heard: 4)]),
        Verdict.fail,
      );
    });

    test('needs a second brand', () {
      expect(voiceVerdict(fives('A')), Verdict.notEnoughData);
    });

    test('needs 5 tries on each phone', () {
      expect(
        voiceVerdict([...fives('A'), voice('B', Condition.normal)]),
        Verdict.notEnoughData,
      );
    });

    test('a miss fails straight away, with no need for more tries', () {
      expect(
        voiceVerdict([voice('A', Condition.normal, heard: false)]),
        Verdict.fail,
      );
    });

    test('silent and tone trials do not count towards it', () {
      final other = [
        for (var i = 0; i < 5; i++) ...[
          voice('A', Condition.silent, heard: false),
          Trial('B', Condition.normal, SoundKind.tone, heard: true, felt: true),
        ],
      ];
      expect(voiceVerdict(other), Verdict.notEnoughData);
    });
  });

  test('report gives heard and felt counts per phone and condition', () {
    final text = report([
      voice('A', Condition.silent),
      voice('A', Condition.silent, heard: false, felt: false),
      Trial('A', Condition.dnd, SoundKind.tone, heard: false, felt: true),
    ]);
    expect(text, contains('A | silent | voice | heard 1 of 2 | felt 1 of 2'));
    expect(text, contains('A | dnd | tone | heard 0 of 1 | felt 1 of 1'));
    expect(text, contains('Early FT-5: notEnoughData'));
  });

  group('wav', () {
    test('has a valid header and the expected length', () {
      final b = sineWav(seconds: 1, sampleRate: 8000);
      expect(String.fromCharCodes(b.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(b.sublist(8, 12)), 'WAVE');
      expect(b.length, 44 + 8000 * 2);
    });
  });
}
