import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'core/constants/app_colors.dart';
import 'core/database/trip_local_db.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/explore/destination_provider.dart';
import 'features/explore/explore_screen.dart';
import 'features/home/home_screen.dart';
import 'features/map/map_provider.dart';
import 'features/notification/notification_provider.dart';
import 'features/profile/profile_screen.dart';
import 'features/trip/my_trip_screen.dart';
import 'features/trip/trip_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inisialisasi Database Zona Waktu untuk Scheduled Notification (Modul 7)
  tz.initializeTimeZones();

  // Inisialisasi Service Notifikasi Lokal HP (Modul 7)
  await NotificationService().init();

  // Inisialisasi Local Database Hive untuk CRUD Trip (Modul 6)
  await TripLocalDb.init();

  runApp(const MeraTripApp());
}

class MeraTripApp extends StatelessWidget {
  final AuthProvider? authProvider;
  final DestinationProvider? destinationProvider;
  final TripProvider? tripProvider;
  final MapProvider? mapProvider;
  final NotificationProvider? notificationProvider;

  const MeraTripApp({
    super.key,
    this.authProvider,
    this.destinationProvider,
    this.tripProvider,
    this.mapProvider,
    this.notificationProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        if (authProvider != null)
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider!)
        else
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()..init()),
        if (destinationProvider != null)
          ChangeNotifierProvider<DestinationProvider>.value(value: destinationProvider!)
        else
          ChangeNotifierProvider<DestinationProvider>(
            create: (_) => DestinationProvider()..loadDestinations(),
          ),
        if (tripProvider != null)
          ChangeNotifierProvider<TripProvider>.value(value: tripProvider!)
        else
          ChangeNotifierProvider<TripProvider>(
            create: (_) => TripProvider()..loadTrips(),
          ),
        if (mapProvider != null)
          ChangeNotifierProvider<MapProvider>.value(value: mapProvider!)
        else
          ChangeNotifierProvider<MapProvider>(create: (_) => MapProvider()),
        if (notificationProvider != null)
          ChangeNotifierProvider<NotificationProvider>.value(value: notificationProvider!)
        else
          ChangeNotifierProvider<NotificationProvider>(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'MeraTrip',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    );
  }
}

/// Gerbang Autentikasi Aplikasi (Modul 4: Navigation)
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // 1. Splash Loading State saat memeriksa sesi SharedPreferences
    if (!auth.isInitialized) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'lib/img/logo.png',
                  width: 80,
                  height: 80,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.landscape_rounded,
                    size: 80,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: AppColors.primary),
            ],
          ),
        ),
      );
    }

    // 2. Jika belum login, buka LoginScreen (Modul 4: Navigator)
    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    // 3. Jika sudah login, buka Shell 4 Tab Utama
    return const MeraTripShellScreen();
  }
}

/// Shell Utama Aplikasi dengan BottomNavigationBar 4 Tab (Modul 4)
class MeraTripShellScreen extends StatefulWidget {
  const MeraTripShellScreen({super.key});

  @override
  State<MeraTripShellScreen> createState() => _MeraTripShellScreenState();
}

class _MeraTripShellScreenState extends State<MeraTripShellScreen> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTabIndex.clamp(0, 3),
        children: [
          HomeScreen(
            onNavigateTab: (idx) {
              setState(() {
                _currentTabIndex = idx;
              });
            },
          ),
          const ExploreScreen(),
          const MyTripScreen(),
          ProfileScreen(
            onNavigateTab: (idx) {
              setState(() {
                _currentTabIndex = idx;
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.luggage_outlined),
            activeIcon: Icon(Icons.luggage_rounded),
            label: 'My Trip',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
