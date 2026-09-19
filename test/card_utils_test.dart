import 'package:flutter_test/flutter_test.dart';
import 'package:validate_card_details/services/card_utils.dart';

void main() {
  group('CardUtils - Card Type Inference', () {
    test('Infers Visa card starting with 4', () {
      expect(CardUtils.inferCardType('4532 7182 9301 4421'), equals(CardBrands.visa));
    });

    test('Infers MasterCard in 51-55 range', () {
      expect(CardUtils.inferCardType('5412 7512 3412 8890'), equals(CardBrands.masterCard));
    });

    test('Infers MasterCard in 2221-2720 range', () {
      expect(CardUtils.inferCardType('2223 0000 0000 0000'), equals(CardBrands.masterCard));
    });

    test('Infers American Express starting with 34 or 37', () {
      expect(CardUtils.inferCardType('3782 8224 6310 005'), equals(CardBrands.americanExpress));
      expect(CardUtils.inferCardType('3400 1234 5678 901'), equals(CardBrands.americanExpress));
    });

    test('Infers Discover card starting with 6011', () {
      expect(CardUtils.inferCardType('6011 4912 8830 1928'), equals(CardBrands.discover));
    });

    test('Infers JCB card starting with 35', () {
      expect(CardUtils.inferCardType('3528 1234 5678 9012'), equals(CardBrands.jcb));
    });

    test('Infers UnionPay card starting with 62', () {
      expect(CardUtils.inferCardType('6212 3456 7890 1234'), equals(CardBrands.unionPay));
    });

    test('Returns Unknown for empty or unrecognized prefix', () {
      expect(CardUtils.inferCardType(''), equals(CardBrands.unknown));
      expect(CardUtils.inferCardType('9999 0000 0000 0000'), equals(CardBrands.unknown));
    });
  });

  group('CardUtils - Luhn Checksum Algorithm', () {
    test('Validates mathematically valid card numbers', () {
      expect(CardUtils.luhnCheck('4242424242424242'), isTrue);
      expect(CardUtils.luhnCheck('5500000000000004'), isTrue);
    });

    test('Rejects invalid card checksums', () {
      expect(CardUtils.luhnCheck('4532718293014420'), isFalse);
      expect(CardUtils.luhnCheck('1234567812345678'), isFalse);
      expect(CardUtils.luhnCheck('123'), isFalse);
    });
  });

  group('CardUtils - CVV Validation', () {
    test('Requires 4 digits for American Express', () {
      expect(CardUtils.validateCVV('1234', CardBrands.americanExpress), isTrue);
      expect(CardUtils.validateCVV('123', CardBrands.americanExpress), isFalse);
    });

    test('Requires 3 digits for Visa/MasterCard', () {
      expect(CardUtils.validateCVV('123', CardBrands.visa), isTrue);
      expect(CardUtils.validateCVV('1234', CardBrands.visa), isFalse);
    });
  });

  group('CardUtils - Country Ban Detection', () {
    test('Detects banned countries case-insensitively', () {
      final banned = ['North Korea', 'Iran', 'Syria', 'Cuba', 'Russia'];

      expect(CardUtils.isCountryBanned('North Korea', banned), isTrue);
      expect(CardUtils.isCountryBanned('north korea', banned), isTrue);
      expect(CardUtils.isCountryBanned('IRAN', banned), isTrue);
      expect(CardUtils.isCountryBanned('United States', banned), isFalse);
      expect(CardUtils.isCountryBanned('South Africa', banned), isFalse);
    });
  });
}
