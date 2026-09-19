import 'package:flutter/material.dart';

/// Card brand constants
class CardBrands {
  static const String visa = 'Visa';
  static const String masterCard = 'MasterCard';
  static const String americanExpress = 'American Express';
  static const String discover = 'Discover';
  static const String jcb = 'JCB';
  static const String dinersClub = 'Diners Club';
  static const String unionPay = 'UnionPay';
  static const String unknown = 'Unknown';
}

/// Utility class for credit card analysis, validation, and country handling.
class CardUtils {
  /// Infers the card brand based on Bank Identification Number (BIN) patterns.
  static String inferCardType(String number) {
    final clean = number.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return CardBrands.unknown;

    // Visa: starts with 4
    if (clean.startsWith('4')) {
      return CardBrands.visa;
    }

    // MasterCard: starts with 51-55 or 2221-2720
    if (RegExp(r'^5[1-5]').hasMatch(clean) ||
        RegExp(r'^(222[1-9]|22[3-9]\d|2[3-6]\d{2}|27[01]\d|2720)').hasMatch(clean)) {
      return CardBrands.masterCard;
    }

    // American Express: starts with 34 or 37
    if (RegExp(r'^3[47]').hasMatch(clean)) {
      return CardBrands.americanExpress;
    }

    // Discover: starts with 6011, 65, 644-649, 622126-622925
    if (RegExp(r'^(6011|65|64[4-9]|622)').hasMatch(clean)) {
      return CardBrands.discover;
    }

    // JCB: starts with 3528-3589 or 2131, 1800
    if (RegExp(r'^(35\d{2}|2131|1800)').hasMatch(clean)) {
      return CardBrands.jcb;
    }

    // Diners Club: starts with 300-305, 36, 38
    if (RegExp(r'^3(?:0[0-5]|[68])').hasMatch(clean)) {
      return CardBrands.dinersClub;
    }

    // UnionPay: starts with 62 or 81
    if (RegExp(r'^(62|81)').hasMatch(clean)) {
      return CardBrands.unionPay;
    }

    return CardBrands.unknown;
  }

  /// Luhn checksum validation algorithm.
  /// Returns true if the number is mathematically valid.
  static bool luhnCheck(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 12) return false;

    int sum = 0;
    final reversed = digits.split('').reversed.toList();

    for (int i = 0; i < reversed.length; i++) {
      int digit = int.parse(reversed[i]);
      if (i % 2 == 1) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
    }

    return sum % 10 == 0;
  }

  /// Validates CVV length based on card brand.
  /// Amex requires 4 digits; most others require 3 digits.
  static bool validateCVV(String cvv, String cardType) {
    final clean = cvv.replaceAll(RegExp(r'\D'), '');
    if (cardType == CardBrands.americanExpress) {
      return clean.length == 4;
    } else if (cardType == CardBrands.unknown) {
      return clean.length == 3 || clean.length == 4;
    }
    return clean.length == 3;
  }

  /// Formats raw digit string into spaced groups of 4 digits.
  static String formatCardNumber(String input) {
    final clean = input.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }

  /// Checks whether a given country matches any banned country (case-insensitive).
  static bool isCountryBanned(String country, List<String> bannedList) {
    if (country.trim().isEmpty) return false;
    final target = country.trim().toLowerCase();
    return bannedList.any((banned) => banned.trim().toLowerCase() == target);
  }

  /// Returns brand accent color for UI design
  static Color getBrandColor(String cardType) {
    switch (cardType) {
      case CardBrands.visa:
        return const Color(0xFF1A1F71); // Visa Navy
      case CardBrands.masterCard:
        return const Color(0xFFEB001B); // Mastercard Red
      case CardBrands.americanExpress:
        return const Color(0xFF006FCF); // Amex Blue
      case CardBrands.discover:
        return const Color(0xFFFF6600); // Discover Orange
      case CardBrands.jcb:
        return const Color(0xFF00447C); // JCB Blue
      case CardBrands.dinersClub:
        return const Color(0xFF0079BE); // Diners Club Blue
      case CardBrands.unionPay:
        return const Color(0xFF007B86); // UnionPay Teal
      default:
        return const Color(0xFF6C63FF); // Modern Purple
    }
  }

  /// Returns card brand icon
  static IconData getBrandIcon(String cardType) {
    switch (cardType) {
      case CardBrands.visa:
        return Icons.credit_card;
      case CardBrands.masterCard:
        return Icons.credit_score;
      case CardBrands.americanExpress:
        return Icons.verified;
      case CardBrands.discover:
        return Icons.stars;
      case CardBrands.jcb:
        return Icons.card_membership;
      case CardBrands.dinersClub:
        return Icons.restaurant;
      case CardBrands.unionPay:
        return Icons.payments;
      default:
        return Icons.payment;
    }
  }

  /// Comprehensive list of world countries with ISO codes & flags
  static const List<Map<String, String>> countryList = [
    {'name': 'United States', 'code': 'US', 'flag': '🇺🇸'},
    {'name': 'United Kingdom', 'code': 'GB', 'flag': '🇬🇧'},
    {'name': 'South Africa', 'code': 'ZA', 'flag': '🇿🇦'},
    {'name': 'Canada', 'code': 'CA', 'flag': '🇨🇦'},
    {'name': 'Australia', 'code': 'AU', 'flag': '🇦🇺'},
    {'name': 'Germany', 'code': 'DE', 'flag': '🇩🇪'},
    {'name': 'France', 'code': 'FR', 'flag': '🇫🇷'},
    {'name': 'Japan', 'code': 'JP', 'flag': '🇯🇵'},
    {'name': 'China', 'code': 'CN', 'flag': '🇨🇳'},
    {'name': 'India', 'code': 'IN', 'flag': '🇮🇳'},
    {'name': 'Brazil', 'code': 'BR', 'flag': '🇧🇷'},
    {'name': 'Nigeria', 'code': 'NG', 'flag': '🇳🇬'},
    {'name': 'Kenya', 'code': 'KE', 'flag': '🇰🇪'},
    {'name': 'Russia', 'code': 'RU', 'flag': '🇷🇺'},
    {'name': 'North Korea', 'code': 'KP', 'flag': '🇰🇵'},
    {'name': 'Iran', 'code': 'IR', 'flag': '🇮🇷'},
    {'name': 'Syria', 'code': 'SY', 'flag': '🇸🇾'},
    {'name': 'Cuba', 'code': 'CU', 'flag': '🇨🇺'},
    {'name': 'Singapore', 'code': 'SG', 'flag': '🇸🇬'},
    {'name': 'United Arab Emirates', 'code': 'AE', 'flag': '🇦🇪'},
  ];
}
