import 'package:flutter/material.dart';
import '../models/credit_card.dart';
import '../services/card_utils.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class CapturedCardsScreen extends StatefulWidget {
  final StorageService storageService;

  const CapturedCardsScreen({super.key, required this.storageService});

  @override
  State<CapturedCardsScreen> createState() => _CapturedCardsScreenState();
}

class _CapturedCardsScreenState extends State<CapturedCardsScreen> {
  List<CreditCardModel> _allCards = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _showOnlySession = true;
  final Set<String> _revealedCardIds = {};

  @override
  void initState() {
    super.initState();
    _loadCards();
    widget.storageService.addListener(_onStorageUpdate);
  }

  void _onStorageUpdate() {
    if (mounted) {
      _loadCards();
    }
  }

  @override
  void dispose() {
    widget.storageService.removeListener(_onStorageUpdate);
    super.dispose();
  }

  Future<void> _loadCards() async {
    final cards = await widget.storageService.loadCards();
    if (mounted) {
      setState(() {
        _allCards = cards;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCard(String id) async {
    await widget.storageService.deleteCard(id);
    await _loadCards();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Card removed from storage'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _toggleReveal(String id) {
    setState(() {
      if (_revealedCardIds.contains(id)) {
        _revealedCardIds.remove(id);
      } else {
        _revealedCardIds.add(id);
      }
    });
  }

  List<CreditCardModel> get _displayedCards {
    List<CreditCardModel> base = _allCards;

    if (_showOnlySession) {
      final sessionNumbers = widget.storageService.sessionCards
          .map((c) => c.cleanCardNumber)
          .toSet();
      base = base
          .where((c) => sessionNumbers.contains(c.cleanCardNumber))
          .toList();
    }

    if (_searchQuery.trim().isEmpty) return base;

    final q = _searchQuery.trim().toLowerCase();
    return base.where((c) {
      return c.cardNumber.contains(q) ||
          c.cardType.toLowerCase().contains(q) ||
          c.issuingCountry.toLowerCase().contains(q);
    }).toList();
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
    final sessionCount = widget.storageService.sessionCards.length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Tabs & Search
          Row(
            children: [
              Expanded(
                child: FilterChip(
                  label: Text('Session Cards ($sessionCount)'),
                  selected: _showOnlySession,
                  onSelected: (selected) =>
                      setState(() => _showOnlySession = true),
                  selectedColor: AppColors.accentIndigo.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.accentIndigo,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _showOnlySession
                        ? AppColors.accentIndigo
                        : AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilterChip(
                  label: Text('All Stored Cards (${_allCards.length})'),
                  selected: !_showOnlySession,
                  onSelected: (selected) =>
                      setState(() => _showOnlySession = false),
                  selectedColor: AppColors.accentIndigo.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.accentIndigo,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: !_showOnlySession
                        ? AppColors.accentIndigo
                        : AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Input
          TextField(
            onChanged: (q) => setState(() => _searchQuery = q),
            decoration: const InputDecoration(
              hintText: 'Search by card number, brand, or country...',
              prefixIcon: Icon(Icons.search),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // List view
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _displayedCards.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showOnlySession
                                  ? Icons.credit_card_off
                                  : Icons.folder_open,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _showOnlySession
                                  ? 'No cards captured during this session yet.'
                                  : 'No credit cards found in storage.',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadCards,
                        child: ListView.builder(
                          itemCount: _displayedCards.length,
                          itemBuilder: (context, index) {
                            final card = _displayedCards[index];
                            final isRevealed =
                                _revealedCardIds.contains(card.id);
                            final brandColor =
                                CardUtils.getBrandColor(card.cardType);
                            final isSession = widget.storageService.sessionCards
                                .any((c) =>
                                    c.cleanCardNumber == card.cleanCardNumber);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: brandColor
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Icon(
                                                CardUtils.getBrandIcon(
                                                    card.cardType),
                                                color: brandColor,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              card.cardType,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: brandColor,
                                              ),
                                            ),
                                            if (isSession) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.accentTeal
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Text(
                                                  'THIS SESSION',
                                                  style: TextStyle(
                                                    color: AppColors.accentTeal,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline,
                                              color: AppColors.dangerRed),
                                          onPressed: () =>
                                              _deleteCard(card.id),
                                          tooltip: 'Delete Card',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          isRevealed
                                              ? card.formattedNumber
                                              : card.maskedNumber,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'monospace',
                                            letterSpacing: 1.5,
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            isRevealed
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: const Color(0xFF64748B),
                                          ),
                                          onPressed: () =>
                                              _toggleReveal(card.id),
                                          tooltip: isRevealed
                                              ? 'Mask Card Number'
                                              : 'Show Full Card Number',
                                        ),
                                      ],
                                    ),
                                    const Divider(),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              _getCountryFlag(
                                                  card.issuingCountry),
                                              style: const TextStyle(
                                                  fontSize: 14),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              card.issuingCountry,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: Color(0xFF334155),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          'CVV: ${isRevealed ? card.cvv : '•••'}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
