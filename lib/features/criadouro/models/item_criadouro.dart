import 'enums/categoria_item.dart';
import 'enums/tipo_efeito.dart';

/// Item disponível na loja do Criadouro
class ItemCriadouro {
  final String id;
  final String nome;
  final CategoriaItem categoria;
  final int preco; // Preço em Planis
  final TipoEfeito tipoEfeito;
  final double valorEfeito; // Porcentagem que adiciona (ex: 20.0 = +20%)
  final TipoEfeito? tipoEfeitoExtra; // Efeito secundário opcional
  final double? valorEfeitoExtra;
  final String? descricao;
  final String? iconPath; // Caminho da imagem do item (opcional)

  const ItemCriadouro({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.preco,
    required this.tipoEfeito,
    required this.valorEfeito,
    this.tipoEfeitoExtra,
    this.valorEfeitoExtra,
    this.descricao,
    this.iconPath,
  });

  factory ItemCriadouro.fromJson(Map<String, dynamic> json) {
    return ItemCriadouro(
      id: json['id'] as String,
      nome: json['nome'] as String,
      categoria: CategoriaItem.values.firstWhere(
        (c) => c.name == json['categoria'],
      ),
      preco: json['preco'] as int,
      tipoEfeito: TipoEfeito.values.firstWhere(
        (t) => t.name == json['tipoEfeito'],
      ),
      valorEfeito: (json['valorEfeito'] as num).toDouble(),
      tipoEfeitoExtra: json['tipoEfeitoExtra'] != null
          ? TipoEfeito.values.firstWhere(
              (t) => t.name == json['tipoEfeitoExtra'],
            )
          : null,
      valorEfeitoExtra: json['valorEfeitoExtra'] != null
          ? (json['valorEfeitoExtra'] as num).toDouble()
          : null,
      descricao: json['descricao'] as String?,
      iconPath: json['iconPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'categoria': categoria.name,
      'preco': preco,
      'tipoEfeito': tipoEfeito.name,
      'valorEfeito': valorEfeito,
      if (tipoEfeitoExtra != null) 'tipoEfeitoExtra': tipoEfeitoExtra!.name,
      if (valorEfeitoExtra != null) 'valorEfeitoExtra': valorEfeitoExtra,
      if (descricao != null) 'descricao': descricao,
      if (iconPath != null) 'iconPath': iconPath,
    };
  }

  /// Descrição do efeito formatada
  String get efeitoDescricao {
    final efeitoPrincipal = '+${valorEfeito.toInt()}% ${tipoEfeito.nome}';
    if (tipoEfeitoExtra != null && valorEfeitoExtra != null) {
      return '$efeitoPrincipal, +${valorEfeitoExtra!.toInt()}% ${tipoEfeitoExtra!.nome}';
    }
    return efeitoPrincipal;
  }

  /// Emoji do item baseado na categoria
  String get emoji => categoria.emoji;
}

/// Itens padrão da loja do Criadouro
class ItensCriadouro {
  static const List<ItemCriadouro> todos = [
    // 🍖 Alimentação
    ItemCriadouro(
      id: 'estiga',
      nome: 'Estiga',
      categoria: CategoriaItem.alimentacao,
      preco: 5,
      tipoEfeito: TipoEfeito.fome,
      valorEfeito: 20,
      iconPath: 'assets/criadouro/comidas/comida_basica.png',
    ),
    ItemCriadouro(
      id: 'refeicao_basica',
      nome: 'Refeição Básica',
      categoria: CategoriaItem.alimentacao,
      preco: 15,
      tipoEfeito: TipoEfeito.fome,
      valorEfeito: 50,
      iconPath: 'assets/criadouro/comidas/comida_media.png',
    ),
    ItemCriadouro(
      id: 'refeicao_avancada',
      nome: 'Refeição Avançada',
      categoria: CategoriaItem.alimentacao,
      preco: 30,
      tipoEfeito: TipoEfeito.fome,
      valorEfeito: 100,
      iconPath: 'assets/criadouro/comidas/comida_avancada.png',
    ),

    // 💧 Hidratação
    ItemCriadouro(
      id: 'agua',
      nome: 'Água',
      categoria: CategoriaItem.hidratacao,
      preco: 1,
      tipoEfeito: TipoEfeito.sede,
      valorEfeito: 20,
      iconPath: 'assets/criadouro/comidas/mantimento_agua.png',
    ),

    // 💊 Medicamentos
    ItemCriadouro(
      id: 'curandeiro',
      nome: 'Curandeiro',
      categoria: CategoriaItem.medicamento,
      preco: 50,
      tipoEfeito: TipoEfeito.saude,
      valorEfeito: 100,
      tipoEfeitoExtra: TipoEfeito.curarDoenca,
      valorEfeitoExtra: 0,
      descricao: 'Cura completa do mascote',
      iconPath: 'assets/criadouro/comidas/npc_curandeiro.png',
    ),

    // 🧼 Higiene
    ItemCriadouro(
      id: 'sabonete',
      nome: 'Sabonete',
      categoria: CategoriaItem.higiene,
      preco: 5,
      tipoEfeito: TipoEfeito.higiene,
      valorEfeito: 30,
    ),
    ItemCriadouro(
      id: 'kit_banho_completo',
      nome: 'Kit Banho Completo',
      categoria: CategoriaItem.higiene,
      preco: 15,
      tipoEfeito: TipoEfeito.higiene,
      valorEfeito: 70,
    ),
    ItemCriadouro(
      id: 'perfume',
      nome: 'Perfume',
      categoria: CategoriaItem.higiene,
      preco: 10,
      tipoEfeito: TipoEfeito.higiene,
      valorEfeito: 20,
      tipoEfeitoExtra: TipoEfeito.alegria,
      valorEfeitoExtra: 5,
    ),

    // 🎾 Brinquedos
    ItemCriadouro(
      id: 'carinho',
      nome: 'Carinho',
      categoria: CategoriaItem.brinquedo,
      preco: 5,
      tipoEfeito: TipoEfeito.alegria,
      valorEfeito: 20,
      iconPath: 'assets/criadouro/comidas/acao_carinho.png',
    ),
    ItemCriadouro(
      id: 'brinquedo',
      nome: 'Brinquedo',
      categoria: CategoriaItem.brinquedo,
      preco: 15,
      tipoEfeito: TipoEfeito.alegria,
      valorEfeito: 40,
      iconPath: 'assets/criadouro/comidas/acao_brinquedo.png',
    ),
  ];

  /// Busca itens por categoria
  static List<ItemCriadouro> porCategoria(CategoriaItem categoria) {
    return todos.where((item) => item.categoria == categoria).toList();
  }

  /// Busca item por ID
  static ItemCriadouro? porId(String id) {
    try {
      return todos.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }
}
