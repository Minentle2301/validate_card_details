import 'package:flutter/material.dart';
import '../services/card_utils.dart';
import '../theme/app_theme.dart';

class CreditCardPreview extends StatelessWidget {
  final String cardNumber;
  final String cardType;
  final String cvv;
  final String issuingCountry;
  final bool isBanned;
  final bool showBack;

  const CreditCardPreview({
    super.key,
    required this.cardNumber,
    required this.cardType,
    required this.cvv,
    required this.issuingCountry,
    this.isBanned = false,
    this.showBack = false,
  });

  LinearGradient _getCardGradient() {
    switch (cardType) {
      case CardBrands.visa:
        return AppColors.visaGradient;
      case CardBrands.masterCard:
        return AppColors.masterCardGradient;
      case CardBrands.americanExpress:
        return AppColors.amexGradient;
      case CardBrands.discover:
        return const LinearGradient(
          colors: [Color(0xFFE65100), Color(0xFFF57C00)],
        );
      case CardBrands.jcb:
        return const LinearGradient(
          colors: [Color(0xFF003B70), Color(0xFF0066B2)],
        );
      case CardBrands.dinersClub:
        return const LinearGradient(
          colors: [Color(0xFF005A9C), Color(0xFF0088CC)],
        );
      case CardBrands.unionPay:
        return const LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF009688)],
        );
      default:
        return AppColors.primaryGradient;
    }
  }

  String _getCountryFlag(String countryName) {
    for (var c in CardUtils.countryList) {
      if (c['name']!.toLowerCase() == countryName.toLowerCase()) {
        return c['flag']!;
      }
    }
    return '🌐';
  }

  @override
  Widget build(BuildContext context) {
    final clean = cardNumber.replaceAll(RegExp(r'\D'), '');
    final displayNum = CardUtils.formatCardNumber(clean);
    final finalNum = displayNum.isEmpty ? '•••• •••• •••• ••••' : displayNum;

    return Container(
      width: double.infinity,
      height: 210,
      decoration: BoxDecoration(
        gradient: _getCardGradient(),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isBanned ? AppColors.dangerRed : CardUtils.getBrandColor(cardType))
                .withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle circle pattern
          Positioned(
            right: -40,
            bottom: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: 40,
            top: -50,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          if (isBanned)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.black.withValues(alpha: 0.55),
                ),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.dangerRed,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.block, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'BANNED COUNTRY CARD',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Card content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row: Brand & Flag
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            CardUtils.getBrandIcon(cardType),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          cardType.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    if (issuingCountry.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isBanned
                                ? AppColors.dangerRed
                                : Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getCountryFlag(issuingCountry),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              issuingCountry,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Middle: EMV Chip & Contactless Icon
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Container(
                              width: 32,
                              height: 1,
                              color: Colors.black12,
                            ),
                          ),
                          Center(
                            child: Container(
                              width: 1,
                              height: 24,
                              color: Colors.black12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.wifi,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 22,
                    ),
                  ],
                ),

                // Bottom: Card Number & CVV tag
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      finalNum,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'VALIDTHRU  12/28',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (cvv.isNotEmpty)
                          Text(
                            'CVV: ${showBack ? cvv : '•••'}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
