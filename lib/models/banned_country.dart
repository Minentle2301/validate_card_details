import 'dart:convert';

class BannedCountry {
  final String name;
  final String code; // ISO-2 country code
  final String? reason;
  final bool isDefault;

  BannedCountry({
    required this.name,
    required this.code,
    this.reason,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        'reason': reason,
        'isDefault': isDefault,
      };

  factory BannedCountry.fromJson(Map<String, dynamic> json) => BannedCountry(
        name: json['name'] as String,
        code: json['code'] as String,
        reason: json['reason'] as String?,
        isDefault: json['isDefault'] as bool? ?? false,
      );

  static List<BannedCountry> getDefaultSanctionedList() {
    return [
      BannedCountry(
        name: 'North Korea',
        code: 'KP',
        reason: 'UN & OFAC Sanctions',
        isDefault: true,
      ),
      BannedCountry(
        name: 'Iran',
        code: 'IR',
        reason: 'High Financial Risk / Sanctions',
        isDefault: true,
      ),
      BannedCountry(
        name: 'Syria',
        code: 'SY',
        reason: 'Trade Restrictions',
        isDefault: true,
      ),
      BannedCountry(
        name: 'Cuba',
        code: 'CU',
        reason: 'OFAC Sanctions List',
        isDefault: true,
      ),
      BannedCountry(
        name: 'Russia',
        code: 'RU',
        reason: 'SWIFT & Banking Restrictions',
        isDefault: true,
      ),
    ];
  }

  static List<BannedCountry> listFromJsonString(String jsonString) {
    if (jsonString.trim().isEmpty) return [];
    final List<dynamic> decoded = json.decode(jsonString);
    return decoded
        .map((e) => BannedCountry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJsonString(List<BannedCountry> list) {
    final mapped = list.map((e) => e.toJson()).toList();
    return json.encode(mapped);
  }
}
