import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'screens/video_splash_screen.dart';
import 'widgets/branded_loader.dart';
import 'services/ingredient_index_service.dart';
import 'viewmodels/home_view_model.dart';
import 'models/ingredient.dart';

import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/recent_scans_screen.dart';
import 'screens/account_screen.dart';
import 'screens/ingredient_detail_screen.dart';
import 'screens/settings_screen.dart';

import 'services/scan_starter.dart';
import 'services/scan_history_service.dart';
import 'theme/app_theme.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/google_sign_in_screen.dart';
import 'screens/welcome_after_signin_screen.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 👇 Duplicate app hatasını engellemek için try/catch
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (!e.toString().contains("duplicate-app")) {
      rethrow;
    }
  }

  runApp(const Shell());
}

class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red.shade600),
        useMaterial3: true,
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    if (_user == null) {
      FlutterNativeSplash.remove();
    }
  }

  void _handleSignedIn(User user) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => WelcomeAfterSigninScreen(
          displayName: user.displayName ?? 'Kullanıcı',
          next: const _IntroThenApp(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return GoogleSignInScreen(onSignedIn: _handleSignedIn);
    }
    return const _IntroThenApp();
  }
}

class _IntroThenApp extends StatelessWidget {
  const _IntroThenApp();

  @override
  Widget build(BuildContext context) {
    return VideoSplashScreen(next: const AppRoot());
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});
  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late HomeViewModel homeVm;
  int navIndex = 0;
  bool _historyInitCalled = false;

  @override
  void initState() {
    super.initState();
    homeVm = HomeViewModel(indexService: IngredientIndexService());
    homeVm.addListener(_onHomeVm);
  }

  void _onHomeVm() {
    if (!mounted) return;
    if (!_historyInitCalled && homeVm.all.isNotEmpty) {
      _historyInitCalled = true;
      ScanHistoryService.instance.init(homeVm.all.cast<Ingredient>());
    }
    setState(() {});
  }

  @override
  void dispose() {
    homeVm.removeListener(_onHomeVm);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Malzeme',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routes: {
        '/settings': (_) => const SettingsScreen(),
        '/detail': (ctx) {
          final arg = ModalRoute.of(ctx)!.settings.arguments;
          return IngredientDetailScreen(ingredient: arg);
        },
      },
      home: Scaffold(
        body: _body(),
        bottomNavigationBar: _BottomNav(
          index: navIndex,
          onTap: (i) => setState(() => navIndex = i),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'global_scan_fab',
          onPressed: () {
            final all = homeVm.all.cast<Ingredient>();
            ScanStarter.start(context, all);
          },
          backgroundColor: Colors.white,
          shape: const CircleBorder(
            side: BorderSide(color: Colors.red, width: 3),
          ),
          child: const Icon(Icons.camera_alt, color: Colors.red),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget _body() {
    if (homeVm.status == HomeStatus.loading) {
      return const Center(child: BrandedLoader());
    }
    if (homeVm.status == HomeStatus.error) {
      return const Center(child: Text('Veri yüklenemedi.'));
    }

    switch (navIndex) {
      case 0:
        return HomeScreen(
          allIngredients: homeVm.all.cast<Ingredient>(),
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
