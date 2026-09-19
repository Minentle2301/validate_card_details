import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/credit_card.dart';
import '../models/banned_country.dart';

class StorageService extends ChangeNotifier {
  static const String _cardsKey = 'captured_cards';
  static const String _bannedCountriesKey = 'banned_countries_v2';

  // Session-level memory tracking
  final List<CreditCardModel> _sessionCards = [];

  List<CreditCardModel> get sessionCards => List.unmodifiable(_sessionCards);

  /// Loads stored cards from SharedPreferences
  Future<List<CreditCardModel>> loadCards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cardsKey);
      if (jsonString == null || jsonString.isEmpty) return [];
      return CreditCardModel.listFromJsonString(jsonString);
    } catch (_) {
      return [];
    }
  }

  /// Saves cards to SharedPreferences
  Future<void> saveCards(List<CreditCardModel> cards) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cardsKey, CreditCardModel.listToJsonString(cards));
  }

  /// Adds a new card if it doesn't already exist (prevents duplicates by normalized card number).
  /// Returns `true` if card was saved, `false` if duplicate.
  Future<bool> addCardIfNotDuplicate(CreditCardModel card) async {
    final existingCards = await loadCards();
    final cleanInput = card.cleanCardNumber;

    final isDuplicate =
        existingCards.any((c) => c.cleanCardNumber == cleanInput);
    if (isDuplicate) return false;

    existingCards.insert(0, card);
    await saveCards(existingCards);

    // Track in session
    _sessionCards.insert(0, card);
    notifyListeners();
    return true;
  }

  /// Removes a card by ID
  Future<void> deleteCard(String id) async {
    final existingCards = await loadCards();
    existingCards.removeWhere((c) => c.id == id);
    await saveCards(existingCards);
    _sessionCards.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  /// Clears all captured cards
  Future<void> clearAllCards() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cardsKey);
    _sessionCards.clear();
    notifyListeners();
  }

  /// Loads banned countries from storage or seeds defaults
  Future<List<BannedCountry>> loadBannedCountries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_bannedCountriesKey);
      if (jsonString == null || jsonString.isEmpty) {
        final defaults = BannedCountry.getDefaultSanctionedList();
        await saveBannedCountries(defaults);
        return defaults;
      }
      return BannedCountry.listFromJsonString(jsonString);
    } catch (_) {
      return BannedCountry.getDefaultSanctionedList();
    }
  }

  /// Saves banned countries list to storage
  Future<void> saveBannedCountries(List<BannedCountry> countries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _bannedCountriesKey, BannedCountry.listToJsonString(countries));
    notifyListeners();
  }

  /// Adds a new banned country
  Future<bool> addBannedCountry(BannedCountry country) async {
    final current = await loadBannedCountries();
    final exists = current.any(
      (c) =>
          c.name.toLowerCase() == country.name.toLowerCase() ||
          c.code.toLowerCase() == country.code.toLowerCase(),
    );
    if (exists) return false;
    current.add(country);
    await saveBannedCountries(current);
    return true;
  }

  /// Removes a banned country by name or ISO code
  Future<void> removeBannedCountry(String countryNameOrCode) async {
    final current = await loadBannedCountries();
    final target = countryNameOrCode.toLowerCase();
    current.removeWhere((c) =>
        c.name.toLowerCase() == target || c.code.toLowerCase() == target);
    await saveBannedCountries(current);
  }

  /// Resets banned countries back to system defaults
  Future<List<BannedCountry>> resetBannedCountriesToDefault() async {
    final defaults = BannedCountry.getDefaultSanctionedList();
    await saveBannedCountries(defaults);
    return defaults;
  }
}
