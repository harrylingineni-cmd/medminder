import 'package:flutter_test/flutter_test.dart';
import 'package:med_app/generic_medicine_data.dart';

void main() {
  group('India generic lookup', () {
    test(
      'matches brand names without case or surrounding-space sensitivity',
      () {
        expect(findIndiaGeneric('  CROCIN '), 'Paracetamol');
        expect(findIndiaGeneric('augmentin'), 'Amoxicillin + Clavulanic acid');
      },
    );

    test('does not guess when a brand is not in the curated list', () {
      expect(findIndiaGeneric('Unknown medicine'), isNull);
      expect(findIndiaGeneric(''), isNull);
    });

    test('suggestions are prefix-only, sorted, and limited', () {
      expect(suggestIndiaBrandNames('a', limit: 3), [
        'Allegra',
        'Amlokind',
        'Amlong',
      ]);
      expect(suggestIndiaBrandNames('mlok'), isEmpty);
    });
  });
}
