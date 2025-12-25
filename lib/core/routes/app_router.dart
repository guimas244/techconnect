import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_screen.dart';
import '../../features/admin/presentation/config_aventura_screen.dart';
import '../../features/admin/presentation/regras_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/aventura/presentation/admin_drops_screen.dart';
import '../../features/aventura/presentation/mapa_aventura_screen.dart';
import '../../features/aventura/presentation/ranking_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/modo_selecao_screen.dart';
import '../../features/jogador/presentation/colecao_screen.dart';
import '../../features/jogador/presentation/jogador_screen.dart';
import '../../features/jogador/presentation/vantagens_screen.dart';
import '../../features/monstros/monstros_menu_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/tipagem/presentation/tipagem_dano_screen.dart';
import '../../features/tipagem/presentation/tipagem_screen.dart';
import '../../features/unlock/presentation/unlock_screen.dart';
import '../../features/explorador/presentation/explorador_home_screen.dart';
import '../../features/explorador/presentation/selecao_equipe_screen.dart';
import '../../features/explorador/presentation/selecao_mapa_screen.dart';
import '../../features/explorador/presentation/batalha_explorador_screen.dart';
import '../../features/explorador/presentation/loja_explorador_screen.dart';
import '../../features/explorador/presentation/fortuna_screen.dart';
import '../../features/aventura/presentation/kills_permanentes_screen.dart';
import '../../shared/models/tipo_enum.dart';
import '../constants/app_constants.dart';

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
        builder: (context, state) => const MapaAventuraScreen(
          mapaPath: '',
          monstrosInimigos: [],
        ),
      ),
      GoRoute(
        path: AppConstants.rankingRoute,
        builder: (context, state) => const RankingScreen(),
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
            builder: (context, state) => const RegrasScreen(),
          ),
          GoRoute(
            path: 'aventura',
            builder: (context, state) => const ConfigAventuraScreen(),
          ),
          GoRoute(
            path: 'drops',
            builder: (context, state) => const AdminDropsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/jogador',
        builder: (context, state) => const JogadorScreen(),
        routes: [
          GoRoute(
            path: 'colecao',
            builder: (context, state) => const ColecaoScreen(),
          ),
          GoRoute(
            path: 'vantagens',
            builder: (context, state) => const VantagensScreen(),
          ),
        ],
      ),
      // Novos modos de jogo
      GoRoute(
        path: AppConstants.modoSelecaoRoute,
        builder: (context, state) => const ModoSelecaoScreen(),
      ),
      GoRoute(
        path: AppConstants.unlockRoute,
        builder: (context, state) => const UnlockScreen(),
      ),
      GoRoute(
        path: AppConstants.exploradorRoute,
        builder: (context, state) => const ExploradorHomeScreen(),
      ),
      GoRoute(
        path: AppConstants.exploradorEquipeRoute,
        builder: (context, state) => const SelecaoEquipeScreen(),
      ),
      GoRoute(
        path: AppConstants.exploradorMapaRoute,
        builder: (context, state) => const SelecaoMapaScreen(),
      ),
      GoRoute(
        path: AppConstants.exploradorBatalhaRoute,
        builder: (context, state) => const BatalhaExploradorScreen(),
      ),
      GoRoute(
        path: AppConstants.exploradorLojaRoute,
        builder: (context, state) => const LojaExploradorScreen(),
      ),
      GoRoute(
        path: AppConstants.exploradorFortunaRoute,
        builder: (context, state) => const FortunaScreen(),
      ),
      GoRoute(
        path: AppConstants.killsPermanentesRoute,
        builder: (context, state) => const KillsPermanentesScreen(),
      ),
    ],
  );
}

class RegrasScreenPlaceholder extends StatelessWidget {
  const RegrasScreenPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Regras - Placeholder')));
}
