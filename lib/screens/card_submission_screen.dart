import 'package:flutter/material.dart';
import '../models/credit_card.dart';
import '../models/banned_country.dart';
import '../services/card_utils.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/credit_card_preview.dart';
import '../widgets/country_picker.dart';
import 'scanner_screen.dart';

class CardSubmissionScreen extends StatefulWidget {
  final StorageService storageService;
  final VoidCallback onCardAdded;

  const CardSubmissionScreen({
    super.key,
    required this.storageService,
    required this.onCardAdded,
  });

  @override
  State<CardSubmissionScreen> createState() => _CardSubmissionScreenState();
}

class _CardSubmissionScreenState extends State<CardSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _numberCtl = TextEditingController();
  final TextEditingController _cvvCtl = TextEditingController();

  String _inferredType = CardBrands.unknown;
  String _selectedCountry = '';
  List<BannedCountry> _bannedCountries = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadBannedCountries();
    _numberCtl.addListener(_onNumberChanged);
  }

  Future<void> _loadBannedCountries() async {
    final list = await widget.storageService.loadBannedCountries();
    if (mounted) {
      setState(() => _bannedCountries = list);
    }
  }

  void _onNumberChanged() {
    final inferred = CardUtils.inferCardType(_numberCtl.text);
    if (inferred != _inferredType) {
      setState(() => _inferredType = inferred);
    }
  }

  bool get _isCountryBanned {
    if (_selectedCountry.isEmpty) return false;
    final bannedNames = _bannedCountries.map((e) => e.name).toList();
    return CardUtils.isCountryBanned(_selectedCountry, bannedNames);
  }

  Future<void> _scanCard() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );

    if (result != null && result.isNotEmpty) {
      if (result['cardNumber'] != null) {
        _numberCtl.text = result['cardNumber']!;
      }
      if (result['cvv'] != null) {
        _cvvCtl.text = result['cvv']!;
      }
      if (result['issuingCountry'] != null) {
        setState(() => _selectedCountry = result['issuingCountry']!);
      }
      _showSnack('Card details scanned successfully!', AppColors.successGreen);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCountry.isEmpty) {
      _showSnack('Please select an issuing country', AppColors.warningOrange);
      return;
    }

    final cleanNumber = _numberCtl.text.replaceAll(RegExp(r'\D'), '');
    final cvv = _cvvCtl.text.trim();
    final country = _selectedCountry.trim();
    final cardType = CardUtils.inferCardType(cleanNumber);

    // 1. Check Banned Country
    final bannedNames = _bannedCountries.map((e) => e.name).toList();
    if (CardUtils.isCountryBanned(country, bannedNames)) {
      _showSnack(
        'Submission blocked: "$country" is in the banned countries list!',
        AppColors.dangerRed,
      );
      return;
    }

    // 2. Check Luhn Algorithm Validation
    if (!CardUtils.luhnCheck(cleanNumber)) {
      _showSnack(
        'Validation failed: Invalid card checksum (Luhn check).',
        AppColors.dangerRed,
      );
      return;
    }

    // 3. Check CVV Length
    if (!CardUtils.validateCVV(cvv, cardType)) {
      _showSnack(
        'Invalid CVV length for $cardType card.',
        AppColors.dangerRed,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final card = CreditCardModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cardNumber: cleanNumber,
      cardType: cardType,
      cvv: cvv,
      issuingCountry: country,
      createdAt: DateTime.now(),
    );

    // 4. Save to Local Storage & Check Duplicate
    final added = await widget.storageService.addCardIfNotDuplicate(card);
    setState(() => _isSubmitting = false);

    if (!added) {
      _showSnack(
        'Duplicate card: This credit card has already been captured!',
        AppColors.warningOrange,
      );
      return;
    }

    // Success reset
    _numberCtl.clear();
    _cvvCtl.clear();
    setState(() {
      _selectedCountry = '';
      _inferredType = CardBrands.unknown;
    });

    widget.onCardAdded();
    _showSnack('Credit card validated & saved securely!', AppColors.successGreen);
  }

  void _showSnack(String message, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  void dispose() {
    _numberCtl.removeListener(_onNumberChanged);
    _numberCtl.dispose();
    _cvvCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannedNames = _bannedCountries.map((e) => e.name).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dynamic Credit Card Preview Widget
          CreditCardPreview(
            cardNumber: _numberCtl.text,
            cardType: _inferredType,
            cvv: _cvvCtl.text,
            issuingCountry: _selectedCountry,
            isBanned: _isCountryBanned,
          ),
          const SizedBox(height: 24),

          // Form Card Container
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Card Submission',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _scanCard,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scan Card'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card Number Field
                    TextFormField(
                      controller: _numberCtl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Credit Card Number',
                        hintText: '4532 0000 0000 0000',
                        prefixIcon: const Icon(Icons.credit_card),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.camera_alt_outlined),
                          onPressed: _scanCard,
                          tooltip: 'Scan Card',
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter credit card number';
                        }
                        final clean = v.replaceAll(RegExp(r'\D'), '');
                        if (clean.length < 12) return 'Card number too short';
                        if (!CardUtils.luhnCheck(clean)) {
                          return 'Invalid card number (Luhn checksum failed)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Inferred Brand Chip
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: CardUtils.getBrandColor(_inferredType)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: CardUtils.getBrandColor(_inferredType)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CardUtils.getBrandIcon(_inferredType),
                                size: 16,
                                color: CardUtils.getBrandColor(_inferredType),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Detected Brand: $_inferredType',
                                style: TextStyle(
                                  color: CardUtils.getBrandColor(_inferredType),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // CVV & Issuing Country Selector
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _cvvCtl,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'CVV',
                              hintText: '123',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'CVV required';
                              if (!CardUtils.validateCVV(v, _inferredType)) {
                                return 'Invalid CVV';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: CountryPickerWidget(
                            selectedCountry: _selectedCountry,
                            bannedCountryNames: bannedNames,
                            onCountrySelected: (country) {
                              setState(() => _selectedCountry = country);
                            },
                          ),
                        ),
                      ],
                    ),

                    if (_isCountryBanned) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.dangerRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.dangerRed),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: AppColors.dangerRed),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '"$_selectedCountry" is in the banned countries list. Submissions will be blocked.',
                                style: const TextStyle(
                                  color: AppColors.dangerRed,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      child: _isSubmitting
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                ),
                                SizedBox(width: 12),
                                Text('Validating & Storing...'),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shield),
                                SizedBox(width: 8),
                                Text('Validate & Submit Card'),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
