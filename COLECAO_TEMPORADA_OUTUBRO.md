# Sistema de Coleção - Análise e Implementação de Temporada

## 📋 Sistema Atual de Coleção

### Arquitetura
```
ColecaoService (colecao_service.dart)
├── ColecaoHiveService (colecao_hive_service.dart) - Armazenamento local
└── GoogleDriveService - Sincronização na nuvem
```

### Como Funciona Atualmente

#### 1. **Armazenamento**
- **Local (HIVE)**: `colecoes` box
  - Chave: `colecao_{email}`
  - Dados: `{ email, monstros: {nome: bool}, ultima_atualizacao, sincronizado_drive }`
- **Nuvem (Drive)**: `colecao/{email}.json`

#### 2. **Fluxo de Carga**
```
1. Tenta carregar do HIVE (local) ✅ RÁPIDO
2. Se não encontrar, busca no Drive ⏱️ LENTO
3. Se buscar do Drive, salva no HIVE para cache
4. Se não encontrar em lugar nenhum, cria inicial
```

#### 3. **Fluxo de Salvamento**
```
1. Salva no HIVE (local) ✅ SEMPRE
2. Tenta sincronizar com Drive 📤 OPCIONAL
3. Se sincronizar com Drive, marca como sincronizado
```

### Monstros Disponíveis Atualmente

**Coleção Nostálgica** (30 monstros):
```dart
'agua', 'alien', 'desconhecido', 'deus', 'docrates', 'dragao',
'eletrico', 'fantasma', 'fera', 'fogo', 'gelo', 'inseto',
'luz', 'magico', 'marinho', 'mistico', 'normal', 'nostalgico',
'pedra', 'planta', 'psiquico', 'subterraneo', 'tecnologia', 'tempo',
'terrestre', 'trevas', 'venenoso', 'vento', 'voador', 'zumbi'
```

**Assets Path**:
- Nostálgicos: `assets/monstros_aventura/colecao_nostalgicos/{tipo}.png`
- Iniciais: `assets/monstros_aventura/colecao_inicial/{tipo}.png`

### Onde São Usados

1. **aventura_screen.dart** (linha ~198-242):
   - Sorteio de monstros para o time do jogador
   - Adiciona monstros nostálgicos desbloqueados à roleta de sorteio

2. **monstro_inimigo.dart**:
   - Flag `isRaro` para identificar monstros de coleção

3. **batalha_screen.dart**:
   - Sistema de desbloqueio após derrotar monstro raro
   - Mostra modal de desbloqueio

---

## 🎃 IMPLEMENTAÇÃO: Coleção de Temporada (Outubro)

### Objetivo
Criar uma **coleção especial de Halloween** que:
- Só aparece em **outubro** (mês 10)
- Tem monstros temáticos (fantasma, zumbi, trevas, etc)
- É independente da coleção nostálgica
- Desaparece automaticamente após outubro

---

### Arquitetura Proposta

#### 1. **Novo Enum para Tipos de Coleção**

**Criar arquivo**: `lib/features/aventura/models/tipo_colecao.dart`

```dart
enum TipoColecao {
  inicial,
  nostalgico,
  halloween, // Coleção de outubro
}

extension TipoColecaoExtension on TipoColecao {
  String get nome {
    switch (this) {
      case TipoColecao.inicial:
        return 'Inicial';
      case TipoColecao.nostalgico:
        return 'Nostálgico';
      case TipoColecao.halloween:
        return 'Halloween';
    }
  }

  String get descricao {
    switch (this) {
      case TipoColecao.inicial:
        return 'Monstros básicos disponíveis para todos';
      case TipoColecao.nostalgico:
        return 'Monstros raros da coleção nostálgica';
      case TipoColecao.halloween:
        return 'Monstros especiais de Halloween (Outubro)';
    }
  }

  /// Verifica se a coleção está ativa no momento
  bool get estaAtiva {
    switch (this) {
      case TipoColecao.inicial:
        return true; // Sempre disponível
      case TipoColecao.nostalgico:
        return true; // Sempre disponível
      case TipoColecao.halloween:
        // Só ativo em outubro
        return DateTime.now().month == 10;
    }
  }

  /// Retorna o path dos assets
  String get assetsPath {
    switch (this) {
      case TipoColecao.inicial:
        return 'assets/monstros_aventura/colecao_inicial';
      case TipoColecao.nostalgico:
        return 'assets/monstros_aventura/colecao_nostalgicos';
      case TipoColecao.halloween:
        return 'assets/monstros_aventura/colecao_halloween';
    }
  }

  /// Cor temática da coleção
  Color get corTematica {
    switch (this) {
      case TipoColecao.inicial:
        return Colors.blue;
      case TipoColecao.nostalgico:
        return Colors.purple;
      case TipoColecao.halloween:
        return Colors.orange; // Laranja de Halloween
    }
  }
}
```

---

#### 2. **Atualizar Modelo de Dados**

**Modificar**: `colecao_hive_service.dart`

```dart
/// Adicionar método para criar coleção de Halloween
Map<String, bool> criarColecaoHalloween() {
  final monstrosHalloween = [
    'fantasma',
    'zumbi',
    'trevas',
    'morcego', // NOVO
    'abobora', // NOVO
    'caveira', // NOVO
    'bruxa',   // NOVO
    'vampiro', // NOVO
  ];

  final colecaoHalloween = <String, bool>{};
  for (final monstro in monstrosHalloween) {
    colecaoHalloween[monstro] = false;
  }

  print('🎃 [ColecaoHiveService] Coleção Halloween criada com ${colecaoHalloween.length} monstros');
  return colecaoHalloween;
}

/// Atualizar método criarColecaoInicial para incluir Halloween
Map<String, bool> criarColecaoInicial() {
  final monstrosNostalgicos = [
    'agua', 'alien', 'desconhecido', 'deus', 'docrates', 'dragao',
    'eletrico', 'fantasma', 'fera', 'fogo', 'gelo', 'inseto',
    'luz', 'magico', 'marinho', 'mistico', 'normal', 'nostalgico',
    'pedra', 'planta', 'psiquico', 'subterraneo', 'tecnologia', 'tempo',
    'terrestre', 'trevas', 'venenoso', 'vento', 'voador', 'zumbi'
  ];

  // Adicionar monstros de Halloween
  final monstrosHalloween = [
    'morcego',
    'abobora',
    'caveira',
    'bruxa',
    'vampiro',
  ];

  final colecaoInicial = <String, bool>{};

  // Adiciona nostálgicos
  for (final monstro in monstrosNostalgicos) {
    colecaoInicial[monstro] = false;
  }

  // Adiciona Halloween
  for (final monstro in monstrosHalloween) {
    colecaoInicial[monstro] = false;
  }

  print('🆕 [ColecaoHiveService] Coleção inicial criada com ${colecaoInicial.length} monstros');
  return colecaoInicial;
}
```

---

#### 3. **Atualizar ColecaoService**

**Modificar**: `colecao_service.dart`

```dart
/// Retorna uma lista dos monstros Halloween desbloqueados
Future<List<String>> obterMonstrosHalloweenDesbloqueados(String email) async {
  try {
    print('🎃 [ColecaoService] Obtendo monstros Halloween desbloqueados para: $email');

    final colecao = await carregarColecaoJogador(email);

    // Lista dos monstros de Halloween
    final monstrosHalloween = [
      'fantasma', // Já existente na coleção nostálgica
      'zumbi',    // Já existente na coleção nostálgica
      'trevas',   // Já existente na coleção nostálgica
      'morcego',  // NOVO
      'abobora',  // NOVO
      'caveira',  // NOVO
      'bruxa',    // NOVO
      'vampiro',  // NOVO
    ];

    // Filtra apenas os monstros Halloween que estão desbloqueados
    final desbloqueados = monstrosHalloween
        .where((monstro) => colecao[monstro] == true)
        .toList();

    print('✅ [ColecaoService] Monstros Halloween desbloqueados: ${desbloqueados.length}');
    print('📋 [ColecaoService] Lista: $desbloqueados');

    return desbloqueados;
  } catch (e) {
    print('❌ [ColecaoService] Erro ao obter monstros Halloween: $e');
    return [];
  }
}

/// Verifica se é outubro e se deve mostrar monstros de Halloween
bool get estaNoMesDeHalloween {
  return DateTime.now().month == 10;
}

/// Retorna todos os monstros desbloqueados disponíveis para sorteio
/// Considera a temporada atual
Future<List<String>> obterMonstrosDisponiveisParaSorteio(String email) async {
  try {
    print('🎲 [ColecaoService] Obtendo monstros disponíveis para sorteio');

    final monstrosNostalgicos = await obterMonstrosNostalgicosDesbloqueados(email);
    final monstrosDisponiveis = <String>[...monstrosNostalgicos];

    // Se for outubro, adiciona monstros de Halloween
    if (estaNoMesDeHalloween) {
      final monstrosHalloween = await obterMonstrosHalloweenDesbloqueados(email);
      monstrosDisponiveis.addAll(monstrosHalloween);
      print('🎃 [ColecaoService] Outubro detectado! Adicionando ${monstrosHalloween.length} monstros de Halloween');
    }

    print('✅ [ColecaoService] Total de monstros disponíveis: ${monstrosDisponiveis.length}');
    return monstrosDisponiveis;
  } catch (e) {
    print('❌ [ColecaoService] Erro ao obter monstros disponíveis: $e');
    return [];
  }
}
```

---

#### 4. **Atualizar Sistema de Sorteio**

**Modificar**: `aventura_screen.dart` (método `_gerarNovosMonstrosLocal`)

```dart
Future<List<MonstroAventura>> _gerarNovosMonstrosLocal() async {
  final random = Random();
  final tiposDisponiveis = Tipo.values.toList();
  final emailJogador = ref.read(validUserEmailProvider);

  print('🎯 [AventuraScreen] Consultando coleção de monstros para: $emailJogador');

  final ColecaoService colecaoService = ColecaoService();

  // MUDANÇA: Usar novo método que considera temporada
  final monstrosDesbloqueados = await colecaoService.obterMonstrosDisponiveisParaSorteio(emailJogador);

  // Adiciona os monstros desbloqueados à lista de tipos disponíveis
  final todosOsTiposDisponiveis = [...tiposDisponiveis];

  for (final nomeDesbloqueado in monstrosDesbloqueados) {
    try {
      final tipoNostalgico = Tipo.values.firstWhere(
        (t) => t.name.toLowerCase() == nomeDesbloqueado.toLowerCase(),
      );
      todosOsTiposDisponiveis.add(tipoNostalgico);

      // Identificar se é Halloween
      final ehHalloween = colecaoService.estaNoMesDeHalloween &&
                         ['morcego', 'abobora', 'caveira', 'bruxa', 'vampiro']
                             .contains(nomeDesbloqueado.toLowerCase());

      if (ehHalloween) {
        print('🎃 [AventuraScreen] Monstro HALLOWEEN ADICIONADO: ${tipoNostalgico.name}');
      } else {
        print('🌟 [AventuraScreen] Monstro nostálgico ADICIONADO: ${tipoNostalgico.name}');
      }
    } catch (e) {
      print('⚠️ [AventuraScreen] Monstro não encontrado nos tipos: $nomeDesbloqueado');
    }
  }

  // ... resto do código de sorteio
}
```

---

#### 5. **Atualizar Modelo MonstroAventura**

**Modificar**: `lib/features/aventura/models/monstro_aventura.dart`

Adicionar propriedade:
```dart
class MonstroAventura {
  // ... propriedades existentes
  final bool ehNostalgico;
  final bool ehHalloween; // NOVO

  const MonstroAventura({
    // ... parâmetros existentes
    this.ehNostalgico = false,
    this.ehHalloween = false, // NOVO
  });

  // Atualizar copyWith
  MonstroAventura copyWith({
    // ... outros parâmetros
    bool? ehNostalgico,
    bool? ehHalloween,
  }) {
    return MonstroAventura(
      // ... outros campos
      ehNostalgico: ehNostalgico ?? this.ehNostalgico,
      ehHalloween: ehHalloween ?? this.ehHalloween,
    );
  }

  // Atualizar toJson
  Map<String, dynamic> toJson() {
    return {
      // ... outros campos
      'ehNostalgico': ehNostalgico,
      'ehHalloween': ehHalloween,
    };
  }

  // Atualizar fromJson
  factory MonstroAventura.fromJson(Map<String, dynamic> json) {
    return MonstroAventura(
      // ... outros campos
      ehNostalgico: json['ehNostalgico'] ?? false,
      ehHalloween: json['ehHalloween'] ?? false,
    );
  }
}
```

---

#### 6. **Assets Necessários**

Criar pasta: `assets/monstros_aventura/colecao_halloween/`

**Novos Assets Necessários**:
```
assets/monstros_aventura/colecao_halloween/
├── morcego.png       (novo)
├── abobora.png       (novo)
├── caveira.png       (novo)
├── bruxa.png         (novo)
├── vampiro.png       (novo)
├── fantasma.png      (cópia do nostálgico, versão Halloween)
├── zumbi.png         (cópia do nostálgico, versão Halloween)
└── trevas.png        (cópia do nostálgico, versão Halloween)
```

**Atualizar `pubspec.yaml`**:
```yaml
flutter:
  assets:
    # ... assets existentes
    - assets/monstros_aventura/colecao_halloween/
```

---

#### 7. **UI - Badge de Temporada**

**Criar widget**: `lib/features/aventura/widgets/badge_temporada.dart`

```dart
import 'package:flutter/material.dart';

class BadgeTemporada extends StatelessWidget {
  final String texto;
  final Color cor;
  final IconData? icone;

  const BadgeTemporada({
    super.key,
    required this.texto,
    this.cor = Colors.orange,
    this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: 14, color: cor),
            const SizedBox(width: 4),
          ],
          Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
}
```

**Usar nos cards de monstro**:
```dart
// Em modal_monstro_inimigo.dart ou card de monstro
if (monstro.ehHalloween && DateTime.now().month == 10)
  const BadgeTemporada(
    texto: 'HALLOWEEN',
    cor: Colors.orange,
    icone: Icons.celebration,
  ),
```

---

### Fluxo de Implementação

#### FASE 1: Backend (1-2 dias)
1. ✅ Criar enum `TipoColecao`
2. ✅ Atualizar `ColecaoHiveService.criarColecaoInicial()`
3. ✅ Adicionar método `criarColecaoHalloween()`
4. ✅ Criar método `obterMonstrosHalloweenDesbloqueados()`
5. ✅ Criar método `obterMonstrosDisponiveisParaSorteio()`
6. ✅ Adicionar getter `estaNoMesDeHalloween`

#### FASE 2: Sorteio (1 dia)
7. ✅ Atualizar `_gerarNovosMonstrosLocal()` em `aventura_screen.dart`
8. ✅ Adicionar flag `ehHalloween` em `MonstroAventura`
9. ✅ Atualizar lógica de sorteio para considerar temporada

#### FASE 3: Assets (1-2 dias)
10. ⬜ Criar/obter 5 novos sprites de monstros Halloween
11. ⬜ Adicionar sprites na pasta `colecao_halloween/`
12. ⬜ Atualizar `pubspec.yaml`

#### FASE 4: UI (1 dia)
13. ✅ Criar widget `BadgeTemporada`
14. ✅ Adicionar badge nos cards de monstro
15. ✅ Adicionar indicador visual na tela de coleção

#### FASE 5: Testes (1 dia)
16. ⬜ Testar em outubro (ou mockar data)
17. ⬜ Testar fora de outubro (monstros devem sumir)
18. ⬜ Testar desbloqueio e salvamento
19. ⬜ Testar sincronização Drive

---

### Testes

#### Mock de Data para Testar

**Criar arquivo de teste**: `lib/core/utils/date_helper.dart`

```dart
import '../config/developer_config.dart';

class DateHelper {
  /// Retorna a data atual ou data mockada (para testes)
  static DateTime now() {
    // Em modo de desenvolvimento, permite forçar data
    if (DeveloperConfig.FORCE_HALLOWEEN_MODE) {
      return DateTime(2024, 10, 15); // 15 de outubro
    }
    return DateTime.now();
  }

  /// Verifica se está em outubro
  static bool get ehOutubro => now().month == 10;
}
```

**Atualizar `developer_config.dart`**:
```dart
class DeveloperConfig {
  // ... configs existentes
  static const bool FORCE_HALLOWEEN_MODE = false; // Mudar para true para testar
}
```

**Usar em todos os lugares**:
```dart
// Trocar todos:
DateTime.now().month == 10

// Por:
DateHelper.ehOutubro
```

---

### Checklist de Implementação

#### Backend
- [ ] Criar `tipo_colecao.dart`
- [ ] Atualizar `colecao_hive_service.dart`
- [ ] Atualizar `colecao_service.dart`
- [ ] Adicionar métodos de Halloween

#### Modelos
- [ ] Atualizar `MonstroAventura` (flag `ehHalloween`)
- [ ] Atualizar `MonstroInimigo` se necessário

#### Sorteio
- [ ] Modificar `_gerarNovosMonstrosLocal()` em `aventura_screen.dart`
- [ ] Atualizar lógica de adição à roleta

#### Assets
- [ ] Criar pasta `colecao_halloween/`
- [ ] Adicionar 5 novos sprites
- [ ] Copiar 3 sprites existentes (versão Halloween)
- [ ] Atualizar `pubspec.yaml`

#### UI
- [ ] Criar `BadgeTemporada` widget
- [ ] Adicionar badge nos cards
- [ ] Atualizar tela de coleção

#### Testes
- [ ] Criar `DateHelper` para mock
- [ ] Testar em outubro
- [ ] Testar fora de outubro
- [ ] Testar desbloqueio
- [ ] Testar salvamento

---

### Benefícios da Implementação

1. **Engajamento Sazonal**: Jogadores voltam em outubro para coletar monstros exclusivos
2. **FOMO (Fear of Missing Out)**: Coleção temporária cria urgência
3. **Replayability**: Incentiva jogar mais para desbloquear tudo
4. **Escalável**: Sistema serve de base para outras temporadas (Natal, Páscoa, etc)

---

### Próximas Temporadas

Após Halloween, você pode criar:

#### Dezembro - Natal
- `colecao_natal/`
- Monstros: gelo, neve, rena, elfo, papai_noel

#### Abril - Páscoa
- `colecao_pascoa/`
- Monstros: coelho, ovo, chocolate, passaro

#### Junho - Festa Junina (Brasil)
- `colecao_junina/`
- Monstros: fogueira, balao, milho, bandeira

---

## 🎯 Próximos Passos Imediatos

1. Criar enum `TipoColecao`
2. Atualizar `criarColecaoInicial()` para incluir monstros Halloween
3. Adicionar método `obterMonstrosDisponiveisParaSorteio()`
4. Modificar sorteio para usar novo método
5. Testar com `FORCE_HALLOWEEN_MODE = true`

**Deseja que eu comece a implementação?**
