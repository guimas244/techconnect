/// Causas de morte do mascote
enum CausaMorte {
  fome('😫', 'Fome', 'Morreu de fome'),
  sede('🥵', 'Desidratação', 'Morreu de sede'),
  higiene('🦨', 'Infecção', 'Morreu por falta de higiene'),
  doenca('🤒', 'Doença', 'Morreu de doença não tratada'),
  saude('☠️', 'Saúde', 'Saúde chegou a zero');

  const CausaMorte(this.emoji, this.nome, this.descricao);

  final String emoji;
  final String nome;
  final String descricao;

  String get nomeCompleto => '$emoji $nome';
}
