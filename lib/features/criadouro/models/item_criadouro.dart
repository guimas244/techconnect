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
      id: 'racao_basica',
      nome: 'Ração Básica',
      categoria: CategoriaItem.alimentacao,
      preco: 5,
      tipoEfeito: TipoEfeito.fome,
      valorEfeito: 20,
    ),
    ItemCriadouro(
      id: 'racao_premium',
      nome: 'Ração Premium',
      categoria: CategoriaItem.alimentacao,
      preco: 15,
      tipoEfeito: TipoEfeito.fome,
      valorEfeito: 50,
    ),
    ItemCriadouro(
      id: 'banquete',
      nome: 'Banquete',
      categoria: CategoriaItem.alimentacao,
      preco: 30,
      tipoEfeito: TipoEfeito.fome,
      valorEfeito: 100,
    ),
    ItemCriadouro(
      id: 'nuty',
      nome: 'Nuty',
      categoria: CategoriaItem.alimentacao,
      preco: 3,
      tipoEfeito: TipoEfeito.fome,
      valorEfeito: 10,
    ),

    // 💧 Hidratação
    ItemCriadouro(
      id: 'agua',
      nome: 'Água',
      categoria: CategoriaItem.hidratacao,
      preco: 3,
      tipoEfeito: TipoEfeito.sede,
      valorEfeito: 20,
    ),
    ItemCriadouro(
      id: 'suco_natural',
      nome: 'Suco Natural',
      categoria: CategoriaItem.hidratacao,
      preco: 8,
      tipoEfeito: TipoEfeito.sede,
      valorEfeito: 40,
    ),
    ItemCriadouro(
      id: 'bebida_energetica',
      nome: 'Bebida Energética',
      categoria: CategoriaItem.hidratacao,
      preco: 20,
      tipoEfeito: TipoEfeito.sede,
      valorEfeito: 80,
    ),

    // 💊 Medicamentos
    ItemCriadouro(
      id: 'remedio_basico',
      nome: 'Remédio Básico',
      categoria: CategoriaItem.medicamento,
      preco: 25,
      tipoEfeito: TipoEfeito.curarDoenca,
      valorEfeito: 0,
      descricao: 'Cura qualquer doença',
    ),
    ItemCriadouro(
      id: 'kit_primeiros_socorros',
      nome: 'Kit Primeiros Socorros',
      categoria: CategoriaItem.medicamento,
      preco: 50,
      tipoEfeito: TipoEfeito.curarDoenca,
      valorEfeito: 0,
      tipoEfeitoExtra: TipoEfeito.saude,
      valorEfeitoExtra: 30,
      descricao: 'Cura doença e restaura saúde',
    ),
    ItemCriadouro(
      id: 'vitaminas',
      nome: 'Vitaminas',
      categoria: CategoriaItem.medicamento,
      preco: 15,
      tipoEfeito: TipoEfeito.saude,
      valorEfeito: 20,
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
      id: 'bolinha',
      nome: 'Bolinha',
      categoria: CategoriaItem.brinquedo,
      preco: 10,
      tipoEfeito: TipoEfeito.alegria,
      valorEfeito: 15,
    ),
    ItemCriadouro(
      id: 'osso',
      nome: 'Osso',
      categoria: CategoriaItem.brinquedo,
      preco: 12,
      tipoEfeito: TipoEfeito.alegria,
      valorEfeito: 15,
    ),
    ItemCriadouro(
      id: 'brinquedo_squeaky',
      nome: 'Brinquedo Squeaky',
      categoria: CategoriaItem.brinquedo,
      preco: 20,
      tipoEfeito: TipoEfeito.alegria,
      valorEfeito: 25,
    ),
    ItemCriadouro(
      id: 'brinquedo_premium',
      nome: 'Brinquedo Premium',
      categoria: CategoriaItem.brinquedo,
      preco: 40,
      tipoEfeito: TipoEfeito.alegria,
      valorEfeito: 40,
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
