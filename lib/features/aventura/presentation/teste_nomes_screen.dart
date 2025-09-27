import 'package:flutter/material.dart';
import '../../../shared/models/tipo_enum.dart';
import '../models/monstro_aventura.dart';

class TesteNomesScreen extends StatelessWidget {
  const TesteNomesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Criar monstros de exemplo
    final monstroInicial = MonstroAventura(
      tipo: Tipo.fogo,
      tipoExtra: Tipo.dragao,
      imagem: 'assets/monstros_aventura/colecao_inicial/fogo.png',
      vida: 100,
      energia: 50,
      agilidade: 30,
      ataque: 40,
      defesa: 35,
      habilidades: [],
    );

    final monstroNostalgico = MonstroAventura(
      tipo: Tipo.fogo,
      tipoExtra: Tipo.dragao,
      imagem: 'assets/monstros_aventura/colecao_nostalgicos/fogo.png',
      vida: 100,
      energia: 50,
      agilidade: 30,
      ataque: 40,
      defesa: 35,
      habilidades: [],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste - Nomes Nostálgicos'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comparação de Nomes',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Monstro Inicial
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star_border, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'MONSTRO INICIAL',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nome: ${monstroInicial.nome}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    Text(
                      'Tipo: ${monstroInicial.tipo.displayName}',
                      style: TextStyle(color: monstroInicial.tipo.cor),
                    ),
                    Text(
                      'Nostálgico: ${monstroInicial.ehNostalgico ? "Sim" : "Não"}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Imagem: ${monstroInicial.imagem}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Monstro Nostálgico
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(
                          'MONSTRO NOSTÁLGICO',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nome: ${monstroNostalgico.nome}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    Text(
                      'Tipo: ${monstroNostalgico.tipo.displayName}',
                      style: TextStyle(color: monstroNostalgico.tipo.cor),
                    ),
                    Text(
                      'Nostálgico: ${monstroNostalgico.ehNostalgico ? "Sim" : "Não"}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Imagem: ${monstroNostalgico.imagem}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Lista de todos os nomes
            const Text(
              'Todos os Nomes Nostálgicos:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                itemCount: Tipo.values.length,
                itemBuilder: (context, index) {
                  final tipo = Tipo.values[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: tipo.cor,
                        child: Icon(Icons.pets, color: Colors.white, size: 16),
                      ),
                      title: Text(tipo.nostalgicMonsterName),
                      subtitle: Text('Original: ${tipo.monsterName}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}