import 'package:flutter/material.dart';
import 'dart:async';
import '../../../shared/models/tipo_enum.dart';
import '../../aventura/services/colecao_service.dart';
import '../../../core/services/storage_service.dart';

class IconeColecaoNostalgica extends StatefulWidget {
  final double size;

  const IconeColecaoNostalgica({
    super.key,
    this.size = 120,
  });

  @override
  State<IconeColecaoNostalgica> createState() => _IconeColecaoNostalgicaState();
}

class _IconeColecaoNostalgicaState extends State<IconeColecaoNostalgica>
    with TickerProviderStateMixin {
  Timer? _timer;
  int _indiceAtual = 0;
  Map<String, bool> _colecaoJogador = {};
  bool _carregandoColecao = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Lista dos 30 monstros nostálgicos
  static const List<Tipo> _monstrosNostalgicos = [
    Tipo.agua, Tipo.alien, Tipo.desconhecido, Tipo.deus, Tipo.docrates,
    Tipo.dragao, Tipo.eletrico, Tipo.fantasma, Tipo.fera, Tipo.fogo,
    Tipo.gelo, Tipo.inseto, Tipo.luz, Tipo.magico, Tipo.marinho,
    Tipo.mistico, Tipo.normal, Tipo.nostalgico, Tipo.pedra, Tipo.planta,
    Tipo.psiquico, Tipo.subterraneo, Tipo.tecnologia, Tipo.tempo,
    Tipo.terrestre, Tipo.trevas, Tipo.venenoso, Tipo.vento, Tipo.voador, Tipo.zumbi
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _carregarColecaoJogador();
    _iniciarRotacao();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _carregarColecaoJogador() async {
    try {
      final storageService = StorageService();
      final email = await storageService.getLastEmail();

      if (email != null) {
        final colecaoService = ColecaoService();
        final colecao = await colecaoService.carregarColecaoJogador(email);

        if (mounted) {
          setState(() {
            _colecaoJogador = colecao;
            _carregandoColecao = false;
          });
        }
      }
    } catch (e) {
      print('❌ [IconeColecao] Erro ao carregar coleção: $e');
      if (mounted) {
        setState(() {
          _carregandoColecao = false;
        });
      }
    }
  }

  void _iniciarRotacao() {
    _fadeController.forward();

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _fadeController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _indiceAtual = (_indiceAtual + 1) % _monstrosNostalgicos.length;
            });
            _fadeController.forward();
          }
        });
      }
    });
  }

  bool _monstroEstaDesbloqueado(Tipo tipo) {
    return _colecaoJogador[tipo.name] == true;
  }

  String _obterCaminhoImagem(Tipo tipo) {
    // Caminho para imagens nostálgicas
    return 'assets/monstros_aventura/colecao_nostalgicos/${tipo.name}.png';
  }

  @override
  Widget build(BuildContext context) {
    if (_carregandoColecao) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade300,
        ),
        child: Center(
          child: SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade400),
            ),
          ),
        ),
      );
    }

    final tipoAtual = _monstrosNostalgicos[_indiceAtual];
    final estaDesbloqueado = _monstroEstaDesbloqueado(tipoAtual);
    final caminhoImagem = _obterCaminhoImagem(tipoAtual);

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Imagem do monstro com transição
            Positioned.fill(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ColorFiltered(
                  colorFilter: estaDesbloqueado
                      ? const ColorFilter.matrix([
                          // Filtro normal para monstros desbloqueados
                          1, 0, 0, 0, 0,
                          0, 1, 0, 0, 0,
                          0, 0, 1, 0, 0,
                          0, 0, 0, 1, 0,
                        ])
                      : const ColorFilter.matrix([
                          // Filtro preto para monstros bloqueados
                          0, 0, 0, 0, 0,
                          0, 0, 0, 0, 0,
                          0, 0, 0, 0, 0,
                          0, 0, 0, 1, 0,
                        ]),
                  child: Image.asset(
                    caminhoImagem,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback para ícone do tipo se a imagem não existir
                      return Container(
                        color: estaDesbloqueado
                            ? tipoAtual.cor.withOpacity(0.8)
                            : Colors.grey.shade400,
                        child: Center(
                          child: Image.asset(
                            tipoAtual.iconAsset,
                            width: widget.size * 0.4,
                            height: widget.size * 0.4,
                            fit: BoxFit.contain,
                            color: estaDesbloqueado ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Overlay com gradiente sutil
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.1),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}