import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/nostr_login_screen.dart';
import '../../presentation/screens/home/home_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/nostr', builder: (_, __) => const NostrLoginScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeShell()),
  ],
);
