import 'package:flutter/material.dart';
import '../models/banned_country.dart';
import '../services/card_utils.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class BannedCountriesScreen extends StatefulWidget {
  final StorageService storageService;

  const BannedCountriesScreen({super.key, required this.storageService});

  @override
  State<BannedCountriesScreen> createState() => _BannedCountriesScreenState();
}

class _BannedCountriesScreenState extends State<BannedCountriesScreen> {
  List<BannedCountry> _bannedList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBannedCountries();
  }

  Future<void> _loadBannedCountries() async {
    setState(() => _isLoading = true);
    final list = await widget.storageService.loadBannedCountries();
    if (mounted) {
      setState(() {
        _bannedList = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeBannedCountry(String name) async {
    await widget.storageService.removeBannedCountry(name);
    await _loadBannedCountries();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$name" removed from banned list'),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _resetDefaults() async {
    final defaults =
        await widget.storageService.resetBannedCountriesToDefault();
    setState(() => _bannedList = defaults);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Banned countries reset to standard sanctions list'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openAddDialog() {
    final nameCtl = TextEditingController();
    final codeCtl = TextEditingController();
    final reasonCtl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Banned Country'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtl,
                decoration: const InputDecoration(
                  labelText: 'Country Name',
                  hintText: 'e.g. North Korea',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeCtl,
                decoration: const InputDecoration(
                  labelText: 'ISO Country Code (2 letters)',
                  hintText: 'e.g. KP',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtl,
                decoration: const InputDecoration(
                  labelText: 'Ban Reason (Optional)',
                  hintText: 'e.g. Compliance Policy',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtl.text.trim();
                final code = codeCtl.text.trim().toUpperCase();
                if (name.isEmpty) return;

                final country = BannedCountry(
                  name: name,
                  code: code.isEmpty ? 'XX' : code,
                  reason: reasonCtl.text.trim().isEmpty
                      ? 'Admin Restriction'
                      : reasonCtl.text.trim(),
                );

                final nav = Navigator.of(ctx);
                final added =
                    await widget.storageService.addBannedCountry(country);
                if (nav.mounted) {
                  nav.pop();
                }

                if (added) {
                  await _loadBannedCountries();
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"$name" is already banned'),
                        backgroundColor: AppColors.warningOrange,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(100, 44)),
              child: const Text('Add Ban'),
            ),
          ],
        );
      },
    );
  }

  List<BannedCountry> get _filteredList {
    if (_searchQuery.trim().isEmpty) return _bannedList;
    final q = _searchQuery.trim().toLowerCase();
    return _bannedList.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.code.toLowerCase().contains(q) ||
          (c.reason ?? '').toLowerCase().contains(q);
    }).toList();
  }

  String _getCountryFlag(String countryName) {
    for (var c in CardUtils.countryList) {
      if (c['name']!.toLowerCase() == countryName.toLowerCase()) {
        return c['flag']!;
      }
    }
    return '🚫';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Banned Countries',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  Text(
                    '${_bannedList.length} countries restricted',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _resetDefaults,
                    tooltip: 'Reset Default Sanctions List',
                  ),
                  ElevatedButton.icon(
                    onPressed: _openAddDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Ban Country'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dangerRed,
                      minimumSize: const Size(120, 44),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: const InputDecoration(
              hintText: 'Search banned countries or reasons...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredList.isEmpty
                    ? const Center(
                        child: Text(
                          'No banned countries match search query.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredList.length,
                        itemBuilder: (context, index) {
                          final item = _filteredList[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Text(
                                _getCountryFlag(item.name),
                                style: const TextStyle(fontSize: 28),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.code,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                item.reason ?? 'Custom Ban Rule',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: AppColors.dangerRed),
                                onPressed: () =>
                                    _removeBannedCountry(item.name),
                                tooltip: 'Remove from banned list',
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
