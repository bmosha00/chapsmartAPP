import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/home_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/',      builder: (ctx, state) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (ctx, state) => const LoginScreen()),
    GoRoute(path: '/home',  builder: (ctx, state) => const HomeShell()),
  ],
  errorBuilder: (ctx, state) => Scaffold(
    body: Center(child: Text('Page not found: ${state.error}', style: const TextStyle(color: Colors.white))),
  ),
);