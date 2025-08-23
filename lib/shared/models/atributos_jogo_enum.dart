import 'dart:math';

enum AtributoJogo {
  vida('Vida', 50, 100),
  energia('Energia', 20, 40),
  agilidade('Agilidade', 10, 20),
  ataque('Ataque', 10, 20),
  defesa('Defesa', 40, 60);

  final String nome;
  final int valorMinimo;
  final int valorMaximo;

  const AtributoJogo(this.nome, this.valorMinimo, this.valorMaximo);

  /// Sorteia um valor aleatório dentro do range do atributo
  int sortearValor(Random random) {
    return valorMinimo + random.nextInt(valorMaximo - valorMinimo + 1);
  }

  /// Valida se um valor está dentro do range permitido
  bool validarValor(int valor) {
    return valor >= valorMinimo && valor <= valorMaximo;
  }

  /// Retorna o range como string para exibição
  String get rangeTexto => '$valorMinimo - $valorMaximo';
}
