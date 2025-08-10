import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/admin/presentation/admin_screen.dart';
import '../../features/tipagem/presentation/tipagem_screen.dart';
import '../../features/tipagem/presentation/tipagem_dano_screen.dart';
import '../../features/tipagem/presentation/drive_config_screen.dart';
import '../../features/drive/drive_debug_screen.dart';
import '../../shared/models/tipo_enum.dart';

class AppRouter {
  static GoRouter get router => GoRouter(
    initialLocation: AppConstants.loginRoute,
    routes: [
      GoRoute(
        path: AppConstants.loginRoute,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.homeRoute,
        builder: (context, state) => const HomeScreen(),
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
            path: 'drive',
            builder: (context, state) => const DriveConfigScreen(),
          ),
          GoRoute(
            path: 'drive-debug',
            builder: (context, state) => const DriveDebugScreen(),
          ),
          GoRoute(
            path: 'monstros',
            builder: (context, state) => const MonstrosScreenPlaceholder(),
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

// Placeholder screens (will be replaced with actual implementations)
class MonstrosScreenPlaceholder extends StatelessWidget {
  const MonstrosScreenPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Monstros - Placeholder')));
}

class RegrasScreenPlaceholder extends StatelessWidget {
  const RegrasScreenPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Regras - Placeholder')));
}
