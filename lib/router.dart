import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/welcome/welcome_screen.dart';
import 'features/home/home_screen.dart';
import 'features/add_habit/add_habit_screen.dart';
import 'features/stats/stats_screen.dart';
import 'features/settings/settings_screen.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/welcome',
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/add',
        builder: (context, state) => const AddHabitScreen(),
      ),
      GoRoute(
        path: '/stats',
        builder: (context, state) => const StatsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}