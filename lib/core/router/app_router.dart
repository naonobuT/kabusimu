import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/mission_select/mission_select_screen.dart';
import '../../presentation/screens/era_select/era_select_screen.dart';
import '../../presentation/screens/company_select/company_select_screen.dart';
import '../../presentation/screens/simulation/simulation_screen.dart';
import '../../presentation/screens/result/result_screen.dart';
import '../../presentation/screens/ranking/ranking_screen.dart';
import '../../presentation/screens/import/import_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: '/missions',
      builder: (_, __) => const MissionSelectScreen(),
    ),
    GoRoute(
      path: '/missions/:missionId/eras',
      builder: (_, state) => EraSelectScreen(
        missionId: state.pathParameters['missionId']!,
      ),
    ),
    GoRoute(
      path: '/missions/:missionId/eras/:eraId/companies',
      builder: (_, state) => CompanySelectScreen(
        missionId: state.pathParameters['missionId']!,
        eraId: state.pathParameters['eraId']!,
      ),
    ),
    GoRoute(
      path: '/simulation',
      builder: (_, state) => SimulationScreen(
        sessionId: int.tryParse(state.uri.queryParameters['session_id'] ?? '') ?? 0,
      ),
    ),
    GoRoute(
      path: '/result/:sessionId',
      builder: (_, state) => ResultScreen(
        sessionId: int.tryParse(state.pathParameters['sessionId'] ?? '') ?? 0,
      ),
    ),
    GoRoute(
      path: '/ranking',
      builder: (_, __) => const RankingScreen(),
    ),
    GoRoute(
      path: '/import',
      builder: (_, __) => const ImportScreen(),
    ),
  ],
  errorBuilder: (_, state) => Scaffold(
    body: Center(child: Text('ページが見つかりません: ${state.error}')),
  ),
);
