import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/aventura_provider.dart';
import '../models/historia_jogador.dart';
import '../../../shared/models/tipo_enum.dart';
import '../models/monstro_aventura.dart';
import 'package:remixicon/remixicon.dart';
import 'mapa_aventura_screen.dart';
import '../../../features/auth/providers/auth_provider.dart';

class AventuraScreen extends ConsumerStatefulWidget {
  const AventuraScreen({super.key});

  @override
  ConsumerState<AventuraScreen> createState() => _AventuraScreenState();
}

class _AventuraScreenState extends ConsumerState<AventuraScreen> {
  // Mantém apenas uma definição do método _buildTipoIcon
  Widget _buildTipoIcon(Tipo tipo) {
    return Image.asset(
      tipo.iconAsset,
      width: 32,
      height: 32,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback para ícone material se asset não existir
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: tipo.cor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            tipo.icone,
            color: tipo.cor,
            size: 20,
          ),
        );
      },
    );
  }
  late String emailJogador;
  HistoriaJogador? historiaAtual;

  @override
  void initState() {
    super.initState();
    // Move a verificação para depois que o widget foi construído
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Recupera o email do usuário autenticado
      final user = ref.read(currentUserProvider);
      emailJogador = user?.email ?? '';
      _verificarEstadoJogador();
    });
  }

  Future<void> _verificarEstadoJogador() async {
    print('🎮 [AventuraScreen] Iniciando verificação do jogador: $emailJogador');
    ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.carregando;
    
    try {
      final repository = ref.read(aventuraRepositoryProvider);
      print('🎮 [AventuraScreen] Repository obtido, verificando histórico...');
      
      final temHistorico = await repository.jogadorTemHistorico(emailJogador);
      print('🎮 [AventuraScreen] Tem histórico: $temHistorico');
      
      if (temHistorico) {
        print('🎮 [AventuraScreen] Carregando histórico existente...');
        final historia = await repository.carregarHistoricoJogador(emailJogador);
        print('🎮 [AventuraScreen] História carregada: ${historia != null}');
        
        if (historia != null) {
          setState(() {
            historiaAtual = historia;
          });
          ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.podeIniciar;
          print('✅ [AventuraScreen] Estado: PODE INICIAR');
        } else {
          ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.erro;
          print('❌ [AventuraScreen] Estado: ERRO (história nula)');
        }
      } else {
        ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.semHistorico;
        print('📝 [AventuraScreen] Estado: SEM HISTÓRICO');
      }
    } catch (e) {
      print('❌ [AventuraScreen] Erro na verificação: $e');
      ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.erro;
    }
  }

  Future<void> _sortearMonstros() async {
    print('🎲 [AventuraScreen] Iniciando sorteio de monstros...');
    ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.carregando;
    
    try {
      final repository = ref.read(aventuraRepositoryProvider);
      print('🎲 [AventuraScreen] Sorteando monstros...');
      final historia = await repository.sortearMonstrosParaJogador(emailJogador);
      
      print('🎲 [AventuraScreen] Monstros sorteados, atualizando estado...');
      setState(() {
        historiaAtual = historia;
      });
      ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.podeIniciar;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Monstros sorteados e salvos com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      print('✅ [AventuraScreen] Sorteio concluído com sucesso');
    } catch (e) {
      print('❌ [AventuraScreen] Erro no sorteio: $e');
      ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.erro;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao sortear monstros: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _iniciarAventura() async {
    print('🚀 [AventuraScreen] Iniciando aventura...');
    ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.carregando;
    
    try {
      final repository = ref.read(aventuraRepositoryProvider);
      print('🚀 [AventuraScreen] Chamando iniciarAventura no repository...');
      
      final historiaAtualizada = await repository.iniciarAventura(emailJogador);
      
      if (historiaAtualizada != null) {
        print('🚀 [AventuraScreen] Aventura iniciada com sucesso!');
        setState(() {
          historiaAtual = historiaAtualizada;
        });
        
        // Navegar para o mapa de aventura
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapaAventuraScreen(
              mapaPath: historiaAtualizada.mapaAventura!,
              monstrosInimigos: historiaAtualizada.monstrosInimigos,
            ),
          ),
        );
        
        ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.podeIniciar;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aventura iniciada! Boa sorte na jornada!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Falha ao iniciar aventura');
      }
    } catch (e) {
      print('❌ [AventuraScreen] Erro ao iniciar aventura: $e');
      ref.read(aventuraEstadoProvider.notifier).state = AventuraEstado.erro;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao iniciar aventura: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(aventuraEstadoProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('Aventura'),
        centerTitle: true,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home');
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background/templo.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Título
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Bem-vindo à Aventura TechConnect!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Conteúdo baseado no estado
                Expanded(
                  child: _buildConteudoPorEstado(estado),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConteudoPorEstado(AventuraEstado estado) {
    switch (estado) {
      case AventuraEstado.carregando:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              SizedBox(height: 16),
              Text(
                'Carregando...',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Conectando com Google Drive',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        );

      case AventuraEstado.semHistorico:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.casino,
                      size: 64,
                      color: Colors.orange,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Primeira Aventura!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Você ainda não possui monstros.\nSorteie 3 monstros para começar!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _sortearMonstros,
                icon: const Icon(Icons.casino),
                label: const Text('SORTEAR MONSTROS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );

      case AventuraEstado.temHistorico:
      case AventuraEstado.podeIniciar:
        return _buildTelaComMonstros();

      case AventuraEstado.aventuraIniciada:
        return _buildTelaComMonstros();

      case AventuraEstado.erro:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.error,
                      size: 64,
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Erro',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Ocorreu um erro ao carregar.\nVerifique sua conexão e tente novamente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _verificarEstadoJogador,
                icon: const Icon(Icons.refresh),
                label: const Text('TENTAR NOVAMENTE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildTelaComMonstros() {
    if (historiaAtual == null) {
      return const Center(child: Text('Erro: Histórico não carregado'));
    }

    return Column(
      children: [
        const SizedBox(height: 10),
        // Cards dos monstros em linha, responsivo
        Row(
          children: historiaAtual!.monstros.map<Widget>((monstro) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: _buildCardMonstroBonito(monstro),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 30),
        // Botão Iniciar
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              _iniciarAventura();
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('INICIAR AVENTURA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardMonstroBonito(dynamic monstro) {
    return InkWell(
      onTap: () => _mostrarModalMonstro(monstro),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(10),
        height: 210,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [monstro.tipo.cor.withOpacity(0.7), Colors.white.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: monstro.tipo.cor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: monstro.tipo.cor, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: monstro.tipo.cor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: monstro.tipo.cor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  monstro.imagem,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: monstro.tipo.cor.withOpacity(0.3),
                      child: Icon(
                        Icons.pets,
                        color: monstro.tipo.cor,
                        size: 30,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Ícones dos tipos (usando asset igual tela de tipagem)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTipoIcon(monstro.tipo),
                const SizedBox(width: 12),
                _buildTipoIcon(monstro.tipoExtra),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Vida
                Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Remix.heart_pulse_fill, color: Colors.red, size: 22),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${monstro.vida}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(width: 18),
                // Energia
                Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Remix.battery_charge_fill, color: Colors.blue, size: 22),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${monstro.energia}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarModalMonstro(MonstroAventura monstro) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [monstro.tipo.cor.withOpacity(0.8), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabeçalho com imagem e tipos
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: monstro.tipo.cor, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: monstro.tipo.cor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          monstro.imagem,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: monstro.tipo.cor.withOpacity(0.3),
                              child: Icon(
                                Icons.pets,
                                color: monstro.tipo.cor,
                                size: 40,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            monstro.tipo.displayName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: monstro.tipo.cor,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildTipoIcon(monstro.tipo),
                              const SizedBox(width: 8),
                              _buildTipoIcon(monstro.tipoExtra),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Atributos
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Atributos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: monstro.tipo.cor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildAtributoInfo('Vida', monstro.vida, Remix.heart_pulse_fill, Colors.red),
                          _buildAtributoInfo('Energia', monstro.energia, Remix.battery_charge_fill, Colors.blue),
                          _buildAtributoInfo('Agilidade', monstro.agilidade, Remix.run_fill, Colors.green),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildAtributoInfo('Ataque', monstro.ataque, Remix.boxing_fill, Colors.orange),
                          _buildAtributoInfo('Defesa', monstro.defesa, Remix.shield_cross_fill, Colors.purple),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Botão fechar
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: monstro.tipo.cor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Fechar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAtributoInfo(String nome, int valor, IconData icone, Color cor) {
    return Column(
      children: [
        Icon(icone, color: cor, size: 24),
        const SizedBox(height: 4),
        Text(
          nome,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$valor',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
      ],
    );
  }
}
