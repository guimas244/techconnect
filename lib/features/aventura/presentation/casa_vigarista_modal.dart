import 'package:flutter/material.dart';
import 'dart:math';
import '../models/historia_jogador.dart';
import '../models/item.dart';
import '../models/habilidade.dart';
import '../../../shared/models/tipo_enum.dart';
import '../../../shared/models/habilidade_enum.dart';
import '../services/item_service.dart';
import '../utils/gerador_habilidades.dart';
import 'modal_item_obtido.dart';
import 'modal_magia_obtida.dart';
import 'modal_cura_obtida.dart';
import '../models/magia_drop.dart';

class CasaVigaristaModal extends StatefulWidget {
  final HistoriaJogador historia;
  final Function(HistoriaJogador historiaAtualizada) onHistoriaAtualizada;

  const CasaVigaristaModal({
    super.key,
    required this.historia,
    required this.onHistoriaAtualizada,
  });

  @override
  State<CasaVigaristaModal> createState() => _CasaVigaristaModalState();
}

class _CasaVigaristaModalState extends State<CasaVigaristaModal> {
  final ItemService _itemService = ItemService();
  int get custoAposta => 2 * widget.historia.tier;
  bool _comprando = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          // Fundo temporário - será substituído por imagem
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade900.withOpacity(0.95),
              Colors.black.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.purple.shade300, width: 2),
        ),
        child: Column(
          children: [
            // Header da loja
            _buildHeader(),
            
            // Vendedor (monstro inseto)
            _buildVendedor(),
            
            // Opções de aposta
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Escolha sua aposta:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Item Aleatório
                    Expanded(
                      child: _buildOpcaoAposta(
                        'Item Aleatório',
                        'Sortear',
                        Icons.diamond,
                        Colors.blue,
                        () => _mostrarConfirmacao('Item', _apostarItem),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Magia Aleatória
                    Expanded(
                      child: _buildOpcaoAposta(
                        'Magia Aleatória',
                        'Sortear',
                        Icons.auto_fix_high,
                        Colors.purple,
                        () => _mostrarConfirmacao('Magia', _apostarMagia),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Cura Aleatória
                    Expanded(
                      child: _buildOpcaoAposta(
                        'Cura Aleatória',
                        '1% a 100%',
                        Icons.healing,
                        Colors.green,
                        () => _mostrarConfirmacao('Cura', _apostarCura),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer com score atual
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2, color: Colors.amber, size: 32),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Casa do Vigarista',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildVendedor() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Imagem do vendedor (tipo inseto)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Tipo.inseto.cor.withOpacity(0.9),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Image.asset(
              'assets/npc/besta_Karma.png',
              width: 60,
              height: 60,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vendedor Questionável',
                  style: TextStyle(
                    color: Colors.amber.shade200,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Apostas arriscadas, recompensas incertas...',
                  style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Custo por aposta: $custoAposta pontos',
                  style: TextStyle(
                    color: Colors.red.shade300,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarConfirmacao(String tipoAposta, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Aposta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Deseja apostar $custoAposta pontos em "$tipoAposta"?',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'O score será descontado imediatamente!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOpcaoAposta(String titulo, String descricao, IconData icone, Color cor, VoidCallback onTap) {
    bool podeComprar = widget.historia.score >= custoAposta && !_comprando;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: podeComprar ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: podeComprar 
                ? cor.withOpacity(0.2) 
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: podeComprar ? cor : Colors.grey,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: podeComprar ? cor.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icone,
                  color: podeComprar ? cor : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color: podeComprar ? Colors.white : Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      descricao,
                      style: TextStyle(
                        color: podeComprar ? Colors.grey.shade300 : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: podeComprar ? cor : Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Score Atual: ${widget.historia.score}',
            style: TextStyle(
              color: Colors.amber.shade300,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Tier: ${widget.historia.tier}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _apostarItem() async {
    if (_comprando || widget.historia.score < custoAposta) return;
    
    setState(() { _comprando = true; });
    
    try {
      // Desconta o score primeiro
      final historiaAtualizada = widget.historia.copyWith(
        score: widget.historia.score - custoAposta,
      );
      
      // Salva a historia com score descontado
      widget.onHistoriaAtualizada(historiaAtualizada);
      
      // Gera item aleatório baseado no tier
      final item = _itemService.gerarItemAleatorio(tierAtual: widget.historia.tier);
      _mostrarResultadoItem(item, historiaAtualizada);
    } catch (e) {
      _mostrarErro('Erro ao processar aposta: $e');
    }
    
    setState(() { _comprando = false; });
  }

  void _apostarMagia() async {
    if (_comprando || widget.historia.score < custoAposta) return;
    
    setState(() { _comprando = true; });
    
    try {
      // Desconta o score primeiro
      final historiaAtualizada = widget.historia.copyWith(
        score: widget.historia.score - custoAposta,
      );
      
      // Salva a historia com score descontado
      widget.onHistoriaAtualizada(historiaAtualizada);
      
      // Gera habilidade aleatória
      final habilidade = _gerarHabilidadeAleatoria();
      _mostrarResultadoMagia(habilidade, historiaAtualizada);
      
    } catch (e) {
      _mostrarErro('Erro ao processar aposta: $e');
    }
    
    setState(() { _comprando = false; });
  }

  void _apostarCura() async {
    if (_comprando || widget.historia.score < custoAposta) return;
    
    setState(() { _comprando = true; });
    
    try {
      // Desconta o score primeiro
      final historiaAtualizada = widget.historia.copyWith(
        score: widget.historia.score - custoAposta,
      );
      
      // Salva a historia com score descontado
      widget.onHistoriaAtualizada(historiaAtualizada);
      
      // Gera cura aleatória (1% a 100%)
      final random = Random();
      final porcentagemCura = random.nextInt(100) + 1; // 1 a 100
      
      _mostrarResultadoCura(porcentagemCura, historiaAtualizada);
      
    } catch (e) {
      _mostrarErro('Erro ao processar aposta: $e');
    }
    
    setState(() { _comprando = false; });
  }

  Habilidade _gerarHabilidadeAleatoria() {
    final random = Random();
    final tipos = Tipo.values;
    final tipoAleatorio = tipos[random.nextInt(tipos.length)];
    
    final habilidades = GeradorHabilidades.gerarHabilidadesMonstro(tipoAleatorio, null);
    return habilidades.isNotEmpty ? habilidades.first : 
    Habilidade(
      nome: 'Habilidade Misteriosa',
      descricao: 'Uma habilidade obtida na Casa do Vigarista',
      tipo: TipoHabilidade.ofensiva,
      efeito: EfeitoHabilidade.danoDirecto,
      tipoElemental: tipoAleatorio,
      valor: 10,
      custoEnergia: 5,
      level: 1,
    );
  }

  void _mostrarResultadoItem(Item item, HistoriaJogador historia) {
    // Usa o modal existente de item obtido
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalItemObtido(
        item: item,
        monstrosDisponiveis: historia.monstros,
        onEquiparItem: (monstro, itemObtido) async {
          // Atualiza o monstro com o novo item
          final monstrosAtualizados = historia.monstros.map((m) {
            if (m.tipo == monstro.tipo && m.level == monstro.level) {
              return m.copyWith(itemEquipado: itemObtido);
            }
            return m;
          }).toList();
          
          final historiaFinal = historia.copyWith(monstros: monstrosAtualizados);
          widget.onHistoriaAtualizada(historiaFinal);
          
          // Fecha a Casa do Vigarista após equipar o item
          Navigator.of(context).pop(); // Fecha o Casa do Vigarista
          
          _mostrarMensagemSucesso('Item ${itemObtido.nome} equipado em ${monstro.tipo.displayName}!');
        },
      ),
    );
  }

  void _mostrarResultadoMagia(Habilidade habilidade, HistoriaJogador historia) {
    
    // Converte Habilidade para MagiaDrop
    final magia = MagiaDrop(
      nome: habilidade.nome,
      descricao: habilidade.descricao,
      tipo: habilidade.tipo,
      efeito: habilidade.efeito,
      valor: habilidade.valor,
      custoEnergia: habilidade.custoEnergia,
      level: habilidade.level,
      dataObtencao: DateTime.now(),
    );
    
    // Usa o modal existente de magia obtida
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalMagiaObtida(
        magia: magia,
        monstrosDisponiveis: historia.monstros,
        onEquiparMagia: (monstro, magiaObtida, habilidadeSubstituida) async {
          // Converte MagiaDrop de volta para Habilidade
          final novaHabilidade = Habilidade(
            nome: magiaObtida.nome,
            descricao: magiaObtida.descricao,
            tipo: magiaObtida.tipo,
            efeito: magiaObtida.efeito,
            tipoElemental: habilidade.tipoElemental, // Usa o tipo elemental da habilidade original
            valor: magiaObtida.valor,
            custoEnergia: magiaObtida.custoEnergia,
            level: magiaObtida.level,
          );
          
          // Substitui a habilidade no monstro
          final monstrosAtualizados = historia.monstros.map((m) {
            if (m.tipo == monstro.tipo && m.level == monstro.level) {
              final novasHabilidades = m.habilidades.map((h) {
                return h == habilidadeSubstituida ? novaHabilidade : h;
              }).toList();
              return m.copyWith(habilidades: novasHabilidades);
            }
            return m;
          }).toList();
          
          final historiaFinal = historia.copyWith(monstros: monstrosAtualizados);
          widget.onHistoriaAtualizada(historiaFinal);
          
          // Fecha a Casa do Vigarista após equipar a magia
          Navigator.of(context).pop(); // Fecha o Casa do Vigarista
          
          _mostrarMensagemSucesso('${monstro.tipo.displayName} aprendeu ${novaHabilidade.nome}!');
        },
      ),
    );
  }

  void _mostrarResultadoCura(int porcentagem, HistoriaJogador historia) {
    // Usa o modal existente de cura obtida
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModalCuraObtida(
        porcentagem: porcentagem,
        monstrosDisponiveis: historia.monstros,
        onCurarMonstro: (monstro, porcentagemCura) async {
          // Calcula a cura
          final curaTotal = (monstro.vida * porcentagemCura / 100).round();
          final novaVidaAtual = (monstro.vidaAtual + curaTotal).clamp(0, monstro.vida);
          
          // Atualiza o monstro com a nova vida
          final monstrosAtualizados = historia.monstros.map((m) {
            if (m.tipo == monstro.tipo && m.level == monstro.level) {
              return m.copyWith(vidaAtual: novaVidaAtual);
            }
            return m;
          }).toList();
          
          final historiaFinal = historia.copyWith(monstros: monstrosAtualizados);
          widget.onHistoriaAtualizada(historiaFinal);
          
          // Fecha a Casa do Vigarista após curar o monstro
          Navigator.of(context).pop(); // Fecha o Casa do Vigarista
          
          _mostrarMensagemSucesso('${monstro.tipo.displayName} foi curado em $porcentagemCura%!');
        },
      ),
    );
  }


  void _mostrarMensagemSucesso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
    setState(() { _comprando = false; });
  }
}