import 'dart:math';
import '../models/item.dart';
import '../utils/gerador_nomes_itens.dart';

class ItemService {
  final Random _random = Random();

  /// Gera um item aleatório ao derrotar um monstro
  Item gerarItemAleatorio({int tierAtual = 1}) {
    print('🏆 [ItemService] Gerando item para tier $tierAtual');
    
    // Determina a quantidade de atributos (2% de 5, 3% de 4, 10% de 3, 20% de 2, resto de 1)
    int quantidadeAtributos = _determinarQuantidadeAtributos();
    
    // Determina a raridade baseada na quantidade de atributos
    RaridadeItem raridade = _determinarRaridade(quantidadeAtributos);
    
    // Gera o nome do item baseado na raridade
    String nome = GeradorNomesItens.gerarNomeItem();
    
    // Gera os atributos do item (com multiplicação por tier)
    Map<String, int> atributos = _gerarAtributos(quantidadeAtributos, tierAtual);
    
    print('✅ [ItemService] Item gerado: $nome (${raridade.nome}) | Tier: $tierAtual | Total atributos: ${atributos.values.fold(0, (sum, value) => sum + value)}');
    
    return Item(
      id: _gerarId(),
      nome: nome,
      raridade: raridade,
      atributos: atributos,
      dataObtencao: DateTime.now(),
      tier: tierAtual,
    );
  }

  /// Determina a quantidade de atributos baseado nas probabilidades
  int _determinarQuantidadeAtributos() {
    int chance = _random.nextInt(100) + 1; // 1-100
    
    if (chance <= 2) return 5; // 2%
    if (chance <= 5) return 4; // 3%
    if (chance <= 15) return 3; // 10%
    if (chance <= 35) return 2; // 20%
    return 1; // 65%
  }

  /// Determina a raridade baseada na quantidade de atributos
  RaridadeItem _determinarRaridade(int quantidadeAtributos) {
    switch (quantidadeAtributos) {
      case 5:
        return RaridadeItem.lendario;
      case 4:
        return RaridadeItem.epico;
      case 3:
        return RaridadeItem.raro;
      case 2:
        return RaridadeItem.normal;
      default:
        return RaridadeItem.inferior;
    }
  }

  /// Gera atributos aleatórios para o item (aplicando multiplicação por tier)
  Map<String, int> _gerarAtributos(int quantidade, int tier) {
    List<String> atributosDisponiveis = ['vida', 'energia', 'ataque', 'defesa', 'agilidade'];
    atributosDisponiveis.shuffle(_random);
    
    Map<String, int> atributos = {};
    
    for (int i = 0; i < quantidade; i++) {
      String atributo = atributosDisponiveis[i];
      int valorBase = _random.nextInt(10) + 1; // 1-10 pontos base por atributo
      int valorFinal = valorBase * tier; // Multiplica pelo tier
      atributos[atributo] = valorFinal;
      
      print('🎯 [ItemService] Atributo: $atributo | Base: $valorBase | Tier: $tier | Final: $valorFinal');
    }
    
    return atributos;
  }

  /// Gera um ID único para o item
  String _gerarId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           _random.nextInt(1000).toString();
  }

  /// Calcula o valor estimado do item (para comparação)
  int calcularValorItem(Item item) {
    int valorBase = item.totalAtributos * 10;
    int multiplicadorRaridade = item.raridade.nivel;
    return valorBase * multiplicadorRaridade;
  }

  /// Compara dois itens e retorna qual é melhor
  bool itemEhMelhor(Item novoItem, Item? itemAtual) {
    if (itemAtual == null) return true;
    return calcularValorItem(novoItem) > calcularValorItem(itemAtual);
  }
}
