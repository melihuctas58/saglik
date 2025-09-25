import 'package:flutter/material.dart';

import 'services/ingredient_index_service.dart';
import 'services/popularity_service.dart';
import 'services/scan_history_service.dart';
import 'services/simple_ingredient_matcher.dart';

import 'viewmodels/home_view_model.dart';
import 'viewmodels/scan_view_model.dart';

import 'screens/home_screen.dart';
import 'screens/recent_scans_screen.dart';
import 'screens/account_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/ingredient_detail_screen.dart';
import 'screens/search_screen.dart';

import 'models/ingredient.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late HomeViewModel homeVm;
  SimpleIngredientMatcher? matcher;
  int navIndex = 0; // 0=Ana, 1=Arama, 2=Taramalar, 3=Hesap

  @override
  void initState() {
    super.initState();
    homeVm = HomeViewModel(indexService: IngredientIndexService());
    homeVm.addListener(_maybeBuildMatcher);
  }

  @override
  void dispose() {
    homeVm.removeListener(_maybeBuildMatcher);
    super.dispose();
  }

  void _maybeBuildMatcher() {
    if (homeVm.status == HomeStatus.ready &&
        matcher == null &&
        homeVm.all.isNotEmpty) {
      matcher = SimpleIngredientMatcher(homeVm.all.cast<Ingredient>());
      if (mounted) setState(() {});
    }
  }

  void _openScan() {
    if (matcher == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veri hazırlanıyor...')),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ScanScreen(
        vm: ScanViewModel(),
        matcher: matcher!,
        onResult: (ings, path) {
          final list = ings.cast<Ingredient>();
          // Popülerlik ve geçmiş
          PopularityService.instance.bumpMany(
            list,
            keyFn: (x) => x.core.primaryName.toLowerCase(),
          );
          ScanHistoryService.instance.add(list, imagePath: path);
          if (mounted) setState(() {});
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final Widget? fab = (navIndex == 0)
        ? FloatingActionButton(
            heroTag: 'home_scan_fab',
            onPressed: _openScan,
            backgroundColor: Colors.white,
            shape: const CircleBorder(
              side: BorderSide(color: Colors.red, width: 3),
            ),
            child: const Icon(Icons.camera_alt, color: Colors.red),
          )
        : null;

    if (homeVm.status == HomeStatus.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 3)),
      );
    }
    if (homeVm.status == HomeStatus.error) {
      return const Scaffold(
        body: Center(child: Text('Veri yüklenemedi.')),
      );
    }

    return Scaffold(
      body: _body(),
      bottomNavigationBar: _BottomNav(
        index: navIndex,
        onTap: (i) => setState(() => navIndex = i),
      ),
      floatingActionButton: fab,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _body() {
    switch (navIndex) {
      case 0:
        return HomeScreen(
          allIngredients: homeVm.all.cast<Ingredient>(),
          // Sağ üst ayarlar kaldırılmıştı; onOpenSettings kullanılmıyor.
        );
      case 1:
        return SearchScreen(allIngredients: homeVm.all.cast<Ingredient>());
      case 2:
        return RecentScansScreen(onOpenIngredient: (ing) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => IngredientDetailScreen(ingredient: ing),
          ));
        });
      case 3:
        return AccountScreen(
          allIngredients: homeVm.all.cast<Ingredient>(),
          onOpenIngredient: (ing) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => IngredientDetailScreen(ingredient: ing),
            ));
          },
          // Eğer bu ekranda sekmeler arası yönlendirme gerekiyorsa
          onGoToScans: () => setState(() => navIndex = 2),
          onGoToSearch: () => setState(() => navIndex = 1),
        );
    }
    return const SizedBox();
  }
}

class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Theme.of(context).colorScheme.surface,
      elevation: 8,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onTap,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Ana'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Arama'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Taramalar'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Hesap'),
        ],
      ),
    );
  }
}