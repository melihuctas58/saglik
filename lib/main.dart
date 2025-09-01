import 'package:flutter/material.dart';

import 'services/ingredient_index_service.dart'; // GERÇEK servis
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
import 'screens/settings_screen.dart';

import 'models/ingredient.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppRoot());
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});
  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late HomeViewModel homeVm;
  SimpleIngredientMatcher? matcher;
  int navIndex = 0;

  @override
  void initState() {
    super.initState();
    homeVm = HomeViewModel(indexService: IngredientIndexService());
    homeVm.addListener(_maybeBuildMatcher);
  }

  void _maybeBuildMatcher() {
    if (homeVm.status == HomeStatus.ready &&
        matcher == null &&
        homeVm.all.isNotEmpty) {
      matcher = SimpleIngredientMatcher(
          homeVm.all.cast<Ingredient>()); // type cast gerekli
      setState(() {});
    }
  }

  void _openDetail(dynamic ingredient) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IngredientDetailScreen(ingredient: ingredient),
      ),
    );
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
          PopularityService.instance.bumpMany(
            ings,
            keyFn: (x) => (x.core?.primaryName ?? '').toString().toLowerCase(),
          );
            ScanHistoryService.instance.add(ings, imagePath: path);
          setState(() {});
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Malzeme',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red.shade600),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: _body(),
        bottomNavigationBar: _BottomNav(
          index: navIndex,
          onTap: (i) => setState(() => navIndex = i),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openScan,
          backgroundColor: Colors.red.shade600,
          child: const Icon(Icons.camera_alt),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
      routes: {
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }

  Widget _body() {
    if (homeVm.status == HomeStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (homeVm.status == HomeStatus.error) {
      return const Center(child: Text('Veri yüklenemedi.'));
    }

    switch (navIndex) {
      case 0:
        return HomeScreen(
          allIngredients: homeVm.all,
          onOpenDetail: _openDetail,
          onOpenSettings: () => Navigator.pushNamed(context, '/settings'),
          onTapScan: _openScan,
        );
      case 1:
        return RecentScansScreen(onOpenIngredient: _openDetail);
      case 2:
        return AccountScreen(
          allIngredients: homeVm.all,
          onOpenIngredient: _openDetail,
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
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onTap,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Ana'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Taramalar'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Hesap'),
        ],
      ),
    );
  }
}