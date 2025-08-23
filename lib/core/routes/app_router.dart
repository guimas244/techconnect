import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/admin/presentation/admin_screen.dart';
import '../../features/tipagem/presentation/tipagem_screen.dart';
import '../../features/tipagem/presentation/tipagem_dano_screen.dart';
import '../../features/monstros/monstros_menu_screen.dart';
import '../../features/aventura/presentation/aventura_screen.dart';
import '../../shared/models/tipo_enum.dart';

class AppRouter {
  static GoRouter get router => GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppConstants.loginRoute,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.homeRoute,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppConstants.aventuraRoute,
        builder: (context, state) => const AventuraScreen(),
      ),
      GoRoute(
        path: AppConstants.adminRoute,
        builder: (context, state) => const AdminScreen(),
        routes: [
          GoRoute(
            path: 'tipagem',
            builder: (context, state) => const TipagemScreen(),
            routes: [
              GoRoute(
                path: 'dano/:tipoId',
                builder: (context, state) {
                  final tipoId = state.pathParameters['tipoId']!;
                  final tipo = Tipo.values.firstWhere(
                    (t) => t.name == tipoId,
                    orElse: () => Tipo.normal,
                  );
                  return TipagemDanoScreen(tipoSelecionado: tipo);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'monstros',
            builder: (context, state) => const MonstrosMenuScreen(),
          ),
          GoRoute(
            path: 'regras',
            builder: (context, state) => const RegrasScreenPlaceholder(),
          ),
        ],
      ),
    ],
  );
}

class RegrasScreenPlaceholder extends StatelessWidget {
  const RegrasScreenPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Regras - Placeholder')));
}
