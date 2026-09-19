import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:validate_card_details/models/credit_card.dart';
import 'package:validate_card_details/models/banned_country.dart';
import 'package:validate_card_details/services/storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StorageService - Card Storage & Duplicate Prevention', () {
    test('Adds new card successfully to storage', () async {
      final service = StorageService();
      final card = CreditCardModel(
        id: '1',
        cardNumber: '4532718293014421',
        cardType: 'Visa',
        cvv: '123',
        issuingCountry: 'United States',
        createdAt: DateTime.now(),
      );

      final added = await service.addCardIfNotDuplicate(card);
      expect(added, isTrue);

      final loaded = await service.loadCards();
      expect(loaded.length, equals(1));
      expect(loaded.first.cleanCardNumber, equals('4532718293014421'));
    });

    test('Prevents duplicate card from being saved twice', () async {
      final service = StorageService();
      final card1 = CreditCardModel(
        id: '1',
        cardNumber: '4532 7182 9301 4421',
        cardType: 'Visa',
        cvv: '123',
        issuingCountry: 'United States',
        createdAt: DateTime.now(),
      );

      final card2 = CreditCardModel(
        id: '2',
        cardNumber: '4532718293014421', // Same number, different formatting & ID
        cardType: 'Visa',
        cvv: '999',
        issuingCountry: 'Canada',
        createdAt: DateTime.now(),
      );

      final firstAdded = await service.addCardIfNotDuplicate(card1);
      final secondAdded = await service.addCardIfNotDuplicate(card2);

      expect(firstAdded, isTrue);
      expect(secondAdded, isFalse); // Duplicate blocked!

      final loaded = await service.loadCards();
      expect(loaded.length, equals(1));
    });
  });

  group('StorageService - Banned Countries Management', () {
    test('Seeds default banned countries on first load', () async {
      final service = StorageService();
      final countries = await service.loadBannedCountries();

      expect(countries.isNotEmpty, isTrue);
      expect(countries.any((c) => c.name == 'North Korea'), isTrue);
    });

    test('Adds and removes custom banned country', () async {
      final service = StorageService();

      final newBan = BannedCountry(
        name: 'Atlantis',
        code: 'AT',
        reason: 'Test Restriction',
      );

      final added = await service.addBannedCountry(newBan);
      expect(added, isTrue);

      var current = await service.loadBannedCountries();
      expect(current.any((c) => c.name == 'Atlantis'), isTrue);

      await service.removeBannedCountry('Atlantis');
      current = await service.loadBannedCountries();
      expect(current.any((c) => c.name == 'Atlantis'), isFalse);
    });
  });
}
