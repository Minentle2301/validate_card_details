import 'package:flutter/material.dart';
import '../services/card_utils.dart';
import '../theme/app_theme.dart';

class CountryPickerWidget extends StatefulWidget {
  final String selectedCountry;
  final List<String> bannedCountryNames;
  final ValueChanged<String> onCountrySelected;

  const CountryPickerWidget({
    super.key,
    required this.selectedCountry,
    required this.bannedCountryNames,
    required this.onCountrySelected,
  });

  @override
  State<CountryPickerWidget> createState() => _CountryPickerWidgetState();
}

class _CountryPickerWidgetState extends State<CountryPickerWidget> {
  void _openSearchDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _CountrySearchSheet(
          bannedCountryNames: widget.bannedCountryNames,
          onSelected: (country) {
            widget.onCountrySelected(country);
            Navigator.pop(ctx);
          },
        );
      },
    );
  }

  bool get _isCurrentBanned {
    if (widget.selectedCountry.isEmpty) return false;
    return CardUtils.isCountryBanned(
        widget.selectedCountry, widget.bannedCountryNames);
  }

  String get _currentFlag {
    for (var c in CardUtils.countryList) {
      if (c['name']!.toLowerCase() == widget.selectedCountry.toLowerCase()) {
        return c['flag']!;
      }
    }
    return '🌐';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _openSearchDialog,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isCurrentBanned
                ? AppColors.dangerRed
                : const Color(0xFFE2E8F0),
            width: _isCurrentBanned ? 2 : 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(_currentFlag, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      widget.selectedCountry.isEmpty
                          ? 'Select Issuing Country'
                          : widget.selectedCountry,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: widget.selectedCountry.isNotEmpty
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: widget.selectedCountry.isEmpty
                            ? const Color(0xFF64748B)
                            : AppColors.primaryDark,
                      ),
                    ),
                  ),
                  if (_isCurrentBanned) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.dangerRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'BANNED',
                        style: TextStyle(
                          color: AppColors.dangerRed,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }
}

class _CountrySearchSheet extends StatefulWidget {
  final List<String> bannedCountryNames;
  final ValueChanged<String> onSelected;

  const _CountrySearchSheet({
    required this.bannedCountryNames,
    required this.onSelected,
  });

  @override
  State<_CountrySearchSheet> createState() => _CountrySearchSheetState();
}

class _CountrySearchSheetState extends State<_CountrySearchSheet> {
  String _query = '';
  final TextEditingController _customCountryCtl = TextEditingController();

  List<Map<String, String>> get _filteredList {
    if (_query.trim().isEmpty) return CardUtils.countryList;
    return CardUtils.countryList.where((c) {
      final nameMatches =
          c['name']!.toLowerCase().contains(_query.toLowerCase());
      final codeMatches =
          c['code']!.toLowerCase().contains(_query.toLowerCase());
      return nameMatches || codeMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select Issuing Country',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Search country name or code...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 320,
            child: ListView.builder(
              itemCount: _filteredList.length,
              itemBuilder: (context, index) {
                final c = _filteredList[index];
                final name = c['name']!;
                final flag = c['flag']!;
                final code = c['code']!;
                final isBanned = CardUtils.isCountryBanned(
                    name, widget.bannedCountryNames);

                return ListTile(
                  leading: Text(flag, style: const TextStyle(fontSize: 24)),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Code: $code'),
                  trailing: isBanned
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.dangerRed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Banned',
                            style: TextStyle(
                              color: AppColors.dangerRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => widget.onSelected(name),
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(bottom: 20, top: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customCountryCtl,
                    decoration: const InputDecoration(
                      hintText: 'Other country name...',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_customCountryCtl.text.trim().isNotEmpty) {
                      widget.onSelected(_customCountryCtl.text.trim());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(80, 48),
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
