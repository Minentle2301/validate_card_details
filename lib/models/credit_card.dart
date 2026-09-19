import 'dart:convert';

/// Represents a credit card entity captured in the application.
class CreditCardModel {
  final String id;
  final String cardNumber; // Digits only
  final String cardType; // e.g. Visa, MasterCard, American Express
  final String cvv;
  final String issuingCountry;
  final DateTime createdAt;

  CreditCardModel({
    required this.id,
    required this.cardNumber,
    required this.cardType,
    required this.cvv,
    required this.issuingCountry,
    required this.createdAt,
  });

  /// Digits only version of card number
  String get cleanCardNumber => cardNumber.replaceAll(RegExp(r'\D'), '');

  /// Returns the last 4 digits of the card number
  String get last4Digits {
    final clean = cleanCardNumber;
    return clean.length >= 4 ? clean.substring(clean.length - 4) : clean;
  }

  /// Formats raw card number with spaces (e.g. 4532 1234 5678 9010)
  String get formattedNumber {
    final clean = cleanCardNumber;
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }

  /// Returns masked card number (e.g. •••• •••• •••• 9010)
  String get maskedNumber {
    final clean = cleanCardNumber;
    if (clean.length <= 4) return clean;
    final last4 = clean.substring(clean.length - 4);
    final maskedLength = clean.length - 4;
    final maskedBlocks = (maskedLength / 4).ceil();

    final buffer = StringBuffer();
    for (int i = 0; i < maskedBlocks; i++) {
      buffer.write('•••• ');
    }
    buffer.write(last4);
    return buffer.toString();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cardNumber': cardNumber,
        'cardType': cardType,
        'cvv': cvv,
        'issuingCountry': issuingCountry,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CreditCardModel.fromJson(Map<String, dynamic> json) {
    return CreditCardModel(
      id: json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      cardNumber: json['cardNumber'] as String,
      cardType: json['cardType'] as String,
      cvv: json['cvv'] as String,
      issuingCountry: json['issuingCountry'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static List<CreditCardModel> listFromJsonString(String jsonString) {
    if (jsonString.trim().isEmpty) return [];
    final List<dynamic> decoded = json.decode(jsonString);
    return decoded
        .map((e) => CreditCardModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJsonString(List<CreditCardModel> list) {
    final mapped = list.map((e) => e.toJson()).toList();
    return json.encode(mapped);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreditCardModel &&
          runtimeType == other.runtimeType &&
          cleanCardNumber == other.cleanCardNumber;

  @override
  int get hashCode => cleanCardNumber.hashCode;
}
