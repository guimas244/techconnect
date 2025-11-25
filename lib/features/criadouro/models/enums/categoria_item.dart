/// Categorias de itens disponíveis na Loja do Criador
enum CategoriaItem {
  alimentacao('🍖', 'Alimentação'),
  hidratacao('💧', 'Hidratação'),
  medicamento('💊', 'Medicamentos'),
  higiene('🧼', 'Higiene'),
  brinquedo('🎾', 'Brinquedos');

  const CategoriaItem(this.emoji, this.nome);

  final String emoji;
  final String nome;

  String get nomeCompleto => '$emoji $nome';
}
