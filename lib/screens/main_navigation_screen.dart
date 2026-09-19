import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'card_submission_screen.dart';
import 'captured_cards_screen.dart';
import 'banned_countries_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final StorageService _storageService = StorageService();

  void _onCardAdded() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final sessionCardCount = _storageService.sessionCards.length;

    final List<Widget> pages = [
      CardSubmissionScreen(
        storageService: _storageService,
        onCardAdded: _onCardAdded,
      ),
      CapturedCardsScreen(storageService: _storageService),
      BannedCountriesScreen(storageService: _storageService),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentIndigo.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CardVault Admin',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  _currentIndex == 0
                      ? 'Submit & Validate Cards'
                      : _currentIndex == 1
                          ? 'Captured Cards List'
                          : 'Manage Banned Countries',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (sessionCardCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(
                avatar: const Icon(Icons.check_circle,
                    size: 16, color: AppColors.accentTeal),
                label: Text(
                  '$sessionCardCount Session Cards',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                backgroundColor: AppColors.accentTeal.withValues(alpha: 0.12),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.add_card_outlined),
            selectedIcon: Icon(Icons.add_card, color: AppColors.accentIndigo),
            label: 'Submit Card',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('$sessionCardCount'),
              isLabelVisible: sessionCardCount > 0,
              child: const Icon(Icons.credit_card_outlined),
            ),
            selectedIcon: Badge(
              label: Text('$sessionCardCount'),
              isLabelVisible: sessionCardCount > 0,
              child: const Icon(Icons.credit_card,
                  color: AppColors.accentIndigo),
            ),
            label: 'Captured Cards',
          ),
          const NavigationDestination(
            icon: Icon(Icons.block_outlined),
            selectedIcon: Icon(Icons.block, color: AppColors.accentIndigo),
            label: 'Banned Countries',
          ),
        ],
      ),
    );
  }
}
