/// Status visual do mascote baseado em suas barras
enum StatusMascote {
  feliz('🥰', 'Feliz', 'Tudo acima de 70%'),
  normal('😊', 'Normal', 'Status OK'),
  comFome('😫', 'Com Fome', 'Fome abaixo de 30%'),
  comSede('🥵', 'Com Sede', 'Sede abaixo de 30%'),
  sujo('🦨', 'Sujo', 'Higiene abaixo de 30%'),
  triste('😢', 'Triste', 'Alegria abaixo de 30%'),
  doente('🤢', 'Doente', 'Mascote está doente'),
  critico('☠️', 'Crítico', 'Alguma barra zerada'),
  morto('🥚', 'Morto', 'Mascote morreu');

  const StatusMascote(this.emoji, this.nome, this.descricao);

  final String emoji;
  final String nome;
  final String descricao;
}
