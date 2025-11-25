/// Tipos de efeito que um item pode ter no mascote
enum TipoEfeito {
  fome('🍖', 'Fome'),
  sede('💧', 'Sede'),
  higiene('🧼', 'Higiene'),
  alegria('😄', 'Alegria'),
  saude('❤️', 'Saúde'),
  curarDoenca('💊', 'Curar Doença');

  const TipoEfeito(this.emoji, this.nome);

  final String emoji;
  final String nome;

  String get nomeCompleto => '$emoji $nome';
}
