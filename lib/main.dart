import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulsenet/services/storage_service.dart';
import 'package:pulsenet/services/distress_listener_service.dart';
import 'package:pulsenet/theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/app_lock_screen.dart';

void main() {
  runApp(
    Provider<StorageService>(
      create: (_) => StorageService(),
      child: const PulseNetApp(),
    ),
  );
}

class PulseNetApp extends StatefulWidget {
  const PulseNetApp({super.key});

  @override
  State<PulseNetApp> createState() => _PulseNetAppState();
}

class _PulseNetAppState extends State<PulseNetApp> {
  late final StorageService _storageService;
  late final DistressListenerService _distressListenerService;
  bool _isInitialized = false;
  bool _showOnboarding = true;
  bool _isLocked = false;
  Future<bool>? _isLockEnabledFuture;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    _storageService = context.read<StorageService>();
    _distressListenerService = DistressListenerService();

    // Check if onboarding has been seen
    final bool hasSeenOnboarding = await _storageService.getBool('hasSeenOnboarding');
    // Initialize the future for lock enabled check
    _isLockEnabledFuture = _storageService.getAppLockEnabled();

    if (mounted) {
      setState(() {
        _showOnboarding = !hasSeenOnboarding;
        _isInitialized = true;
      });
    }
  }

  Future<void> _onOnboardingComplete() async {
    await _storageService.setBool('hasSeenOnboarding', true);
    if (mounted) {
      setState(() {
        _showOnboarding = false;
      });
    }
  }

  Future<void> _onUnlockSuccess() async {
    if (mounted) {
      setState(() {
        _isLocked = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'PulseNet',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: Builder(
        builder: (context) {
          // Handle app lock
          if (_showOnboarding) {
            return OnboardingScreen(onComplete: _onOnboardingComplete);
          }

          // Check if app lock is enabled and we need to show lock screen
          return FutureBuilder<bool>(
            future: _isLockEnabledFuture,
            builder: (context, snapshot) {
              final bool isLockEnabled = snapshot.data ?? false;
              if (isLockEnabled && !_isLocked) {
                // We need to check if the lock is currently engaged
                // For simplicity, we'll lock on every app resume - in a real app,
                // we'd use lifecycle events to lock when app goes to background
                return AppLockScreen(
                  onUnlockSuccess: _onUnlockSuccess,
                );
              }
              return const DashboardScreen();
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _distressListenerService.dispose();
    super.dispose();
  }
}