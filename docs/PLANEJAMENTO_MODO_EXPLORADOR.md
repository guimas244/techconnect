# PLANEJAMENTO: Modo Explorador + Refatoração TechTerra

**Versão:** 1.0
**Data:** 2025-12-22
**Autor:** Claude + Guilherme

---

## SUMÁRIO EXECUTIVO

Este documento detalha a implementação de uma grande refatoração do TechTerra, dividindo o jogo em dois modos distintos:

1. **Modo Unlock** (modo atual adaptado) - Foco em desbloqueio e automático
2. **Modo Explorador** (novo) - Foco em gameplay estratégico manual

---

## ÍNDICE

1. [Visão Geral das Mudanças](#1-visão-geral-das-mudanças)
2. [Fase 1: Infraestrutura Base](#fase-1-infraestrutura-base)
3. [Fase 2: Sistema de Kills Permanentes](#fase-2-sistema-de-kills-permanentes)
4. [Fase 3: Controle de Dispositivo](#fase-3-controle-de-dispositivo)
5. [Fase 4: Modo Unlock (Refatoração do Atual)](#fase-4-modo-unlock)
6. [Fase 5: Modo Explorador - Core](#fase-5-modo-explorador-core)
7. [Fase 6: Sistema de Mapas e Batalhas](#fase-6-sistema-de-mapas-e-batalhas)
8. [Fase 7: Sistema de XP e Evolução](#fase-7-sistema-de-xp-e-evolução)
9. [Fase 8: Sistema de Equipamentos (3 Slots)](#fase-8-sistema-de-equipamentos)
10. [Fase 9: Sistema de Lojas](#fase-9-sistema-de-lojas)
11. [Fase 10: Sistema de Energia e Durabilidade](#fase-10-sistema-de-energia-e-durabilidade)
12. [Fase 11: Drops e Recompensas](#fase-11-drops-e-recompensas)
13. [Fase 12: Polimento e Áudio](#fase-12-polimento-e-audio)
14. [Fase 13: Testes e QA](#fase-13-testes-e-qa)

---

## 1. VISÃO GERAL DAS MUDANÇAS

### 1.1 Comparativo: Modo Atual vs Novos Modos

| Aspecto | Modo Atual | Modo Unlock (Novo) | Modo Explorador (Novo) |
|---------|------------|-------------------|------------------------|
| **Gameplay** | Semi-automático | Automático | Manual estratégico |
| **Monstros** | 3 por batalha | 3 por batalha | 2 por batalha |
| **Kills** | Expiram em 3 dias | Permanentes | Moeda de troca |
| **Desbloqueio** | Coleta monstros | Coleta monstros | Não desbloqueia |
| **Passivas** | Drop aleatório | Drop aleatório | Não obtém novas |
| **Eventos** | Ativos | Removidos | Cartas de evento |
| **Itens** | 1 slot | 1 slot | 3 slots (RPG) |
| **XP** | Não existe | Não existe | Sistema completo |
| **Lojas** | Genéricas | Genéricas | Por tipagem |

### 1.2 Estrutura de Pastas Proposta

```
lib/features/
├── aventura/                    # Código compartilhado (manter)
│   ├── models/
│   │   ├── monstro_aventura.dart      # Atualizar
│   │   ├── monstro_explorador.dart    # NOVO
│   │   ├── kills_permanentes.dart     # NOVO
│   │   ├── equipamento_slot.dart      # NOVO
│   │   ├── sessao_explorador.dart     # NOVO
│   │   └── ...
│   └── services/
│       ├── batalha_service.dart       # Reutilizar
│       ├── kills_service.dart         # NOVO
│       └── ...
├── unlock/                      # NOVO - Modo Unlock
│   ├── presentation/
│   │   └── unlock_screen.dart
│   └── services/
│       └── unlock_service.dart
├── explorador/                  # NOVO - Modo Explorador
│   ├── presentation/
│   │   ├── explorador_home_screen.dart
│   │   ├── selecao_equipe_screen.dart
│   │   ├── selecao_mapa_screen.dart
│   │   ├── batalha_explorador_screen.dart
│   │   ├── loja_explorador_screen.dart
│   │   └── resumo_run_screen.dart
│   ├── models/
│   │   ├── mapa_explorador.dart
│   │   ├── run_explorador.dart
│   │   └── loja_explorador.dart
│   └── services/
│       ├── explorador_service.dart
│       ├── xp_service.dart
│       ├── loja_service.dart
│       └── energia_service.dart
└── dispositivo/                 # NOVO - Controle de dispositivo
    ├── models/
    │   └── dispositivo_info.dart
    └── services/
        └── dispositivo_service.dart
```

---

## FASE 1: INFRAESTRUTURA BASE
**Prioridade:** Alta
**Dependências:** Nenhuma
**Estimativa de Complexidade:** Média

### 1.1 Objetivos
- Criar estrutura de pastas para os novos modos
- Configurar navegação entre modos
- Criar models base compartilhados

### 1.2 Tarefas

#### 1.2.1 Criar Estrutura de Pastas
**Onde:** `lib/features/`

```bash
# Criar pastas
lib/features/unlock/
lib/features/unlock/presentation/
lib/features/unlock/services/
lib/features/explorador/
lib/features/explorador/presentation/
lib/features/explorador/models/
lib/features/explorador/services/
lib/features/dispositivo/
lib/features/dispositivo/models/
lib/features/dispositivo/services/
```

#### 1.2.2 Criar Enum de Modos
**Arquivo:** `lib/core/enums/game_mode.dart` (NOVO)

```dart
enum GameMode {
  unlock,     // Modo automático - desbloqueia monstros
  explorador, // Modo manual - farm e estratégia
}
```

#### 1.2.3 Atualizar Navegação
**Arquivo:** `lib/core/config/app_router.dart`

- Adicionar rota `/modo-selecao` - Tela de seleção de modo
- Adicionar rota `/unlock` - Modo Unlock
- Adicionar rota `/explorador` - Modo Explorador
- Adicionar rota `/explorador/equipe` - Seleção de equipe
- Adicionar rota `/explorador/mapa` - Seleção de mapa
- Adicionar rota `/explorador/batalha` - Batalha do explorador
- Adicionar rota `/explorador/loja` - Loja do explorador

#### 1.2.4 Criar Tela de Seleção de Modo
**Arquivo:** `lib/features/home/presentation/modo_selecao_screen.dart` (NOVO)

```dart
// Tela com dois cards grandes:
// - Card "MODO UNLOCK" -> Navega para /unlock
// - Card "MODO EXPLORADOR" -> Navega para /explorador
// Exibir resumo de cada modo
```

### 1.3 Teste de Validação
- [ ] App inicia e mostra tela de seleção de modo
- [ ] Navegação para Modo Unlock funciona
- [ ] Navegação para Modo Explorador funciona (pode estar vazia)
- [ ] Botão de voltar funciona em ambos os modos

---

## FASE 2: SISTEMA DE KILLS PERMANENTES
**Prioridade:** Alta
**Dependências:** Fase 1
**Estimativa de Complexidade:** Média

### 2.1 Objetivos
- Kills deixam de expirar
- Kills são permanentes por tipo
- Kills servem como moeda no Modo Explorador

### 2.2 Análise do Sistema Atual
**Arquivo atual:** `lib/features/aventura/models/progresso_diario.dart`

O sistema atual:
- Kills expiram após 3 dias
- Armazenadas em `Map<String, Map<Tipo, int>>` por data
- Método `limparKillsAntigos()` remove kills antigas

### 2.3 Tarefas

#### 2.3.1 Criar Model de Kills Permanentes
**Arquivo:** `lib/features/aventura/models/kills_permanentes.dart` (NOVO)

```dart
class KillsPermanentes {
  final Map<Tipo, int> kills; // Kills por tipo (permanentes)
  final DateTime ultimaAtualizacao;

  // Métodos
  KillsPermanentes adicionarKills(Tipo tipo, int quantidade);
  KillsPermanentes gastarKills(Tipo tipo, int quantidade); // Para loja
  int getKillsPorTipo(Tipo tipo);
  int getTotalKills();

  // Serialização
  Map<String, dynamic> toJson();
  factory KillsPermanentes.fromJson(Map<String, dynamic> json);
}
```

#### 2.3.2 Criar KillsService
**Arquivo:** `lib/features/aventura/services/kills_service.dart` (NOVO)

```dart
class KillsService {
  // Carregar kills do Hive
  Future<KillsPermanentes> carregarKills(String email);

  // Salvar kills no Hive
  Future<void> salvarKills(String email, KillsPermanentes kills);

  // Migrar kills antigas (do sistema de 3 dias) para permanentes
  Future<KillsPermanentes> migrarKillsAntigos(String email);

  // Adicionar kill após batalha
  Future<KillsPermanentes> registrarKill(String email, Tipo tipo);

  // Gastar kills na loja
  Future<KillsPermanentes?> gastarKills(String email, Tipo tipo, int quantidade);
}
```

#### 2.3.3 Criar Hive Box para Kills
**Arquivo:** `lib/features/aventura/services/kills_hive_service.dart` (NOVO)

```dart
// Box: 'kills_permanentes'
// Chave: email
// Valor: JSON de KillsPermanentes
```

#### 2.3.4 Migração de Dados
**Arquivo:** `lib/features/aventura/services/migracao_kills_service.dart` (NOVO)

```dart
class MigracaoKillsService {
  // Executar na primeira vez que abrir o app após update
  // 1. Ler ProgressoDiario atual
  // 2. Somar todas as kills (ignorando datas)
  // 3. Salvar em KillsPermanentes
  // 4. Marcar migração como concluída

  Future<void> executarMigracao(String email);
  Future<bool> migracaoNecessaria(String email);
}
```

#### 2.3.5 Atualizar ProgressoDiario
**Arquivo:** `lib/features/aventura/models/progresso_diario.dart`

```dart
// REMOVER: limparKillsAntigos()
// REMOVER: lógica de expiração de 3 dias
// MANTER: estrutura para compatibilidade temporária
// ADICIONAR: flag 'migrado' para controle
```

### 2.4 Teste de Validação
- [ ] Kills antigas são migradas corretamente
- [ ] Novas kills são salvas como permanentes
- [ ] Kills não expiram após 3 dias
- [ ] Kills por tipo são contabilizadas corretamente
- [ ] Método de gastar kills funciona

---

## FASE 3: CONTROLE DE DISPOSITIVO
**Prioridade:** Alta
**Dependências:** Fase 1
**Estimativa de Complexidade:** Alta

### 3.1 Objetivos
- Jogador só pode logar em um dispositivo por dia
- Sistema detecta troca de dispositivo
- Bloqueio até próximo dia se trocar

### 3.2 Tarefas

#### 3.2.1 Criar Model de Dispositivo
**Arquivo:** `lib/features/dispositivo/models/dispositivo_info.dart` (NOVO)

```dart
class DispositivoInfo {
  final String dispositivoId;      // ID único do dispositivo
  final String plataforma;          // android/ios/windows
  final String modelo;              // Modelo do dispositivo
  final DateTime primeiroAcesso;    // Quando registrou

  Map<String, dynamic> toJson();
  factory DispositivoInfo.fromJson(Map<String, dynamic> json);
}

class ControleDispositivoDiario {
  final String email;
  final String dispositivoIdHoje;   // ID do dispositivo usado hoje
  final DateTime dataRegistro;      // Data do registro (só o dia)
  final bool bloqueado;             // Se está bloqueado por troca

  // Verifica se pode acessar com este dispositivo
  bool podeAcessar(String dispositivoId);

  // Verifica se é um novo dia
  bool ehNovoDia();
}
```

#### 3.2.2 Criar DispositivoService
**Arquivo:** `lib/features/dispositivo/services/dispositivo_service.dart` (NOVO)

```dart
class DispositivoService {
  // Gerar ID único do dispositivo
  Future<String> getDispositivoId();

  // Verificar se pode fazer login
  Future<ResultadoAcesso> verificarAcesso(String email);

  // Registrar acesso do dispositivo
  Future<void> registrarAcesso(String email, String dispositivoId);

  // Verificar se trocou de dispositivo
  Future<bool> trocouDispositivo(String email, String dispositivoId);

  // Obter informações do dispositivo
  Future<DispositivoInfo> getInfoDispositivo();
}

enum ResultadoAcesso {
  permitido,           // Pode acessar normalmente
  bloqueadoTroca,      // Trocou de dispositivo hoje
  novoDia,             // Novo dia, pode registrar
}
```

#### 3.2.3 Dependência para ID de Dispositivo
**Arquivo:** `pubspec.yaml`

```yaml
dependencies:
  device_info_plus: ^10.1.0  # Para obter ID único do dispositivo
```

#### 3.2.4 Salvar Controle no Drive
**Arquivo:** `lib/core/services/google_drive_service.dart`

```dart
// Adicionar pasta: TECHTERRA/dispositivos/
// Arquivo: {email}_dispositivo.json
// Conteúdo: ControleDispositivoDiario
```

#### 3.2.5 Integrar no Login (BLOQUEIO ANTES DE ENTRAR)
**Arquivo:** `lib/features/auth/presentation/login_screen.dart`

```dart
// FLUXO DE LOGIN COM VERIFICAÇÃO DE DISPOSITIVO:
//
// 1. Usuário digita email/senha
// 2. Firebase Auth valida credenciais
// 3. SE credenciais OK:
//    │
//    ├─ 4. IMEDIATAMENTE verificar dispositivo no Drive
//    │     DispositivoService.verificarAcesso(email)
//    │
//    ├─ 5a. SE bloqueadoTroca:
//    │      ├─ NÃO PERMITE ENTRAR NO APP
//    │      ├─ Mostra tela de bloqueio
//    │      ├─ Mensagem: "Você já acessou de outro dispositivo hoje"
//    │      ├─ Mostra tempo restante até meia-noite (Brasília)
//    │      └─ Único botão: [Fazer Logout]
//    │
//    └─ 5b. SE permitido ou novoDia:
//           ├─ Registra este dispositivo no Drive
//           ├─ Faz upload do relatório do dia anterior (background)
//           └─ Continua para a Home do app
```

#### 3.2.6 Criar Tela de Bloqueio
**Arquivo:** `lib/features/dispositivo/presentation/bloqueio_dispositivo_screen.dart` (NOVO)

```dart
// Tela de BLOQUEIO TOTAL (não permite navegar para nenhum lugar)
//
// Layout:
// ┌─────────────────────────────────────────────────────────────┐
// │                                                             │
// │              🔒 ACESSO BLOQUEADO                            │
// │                                                             │
// │   Você já acessou de outro dispositivo hoje.                │
// │                                                             │
// │   Dispositivo registrado: Samsung Galaxy S21                │
// │   Este dispositivo: iPhone 13                               │
// │                                                             │
// │   ┌─────────────────────────────────────────────────────┐   │
// │   │  Tempo restante para liberar:                       │   │
// │   │                                                     │   │
// │   │           ⏰ 05:32:15                               │   │
// │   │                                                     │   │
// │   │  (Liberação à meia-noite - horário de Brasília)     │   │
// │   └─────────────────────────────────────────────────────┘   │
// │                                                             │
// │                    [FAZER LOGOUT]                           │
// │                                                             │
// └─────────────────────────────────────────────────────────────┘
//
// IMPORTANTE: Esta tela NÃO tem navegação para outros lugares
// O usuário SÓ pode fazer logout e tentar em outro momento
```

### 3.3 Teste de Validação
- [ ] Primeiro acesso do dia registra dispositivo
- [ ] Segundo acesso do mesmo dispositivo funciona
- [ ] Acesso de dispositivo diferente no mesmo dia é bloqueado
- [ ] No dia seguinte, pode acessar de qualquer dispositivo
- [ ] Tela de bloqueio mostra informações corretas

---

## FASE 4: MODO UNLOCK
**Prioridade:** Alta
**Dependências:** Fases 1, 2, 3
**Estimativa de Complexidade:** Média

### 4.1 Objetivos
- Transformar modo atual em "Modo Unlock"
- Remover eventos deste modo
- Manter apenas desbloqueio de monstros e passivas
- Modo 100% automático

### 4.2 Tarefas

#### 4.2.1 Criar UnlockScreen
**Arquivo:** `lib/features/unlock/presentation/unlock_screen.dart` (NOVO)

```dart
// Reutilizar maior parte do mapa_aventura_screen.dart
// REMOVER:
// - Drops de evento (moedaEvento, moedaChave, ovoEvento)
// - Casa do Vigarista
// - NPCs de evento
//
// MANTER:
// - Sistema de batalha automático
// - Desbloqueio de monstros (colecoes)
// - Drop de passivas
// - Sistema de tiers
// - Itens e magias
```

#### 4.2.2 Criar UnlockService
**Arquivo:** `lib/features/unlock/services/unlock_service.dart` (NOVO)

```dart
class UnlockService {
  // Verificar se pode desbloquear monstro
  Future<bool> podeDesbloquearMonstro(String email, MonstroAventura monstro);

  // Desbloquear monstro
  Future<void> desbloquearMonstro(String email, MonstroAventura monstro);

  // Obter monstros desbloqueados
  Future<List<MonstroAventura>> getMonstrosDesbloqueados(String email);

  // Verificar passivas disponíveis
  Future<List<Passiva>> getPassivasDisponiveis(String email);
}
```

#### 4.2.3 Remover Eventos do Modo
**Arquivo:** `lib/features/unlock/services/unlock_recompensa_service.dart` (NOVO)

```dart
// Copiar RecompensaService mas REMOVER:
// - moedaEvento
// - moedaChave
// - ovoEvento
// - Qualquer drop relacionado a evento
```

#### 4.2.4 Atualizar RecompensaService Original
**Arquivo:** `lib/features/aventura/services/recompensa_service.dart`

```dart
// Adicionar parâmetro: GameMode mode
// Se mode == unlock -> Sem eventos
// Se mode == explorador -> Lógica diferente (fase posterior)
```

### 4.3 Teste de Validação
- [ ] Modo Unlock inicia corretamente
- [ ] Batalhas automáticas funcionam
- [ ] Monstros são desbloqueados ao vencer
- [ ] Passivas são obtidas normalmente
- [ ] NÃO aparecem drops de evento
- [ ] Kills são registradas como permanentes

---

## FASE 5: MODO EXPLORADOR - CORE
**Prioridade:** Alta
**Dependências:** Fases 1, 2
**Estimativa de Complexidade:** Alta

### 5.1 Objetivos
- Criar estrutura base do Modo Explorador
- Sistema de seleção de equipe (2 monstros por batalha)
- Sistema de banco (3 monstros reserva)

### 5.2 Tarefas

#### 5.2.1 Criar Model do Monstro Explorador
**Arquivo:** `lib/features/explorador/models/monstro_explorador.dart` (NOVO)

```dart
class MonstroExplorador {
  final MonstroAventura monstroBase;  // Referência ao monstro desbloqueado
  final Tipo tipoPrincipal;           // Apenas tipo principal conta

  // XP e Level (específico do explorador)
  final int xpAtual;                  // XP acumulado na run
  final int level;                    // Level atual
  final int xpParaProximoLevel;       // XP necessário para subir

  // Equipamentos (3 slots)
  final EquipamentoSlot? cabeca;
  final EquipamentoSlot? peito;
  final EquipamentoSlot? bracos;

  // Pontos de Bônus (distribuídos pelo jogador)
  final int bonusVidaProprio;         // +% vida para si
  final int bonusVidaTipagem;         // +% vida para tipagem
  final int bonusAtaqueProprio;
  final int bonusAtaqueTipagem;
  final int bonusDefesaProprio;
  final int bonusDefesaTipagem;
  final int pontosDisponiveis;        // Pontos para distribuir

  // Estado na run
  final bool desmaiado;               // Se morreu na run
  final int energiaRestante;          // Energia para lutas hoje
  final bool usadoHoje;               // Se já foi usado em batalha hoje

  // Habilidades (começa com 1 de ataque)
  final List<Habilidade> habilidades; // Sempre começa com 1 skill de dano

  // Getters calculados
  int get vidaTotal;      // Base + equipamentos + bônus
  int get ataqueTotal;
  int get defesaTotal;
  int get agilidadeTotal;
  int get energiaMaxima;  // Determina quantas lutas por dia
  int get custoEnergia => level;  // Gasta 1 energia por level

  // Métodos
  MonstroExplorador ganharXP(int quantidade);
  MonstroExplorador subirLevel();
  MonstroExplorador distribuirPonto(String atributo, bool paraTipagem);
  MonstroExplorador equipar(EquipamentoSlot equipamento);
  MonstroExplorador desmaiar(); // Perde XP, marca como desmaiado
  MonstroExplorador resetarParaNovoDia();
}
```

#### 5.2.2 Criar Model de Sessão do Explorador
**Arquivo:** `lib/features/explorador/models/sessao_explorador.dart` (NOVO)

```dart
class SessaoExplorador {
  final String email;
  final DateTime dataInicio;
  final String sessaoId;

  // Equipe ativa (2 monstros em batalha)
  final List<MonstroExplorador> equipeAtiva;  // Max 2

  // Banco (3 monstros que recebem XP extra)
  final List<MonstroExplorador> banco;        // Max 3

  // Progresso da sessão
  final int tierAtual;
  final int batalhasNoMapaAtual;              // 0-3
  final String? mapaAtual;
  final List<MapaOpcao> opcoesMapaDisponiveis;

  // Histórico
  final Map<Tipo, int> killsNaSessao;         // Kills ganhas nesta run
  final List<RegistroBatalha> historicoBatalhas;

  // Estado
  final bool emAndamento;
  final DateTime? dataFim;

  // Métodos
  SessaoExplorador iniciarBatalha();
  SessaoExplorador finalizarBatalha(RegistroBatalha resultado);
  SessaoExplorador selecionarMapa(MapaOpcao mapa);
  SessaoExplorador trocarMonstroAtivo(int index, MonstroExplorador novo);
  SessaoExplorador desistir(); // Perde todo XP
  SessaoExplorador finalizarRun();
}
```

#### 5.2.3 Criar ExploradorService
**Arquivo:** `lib/features/explorador/services/explorador_service.dart` (NOVO)

```dart
class ExploradorService {
  // Iniciar nova sessão
  Future<SessaoExplorador> iniciarSessao(String email);

  // Carregar sessão existente
  Future<SessaoExplorador?> carregarSessao(String email);

  // Salvar sessão
  Future<void> salvarSessao(SessaoExplorador sessao);

  // Obter monstros disponíveis (desbloqueados no Unlock)
  Future<List<MonstroExplorador>> getMonstrosDisponiveis(String email);

  // Selecionar equipe
  Future<SessaoExplorador> selecionarEquipe(
    String email,
    List<MonstroExplorador> equipeAtiva,
    List<MonstroExplorador> banco,
  );

  // Processar resultado de batalha
  Future<SessaoExplorador> processarBatalha(
    SessaoExplorador sessao,
    RegistroBatalha resultado,
  );

  // Distribuir XP para banco (sorte)
  Future<void> distribuirXPBanco(SessaoExplorador sessao, int xpExtra);

  // Finalizar sessão
  Future<ResumoRun> finalizarSessao(SessaoExplorador sessao);
}
```

#### 5.2.4 Criar Tela de Seleção de Equipe
**Arquivo:** `lib/features/explorador/presentation/selecao_equipe_screen.dart` (NOVO)

```dart
// Layout:
// ┌─────────────────────────────────────┐
// │  SELECIONE SUA EQUIPE               │
// ├─────────────────────────────────────┤
// │  EQUIPE ATIVA (2 monstros)          │
// │  [Slot 1: ___] [Slot 2: ___]        │
// ├─────────────────────────────────────┤
// │  BANCO (3 monstros - recebem XP)    │
// │  [Slot 1] [Slot 2] [Slot 3]         │
// ├─────────────────────────────────────┤
// │  MONSTROS DISPONÍVEIS               │
// │  (Grid scrollable com filtro por    │
// │   tipo principal)                   │
// ├─────────────────────────────────────┤
// │  [INICIAR EXPEDIÇÃO]                │
// └─────────────────────────────────────┘
```

### 5.3 Teste de Validação
- [ ] Tela de seleção de equipe carrega monstros desbloqueados
- [ ] Pode selecionar exatamente 2 monstros para equipe ativa
- [ ] Pode selecionar até 3 monstros para banco
- [ ] Monstro desmaiado não aparece como disponível
- [ ] Filtro por tipo funciona
- [ ] Sessão é criada ao iniciar expedição

---

## FASE 6: SISTEMA DE MAPAS E BATALHAS
**Prioridade:** Alta
**Dependências:** Fase 5
**Estimativa de Complexidade:** Alta

### 6.1 Objetivos
- Criar sistema de seleção de mapas
- 3 batalhas por mapa
- Mapas com chances de subir/descer/manter tier
- Cada mapa tem monstros específicos

### 6.2 Tarefas

#### 6.2.1 Criar Model de Mapa
**Arquivo:** `lib/features/explorador/models/mapa_explorador.dart` (NOVO)

```dart
class MapaExplorador {
  final String id;
  final String nome;
  final String imagemPath;
  final List<Tipo> tiposDisponiveis;    // Tipos de monstros neste mapa
  final int tierMinimo;                  // Tier mínimo para aparecer
  final int tierMaximo;                  // Tier máximo para aparecer

  // Chances de transição de tier após completar
  final double chanceSubir;              // % de subir tier
  final double chanceDescer;             // % de descer tier
  final double chanceManter;             // % de manter tier

  // Tipo de mapa
  final TipoMapa tipo;                   // normal, loja, boss, evento

  // Recompensas especiais
  final bool temLoja;                    // Se tem loja após batalhas
  final double multiplicadorXP;          // Bonus de XP neste mapa
}

enum TipoMapa {
  normal,     // Mapa comum
  loja,       // Mapa com loja no final
  desafio,    // Mapa mais difícil, mais recompensas
  descanso,   // Mapa para recuperar energia
}

class MapaOpcao {
  final MapaExplorador mapa;
  final int tierResultante;  // Tier que vai ficar após escolher
  final String descricao;    // "Subir para Tier 5", "Manter Tier 4"
}
```

#### 6.2.2 Criar Configuração de Mapas
**Arquivo:** `lib/features/explorador/config/mapas_config.dart` (NOVO)

```dart
class MapasConfig {
  static List<MapaExplorador> get todosMapas => [
    MapaExplorador(
      id: 'floresta_verde',
      nome: 'Floresta Verde',
      imagemPath: 'assets/mapas_aventura/floresta_verde.jpg',
      tiposDisponiveis: [Tipo.grama, Tipo.inseto, Tipo.normal],
      tierMinimo: 1,
      tierMaximo: 10,
      chanceSubir: 0.4,
      chanceDescer: 0.1,
      chanceManter: 0.5,
      tipo: TipoMapa.normal,
      temLoja: false,
      multiplicadorXP: 1.0,
    ),
    // ... outros mapas
  ];

  // Gerar 3 opções de mapa baseado no tier atual
  static List<MapaOpcao> gerarOpcoes(int tierAtual, Random random);
}
```

#### 6.2.3 Criar Tela de Seleção de Mapa
**Arquivo:** `lib/features/explorador/presentation/selecao_mapa_screen.dart` (NOVO)

```dart
// Layout:
// ┌─────────────────────────────────────┐
// │  ESCOLHA SEU DESTINO                │
// │  Tier Atual: 5                      │
// ├─────────────────────────────────────┤
// │  ┌─────────┐ ┌─────────┐ ┌─────────┐│
// │  │ Floresta│ │ Vulcão  │ │ Loja    ││
// │  │ Tier 5  │ │ Tier 6↑ │ │ Tier 4↓ ││
// │  │ Normal  │ │ Desafio │ │ Compras ││
// │  └─────────┘ └─────────┘ └─────────┘│
// ├─────────────────────────────────────┤
// │  (Descrição do mapa selecionado)    │
// │  Tipos: Fogo, Terra, Dragão         │
// │  Dificuldade: ★★★☆☆                │
// └─────────────────────────────────────┘
```

#### 6.2.4 Criar Tela de Batalha do Explorador
**Arquivo:** `lib/features/explorador/presentation/batalha_explorador_screen.dart` (NOVO)

```dart
// REUTILIZAR: BatalhaService do aventura (lógica pura)
//
// Diferenças do modo unlock:
// - 2 monstros vs inimigos (não 3)
// - Jogador ESCOLHE ações (não automático)
// - Após cada batalha: tela de resultado com XP
// - 3 batalhas por mapa
// - Contador de batalhas visível
//
// Layout:
// ┌─────────────────────────────────────┐
// │  BATALHA 2/3 - Floresta Verde       │
// ├─────────────────────────────────────┤
// │         [INIMIGO]                   │
// │         HP: ████████░░              │
// ├─────────────────────────────────────┤
// │  [Monstro 1]     [Monstro 2]        │
// │  HP: ██████      HP: ████████       │
// │  EN: ███         EN: █████          │
// ├─────────────────────────────────────┤
// │  AÇÕES:                             │
// │  [Skill 1] [Skill 2] [Defender]     │
// │  [Trocar] [Fugir (perde XP)]        │
// └─────────────────────────────────────┘
```

#### 6.2.5 Atualizar BatalhaService para Explorador
**Arquivo:** `lib/features/aventura/services/batalha_service.dart`

```dart
// Adicionar método:
Future<RegistroBatalha> executarBatalhaExplorador(
  List<MonstroExplorador> equipe,  // 2 monstros
  MonstroInimigo inimigo,
  AcaoJogador acao,                // Ação escolhida pelo jogador
);

// Adicionar suporte a:
// - Batalha por turnos com input do jogador
// - 2 monstros atacando/defendendo
// - Sistema de troca durante batalha
```

### 6.3 Teste de Validação
- [ ] 3 opções de mapa são geradas após completar mapa
- [ ] Tier muda corretamente baseado na escolha
- [ ] Batalhas funcionam com 2 monstros
- [ ] Jogador escolhe ações (não automático)
- [ ] Contador de batalhas funciona (1/3, 2/3, 3/3)
- [ ] Após 3 batalhas, mostra seleção de novo mapa

---

## FASE 7: SISTEMA DE XP E EVOLUÇÃO
**Prioridade:** Alta
**Dependências:** Fases 5, 6
**Estimativa de Complexidade:** Alta

### 7.1 Objetivos
- XP permanente durante a run
- XP perdido se monstro morrer
- Pontos de bônus ao subir de level
- XP é do dispositivo (não sincroniza)

### 7.2 Regras do Sistema de XP

#### 7.2.1 XP Necessário por Level (Progressão Exponencial)

| Level | XP Necessário | Fórmula |
|-------|---------------|---------|
| 1 | 50 | 50 × 2^0 |
| 2 | 100 | 50 × 2^1 |
| 3 | 200 | 50 × 2^2 |
| 4 | 400 | 50 × 2^3 |
| 5 | 800 | 50 × 2^4 |
| N | 50 × 2^(N-1) | Dobra a cada level |

**Fórmula:** `xpNecessario = 50 * pow(2, level - 1)`

#### 7.2.2 XP Ganho por Batalha

**Regra:** XP ganho = Level do inimigo derrotado

| Level Inimigo | XP Ganho |
|---------------|----------|
| Level 1 | 1 XP |
| Level 4 | 4 XP |
| Level 10 | 10 XP |

#### 7.2.3 Distribuição do XP (Por Sorte)

Quando um inimigo é derrotado, o XP é distribuído assim:

```
Inimigo Level 4 derrotado = 8 XP total distribuído

┌─────────────────────────────────────────────────────┐
│  EQUIPE ATIVA (2 monstros)                          │
│  ┌─────────┐  ┌─────────┐                           │
│  │Monstro A│  │Monstro B│                           │
│  └────┬────┘  └─────────┘                           │
│       │                                             │
│       ▼ SORTEIO: 1 dos 2 recebe                     │
│    +4 XP                                            │
├─────────────────────────────────────────────────────┤
│  BANCO (3 monstros)                                 │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐              │
│  │Monstro C│  │Monstro D│  │Monstro E│              │
│  └─────────┘  └────┬────┘  └─────────┘              │
│                    │                                │
│                    ▼ SORTEIO: 1 dos 3 recebe        │
│                 +4 XP                               │
└─────────────────────────────────────────────────────┘
```

**Resumo:**
- 1 monstro ativo (sorteado entre os 2) recebe o XP
- 1 monstro do banco (sorteado entre os 3) recebe o MESMO XP
- Total: XP × 2 (dividido entre ativo e banco)

### 7.3 Tarefas

#### 7.3.1 Criar XPService
**Arquivo:** `lib/features/explorador/services/xp_service.dart` (NOVO)

```dart
class XPService {
  // Configurações de XP
  static const int XP_BASE_LEVEL_1 = 50;

  /// Calcula XP necessário para o próximo level
  /// Fórmula: 50 * 2^(level-1)
  /// Level 1: 50, Level 2: 100, Level 3: 200, etc
  int calcularXPParaLevel(int level) {
    return XP_BASE_LEVEL_1 * pow(2, level - 1).toInt();
  }

  /// Calcula XP ganho ao derrotar um inimigo
  /// XP = level do inimigo
  int calcularXPGanho(MonstroInimigo inimigo) {
    return inimigo.level;
  }

  /// Distribui XP após vitória
  /// Retorna os monstros atualizados (1 ativo + 1 banco)
  DistribuicaoXP distribuirXP(
    List<MonstroExplorador> equipeAtiva,  // 2 monstros
    List<MonstroExplorador> banco,         // 3 monstros
    int xpGanho,                           // Level do inimigo
    Random random,
  ) {
    // Sorteia 1 dos ativos
    final indexAtivo = random.nextInt(equipeAtiva.length);
    final monstroAtivoAtualizado = equipeAtiva[indexAtivo].adicionarXP(xpGanho);

    // Sorteia 1 do banco
    final indexBanco = random.nextInt(banco.length);
    final monstroBancoAtualizado = banco[indexBanco].adicionarXP(xpGanho);

    return DistribuicaoXP(
      monstroAtivoIndex: indexAtivo,
      monstroAtivoXP: xpGanho,
      monstroBancoIndex: indexBanco,
      monstroBancoXP: xpGanho,
    );
  }

  /// Verifica se monstro pode subir de level
  bool podeSubirLevel(MonstroExplorador monstro) {
    final xpNecessario = calcularXPParaLevel(monstro.level);
    return monstro.xpAtual >= xpNecessario;
  }

  /// Sobe o level do monstro e retorna pontos de bônus ganhos
  MonstroExplorador subirLevel(MonstroExplorador monstro) {
    final xpNecessario = calcularXPParaLevel(monstro.level);
    return monstro.copyWith(
      level: monstro.level + 1,
      xpAtual: monstro.xpAtual - xpNecessario, // Sobra vai pro próximo
      pontosDisponiveis: monstro.pontosDisponiveis + 1, // +1 ponto por level
    );
  }
}

class DistribuicaoXP {
  final int monstroAtivoIndex;
  final int monstroAtivoXP;
  final int monstroBancoIndex;
  final int monstroBancoXP;

  const DistribuicaoXP({
    required this.monstroAtivoIndex,
    required this.monstroAtivoXP,
    required this.monstroBancoIndex,
    required this.monstroBancoXP,
  });
}
```

#### 7.2.2 Criar Sistema de Pontos de Bônus
**Arquivo:** `lib/features/explorador/services/bonus_service.dart` (NOVO)

```dart
class BonusService {
  // Tipos de bônus disponíveis
  static const Map<String, BonusInfo> bonusDisponiveis = {
    'vida_proprio': BonusInfo(
      nome: 'Vida (Próprio)',
      descricao: '+5% vida para este monstro',
      valorPorPonto: 5,
      paraTipagem: false,
    ),
    'vida_tipagem': BonusInfo(
      nome: 'Vida (Tipagem)',
      descricao: '+2% vida para monstros da mesma tipagem',
      valorPorPonto: 2,
      paraTipagem: true,
    ),
    // ... outros bônus
  };

  // Aplicar ponto de bônus
  MonstroExplorador aplicarBonus(
    MonstroExplorador monstro,
    String tipoBonus,
  );

  // Calcular stats finais com bônus
  StatsCalculados calcularStatsComBonus(
    MonstroExplorador monstro,
    List<MonstroExplorador> todosDoTime,
  );
}

class BonusInfo {
  final String nome;
  final String descricao;
  final int valorPorPonto;
  final bool paraTipagem;  // Se afeta outros da tipagem
}
```

#### 7.2.3 Criar Tela de Distribuição de Pontos
**Arquivo:** `lib/features/explorador/presentation/distribuir_pontos_screen.dart` (NOVO)

```dart
// Layout:
// ┌─────────────────────────────────────┐
// │  LEVEL UP! 🎉                       │
// │  [Monstro] subiu para Level 5       │
// │  Pontos disponíveis: 3              │
// ├─────────────────────────────────────┤
// │  BÔNUS PRÓPRIOS:                    │
// │  Vida:    [■■■□□] +15% [+]          │
// │  Ataque:  [■□□□□] +5%  [+]          │
// │  Defesa:  [□□□□□] +0%  [+]          │
// ├─────────────────────────────────────┤
// │  BÔNUS TIPAGEM (Fogo):              │
// │  Vida:    [■□□□□] +2%  [+]          │
// │  Ataque:  [□□□□□] +0%  [+]          │
// ├─────────────────────────────────────┤
// │  [CONFIRMAR]                        │
// └─────────────────────────────────────┘
```

#### 7.2.4 Armazenamento Local de XP
**Arquivo:** `lib/features/explorador/services/xp_local_service.dart` (NOVO)

```dart
class XPLocalService {
  // XP é armazenado APENAS localmente
  // Não sincroniza com Drive
  // Perde ao trocar dispositivo

  Future<Map<String, int>> carregarXPLocal(String email);
  Future<void> salvarXPLocal(String email, Map<String, int> xpPorMonstro);
  Future<void> limparXPLocal(String email);
}
```

### 7.3 Teste de Validação
- [ ] XP é ganho após vitória
- [ ] XP é calculado corretamente (tier, level inimigo)
- [ ] Level sobe quando XP suficiente
- [ ] Pontos de bônus são ganhos ao subir level
- [ ] Pontos podem ser distribuídos
- [ ] Bônus de tipagem afeta outros monstros
- [ ] XP é perdido se monstro morrer
- [ ] XP não sincroniza entre dispositivos

---

## FASE 8: SISTEMA DE EQUIPAMENTOS (3 SLOTS)
**Prioridade:** Média
**Dependências:** Fase 5
**Estimativa de Complexidade:** Média

### 8.1 Objetivos
- 3 slots de equipamento por monstro (cabeça, peito, braços)
- Itens têm durabilidade
- Itens são específicos por tipagem (comprados com kills)

### 8.2 Tarefas

#### 8.2.1 Criar Model de Slot de Equipamento
**Arquivo:** `lib/features/explorador/models/equipamento_slot.dart` (NOVO)

```dart
enum SlotTipo {
  cabeca,  // Capacetes, coroas, etc
  peito,   // Armaduras, peitorais, etc
  bracos,  // Braceletes, luvas, etc
}

class EquipamentoSlot {
  final String id;
  final String nome;
  final SlotTipo slot;
  final Tipo tipagem;            // Tipo do monstro que pode usar
  final RaridadeItem raridade;

  // Atributos
  final int vida;
  final int ataque;
  final int defesa;
  final int agilidade;
  final int energia;

  // Durabilidade
  final int durabilidadeMaxima;  // Quantas lutas aguenta
  final int durabilidadeAtual;   // Lutas restantes

  // Tier
  final int tierObtido;          // Tier em que foi obtido

  // Métodos
  EquipamentoSlot usarEmBatalha(); // Reduz durabilidade
  bool get quebrado => durabilidadeAtual <= 0;

  // Serialização
  Map<String, dynamic> toJson();
  factory EquipamentoSlot.fromJson(Map<String, dynamic> json);
}
```

#### 8.2.2 Criar EquipamentoService
**Arquivo:** `lib/features/explorador/services/equipamento_service.dart` (NOVO)

```dart
class EquipamentoService {
  // Gerar equipamento aleatório
  EquipamentoSlot gerarEquipamento(
    SlotTipo slot,
    Tipo tipagem,
    int tier,
    bool isLoja,  // Loja = melhor qualidade
  );

  // Calcular durabilidade base
  int calcularDurabilidade(RaridadeItem raridade, int tier);

  // Equipar item em monstro
  MonstroExplorador equiparItem(
    MonstroExplorador monstro,
    EquipamentoSlot item,
  );

  // Desequipar item
  MonstroExplorador desequiparItem(
    MonstroExplorador monstro,
    SlotTipo slot,
  );

  // Verificar compatibilidade
  bool podeEquipar(MonstroExplorador monstro, EquipamentoSlot item);
}
```

#### 8.2.3 Atualizar Gerador de Nomes
**Arquivo:** `lib/features/aventura/utils/gerador_nomes_itens.dart`

```dart
// Adicionar nomes para cada slot:
// Cabeça: Elmo, Capacete, Coroa, Tiara, Capuz, etc
// Peito: Armadura, Peitoral, Couraça, Manto, Veste, etc
// Braços: Bracelete, Luva, Manopla, Algema, Punho, etc
```

#### 8.2.4 Criar Modal de Detalhes do Monstro (com 3 Equipamentos)
**Arquivo:** `lib/features/explorador/presentation/modal_detalhe_monstro_explorador.dart` (NOVO)

**REFERÊNCIA:** Usar como base o modal do modo aventura:
- `lib/features/aventura/presentation/modal_detalhe_item_equipado.dart`

**Adaptações para o Modo Explorador:**
- Cores do tema explorador (teal/amber ao invés de cores claras)
- Fundo escuro (grey.shade900) ao invés de gradiente claro
- Mostrar os 3 slots de equipamento (cabeça, peito, braços)
- Mostrar XP e level do monstro
- Mostrar stats base + bônus de equipamentos
- Durabilidade de cada equipamento

```dart
// Layout:
// ┌─────────────────────────────────────┐
// │  [Imagem]  NOME DO MONSTRO          │
// │            Tipo: Fogo  Lv.5         │
// │            XP: ████████░░ 80/100    │
// ├─────────────────────────────────────┤
// │  STATS:                             │
// │  ❤️ Vida: 120 (+20)                 │
// │  ⚔️ Ataque: 45 (+10)                │
// │  🛡️ Defesa: 60 (+15)                │
// │  ⚡ Agilidade: 30 (+5)              │
// ├─────────────────────────────────────┤
// │  EQUIPAMENTOS (3 slots):            │
// │  ┌──────┐  [Elmo de Fogo]           │
// │  │Cabeça│  +10 Vida, +5 Defesa      │
// │  └──────┘  Durabilidade: 8/10       │
// │  ┌──────┐  [Armadura Flamejante]    │
// │  │Peito │  +20 Vida, +10 Defesa     │
// │  └──────┘  Durabilidade: 5/15       │
// │  ┌──────┐  (Vazio)                  │
// │  │Braços│  [Equipar]                │
// │  └──────┘                           │
// ├─────────────────────────────────────┤
// │  [MOVER] [REMOVER] [FECHAR]         │
// └─────────────────────────────────────┘
```

### 8.3 Teste de Validação
- [ ] 3 slots funcionam independentemente
- [ ] Equipamento só pode ser usado por tipagem correta
- [ ] Durabilidade diminui a cada batalha
- [ ] Item quebrado é removido automaticamente
- [ ] Stats do monstro atualizam com equipamentos

---

## FASE 9: SISTEMA DE LOJAS
**Prioridade:** Média
**Dependências:** Fases 2, 8
**Estimativa de Complexidade:** Média

### 9.1 Objetivos
- Lojas vendem itens por tipagem específica
- Preço em kills do tipo correspondente
- Memória de tier (não vende acima do tier)
- Botão de refresh (paga kills)

### 9.2 Tarefas

#### 9.2.1 Criar Model de Loja
**Arquivo:** `lib/features/explorador/models/loja_explorador.dart` (NOVO)

```dart
class LojaExplorador {
  final String id;
  final int tierMaximo;           // Tier máximo dos itens
  final List<ItemLoja> itens;     // Itens disponíveis
  final DateTime geradaEm;
  final int refreshsUsados;

  // Métodos
  LojaExplorador refresh(int tierAtual);
  LojaExplorador comprarItem(String itemId);
}

class ItemLoja {
  final EquipamentoSlot equipamento;
  final int preco;                // Em kills
  final Tipo tipagemPreco;        // Tipo de kill usado
  final bool vendido;             // Se já foi comprado

  // Preço sempre em kills do mesmo tipo do item
  // Exemplo: Elmo de Fogo custa kills de Fogo
}
```

#### 9.2.2 Criar LojaService
**Arquivo:** `lib/features/explorador/services/loja_service.dart` (NOVO)

```dart
class LojaService {
  // Gerar loja para o tier atual
  LojaExplorador gerarLoja(int tierAtual);

  // Gerar itens da loja
  List<ItemLoja> gerarItensLoja(int tierMaximo, int quantidade);

  // Calcular preço do item
  int calcularPreco(EquipamentoSlot item, int tier);

  // Refresh da loja
  LojaExplorador refreshLoja(LojaExplorador loja, int tierAtual);

  // Calcular custo do refresh
  int calcularCustoRefresh(int refreshsUsados);

  // Comprar item
  Future<ResultadoCompra> comprarItem(
    String email,
    LojaExplorador loja,
    String itemId,
    KillsPermanentes kills,
  );
}

class ResultadoCompra {
  final bool sucesso;
  final String? erro;
  final EquipamentoSlot? itemComprado;
  final KillsPermanentes? killsAtualizadas;
}
```

#### 9.2.3 Criar Tela de Loja
**Arquivo:** `lib/features/explorador/presentation/loja_explorador_screen.dart` (NOVO)

```dart
// Layout:
// ┌─────────────────────────────────────┐
// │  LOJA - Tier 5                      │
// │  [Refresh: 50 kills] 🔄             │
// ├─────────────────────────────────────┤
// │  ┌─────────────────────────────────┐│
// │  │ Elmo de Fogo (Cabeça)           ││
// │  │ +15 Vida, +8 Defesa             ││
// │  │ Durabilidade: 12                ││
// │  │ 💀 150 kills Fogo   [COMPRAR]   ││
// │  └─────────────────────────────────┘│
// │  ┌─────────────────────────────────┐│
// │  │ Bracelete de Água (Braços)      ││
// │  │ +10 Ataque, +5 Agilidade        ││
// │  │ Durabilidade: 8                 ││
// │  │ 💀 120 kills Água   [COMPRAR]   ││
// │  └─────────────────────────────────┘│
// │  ...                                │
// ├─────────────────────────────────────┤
// │  Suas Kills:                        │
// │  🔥 Fogo: 234  💧 Água: 156         │
// └─────────────────────────────────────┘
```

### 9.3 Teste de Validação
- [ ] Loja gera itens do tier correto
- [ ] Preços são em kills do tipo do item
- [ ] Compra desconta kills corretamente
- [ ] Refresh funciona e cobra kills
- [ ] Itens vendidos não aparecem mais
- [ ] Loja persiste ao sair e voltar

---

## FASE 10: SISTEMA DE ENERGIA E DURABILIDADE
**Prioridade:** Média
**Dependências:** Fases 5, 8
**Estimativa de Complexidade:** Média

### 10.1 Objetivos
- Energia limita batalhas por dia
- Custo de energia = level do monstro
- Durabilidade dos itens diminui por batalha

### 10.2 Tarefas

#### 10.2.1 Criar EnergiaService
**Arquivo:** `lib/features/explorador/services/energia_service.dart` (NOVO)

```dart
class EnergiaService {
  // Configurações
  static const int ENERGIA_BASE = 10;
  static const int ENERGIA_POR_LEVEL = 2;

  // Calcular energia máxima
  int calcularEnergiaMaxima(MonstroExplorador monstro);

  // Calcular custo de uma batalha
  int calcularCustoBatalha(MonstroExplorador monstro);
  // Custo = level do monstro (level 5 = 5 energia)

  // Verificar se pode batalhar
  bool podeBatalhar(MonstroExplorador monstro);

  // Consumir energia
  MonstroExplorador consumirEnergia(MonstroExplorador monstro);

  // Resetar energia (novo dia)
  MonstroExplorador resetarEnergia(MonstroExplorador monstro);

  // Calcular batalhas restantes
  int batalhasRestantes(MonstroExplorador monstro);
}
```

#### 10.2.2 Criar DurabilidadeService
**Arquivo:** `lib/features/explorador/services/durabilidade_service.dart` (NOVO)

```dart
class DurabilidadeService {
  // Configurações de durabilidade por raridade
  static const Map<RaridadeItem, int> DURABILIDADE_BASE = {
    RaridadeItem.inferior: 5,
    RaridadeItem.normal: 10,
    RaridadeItem.raro: 15,
    RaridadeItem.epico: 20,
    RaridadeItem.lendario: 30,
    RaridadeItem.impossivel: 50,
  };

  // Reduzir durabilidade após batalha
  MonstroExplorador reduzirDurabilidade(MonstroExplorador monstro);

  // Verificar itens quebrados
  List<EquipamentoSlot> verificarItensQuebrados(MonstroExplorador monstro);

  // Remover itens quebrados
  MonstroExplorador removerItensQuebrados(MonstroExplorador monstro);

  // Reparar item (se implementar sistema de reparo)
  EquipamentoSlot repararItem(EquipamentoSlot item, int quantidade);
}
```

#### 10.2.3 Integrar no Fluxo de Batalha
**Arquivo:** `lib/features/explorador/presentation/batalha_explorador_screen.dart`

```dart
// Antes da batalha:
// 1. Verificar energia suficiente
// 2. Se não tiver, mostrar aviso
// 3. Permitir trocar por monstro com energia

// Após a batalha:
// 1. Consumir energia
// 2. Reduzir durabilidade dos equipamentos
// 3. Verificar itens quebrados
// 4. Notificar jogador se item quebrou
```

### 10.3 Teste de Validação
- [ ] Energia limita batalhas corretamente
- [ ] Custo de energia = level do monstro
- [ ] Monstro sem energia não pode batalhar
- [ ] Durabilidade diminui a cada batalha
- [ ] Item quebrado é removido
- [ ] Energia reseta no novo dia

---

## FASE 11: DROPS E RECOMPENSAS
**Prioridade:** Média
**Dependências:** Fases 5, 6
**Estimativa de Complexidade:** Média

### 11.1 Objetivos
- Drops: Caixinhas, cartas de evento
- Caixinhas dão monstros ou itens exclusivos
- Cartas são para eventos especiais
- Habilidades e itens são COMPRADOS, não dropados

### 11.2 Tarefas

#### 11.2.1 Criar Model de Caixinha
**Arquivo:** `lib/features/explorador/models/caixinha_drop.dart` (NOVO)

```dart
enum TipoCaixinha {
  monstro,     // Contém monstro exclusivo
  equipamento, // Contém equipamento especial
  mista,       // Pode ser qualquer coisa
}

class CaixinhaDrop {
  final String id;
  final String nome;
  final TipoCaixinha tipo;
  final RaridadeItem raridade;
  final String descricao;
  final String iconPath;

  // Conteúdo (revelado ao abrir)
  final ConteudoCaixinha? conteudo;
  final bool aberta;

  // Compartilhamento
  String gerarTextoCompartilhamento();
}

class ConteudoCaixinha {
  final TipoConteudo tipo;
  final MonstroAventura? monstro;
  final EquipamentoSlot? equipamento;
  final int? quantidade;
}
```

#### 11.2.2 Criar DropExploradorService
**Arquivo:** `lib/features/explorador/services/drop_explorador_service.dart` (NOVO)

```dart
class DropExploradorService {
  // Chances de drop
  static const double CHANCE_CAIXINHA = 0.05;      // 5% por batalha
  static const double CHANCE_CARTA_EVENTO = 0.02; // 2% por batalha

  // Gerar drops após batalha
  List<DropRecompensa> gerarDrops(
    int tier,
    bool vitoria,
    bool eventoAtivo,
  );

  // Abrir caixinha
  ConteudoCaixinha abrirCaixinha(CaixinhaDrop caixinha);

  // Gerar conteúdo da caixinha
  ConteudoCaixinha gerarConteudoCaixinha(
    TipoCaixinha tipo,
    RaridadeItem raridade,
    int tier,
  );
}
```

#### 11.2.3 Criar Tela de Recompensas
**Arquivo:** `lib/features/explorador/presentation/recompensas_screen.dart` (NOVO)

```dart
// Layout após batalha:
// ┌─────────────────────────────────────┐
// │  VITÓRIA! 🎉                        │
// ├─────────────────────────────────────┤
// │  XP Ganho: +25                      │
// │  Kills Ganhas: +1 Fogo              │
// ├─────────────────────────────────────┤
// │  DROPS:                             │
// │  ┌─────────────────────────────────┐│
// │  │ 📦 Caixinha Rara               ││
// │  │ [ABRIR] [GUARDAR]              ││
// │  └─────────────────────────────────┘│
// ├─────────────────────────────────────┤
// │  [CONTINUAR]                        │
// └─────────────────────────────────────┘
```

### 11.3 Teste de Validação
- [ ] Caixinhas dropam com chance correta
- [ ] Caixinhas podem ser abertas
- [ ] Conteúdo é revelado corretamente
- [ ] Cartas de evento só dropam se evento ativo
- [ ] Compartilhamento funciona

---

## FASE 12: POLIMENTO E ÁUDIO
**Prioridade:** Baixa
**Dependências:** Todas as fases anteriores
**Estimativa de Complexidade:** Média

### 12.1 Objetivos
- Adicionar músicas ao jogo
- Música de lobby, batalha, vitória, derrota
- Efeitos sonoros

### 12.2 Fontes de Músicas Gratuitas (Royalty-Free)

#### 12.2.1 Sites Recomendados

| Site | URL | Licença | Tipo |
|------|-----|---------|------|
| **OpenGameArt** | https://opengameart.org/content/rpg-battle-music | CC0/CC-BY | Músicas de batalha RPG |
| **FreePD** | https://freepd.com/ | Domínio Público | Músicas diversas |
| **Incompetech** | https://incompetech.com/music/ | CC-BY 3.0 | Kevin MacLeod |
| **Pixabay Music** | https://pixabay.com/music/ | Pixabay License | Músicas gratuitas |
| **Free Music Archive** | https://freemusicarchive.org/ | Várias CC | Músicas diversas |

#### 12.2.2 Músicas Sugeridas

**Lobby/Menu:**
- Estilo: Calmo, RPG medieval
- Sugestão: "Tavern Loop" (OpenGameArt) ou similar
- Duração: 1-2 minutos (loop)

**Batalha Normal:**
- Estilo: Intenso, ação
- Sugestão: "Battle Theme" (OpenGameArt)
- Duração: 1-2 minutos (loop)

**Batalha Boss/Elite:**
- Estilo: Épico, intenso
- Sugestão: "Boss Battle" (Incompetech)
- Duração: 2-3 minutos (loop)

**Vitória:**
- Estilo: Triunfante, curto
- Duração: 5-10 segundos

**Derrota:**
- Estilo: Melancólico, curto
- Duração: 5-10 segundos

### 12.3 Tarefas

#### 12.3.1 Adicionar Dependência de Áudio
**Arquivo:** `pubspec.yaml`

```yaml
dependencies:
  just_audio: ^0.9.36        # Player de áudio
  audio_session: ^0.1.18     # Gerenciamento de sessão
```

#### 12.3.2 Criar AudioService
**Arquivo:** `lib/core/services/audio_service.dart` (NOVO)

```dart
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  double _musicVolume = 0.5;
  double _sfxVolume = 0.7;

  // Músicas
  Future<void> playLobbyMusic();
  Future<void> playBattleMusic();
  Future<void> playBossBattleMusic();
  Future<void> playVictoryMusic();
  Future<void> playDefeatMusic();
  Future<void> stopMusic();
  Future<void> fadeOutMusic();

  // Efeitos sonoros
  Future<void> playSFX(String sfxName);
  // attack, hit, critical, heal, levelup, buy, etc

  // Configurações
  void setMusicEnabled(bool enabled);
  void setSFXEnabled(bool enabled);
  void setMusicVolume(double volume);
  void setSFXVolume(double volume);

  // Persistência
  Future<void> loadSettings();
  Future<void> saveSettings();
}
```

#### 12.3.3 Baixar e Organizar Músicas
**Pasta:** `assets/audio/`

```
assets/audio/
├── music/
│   ├── lobby_theme.mp3
│   ├── battle_normal.mp3
│   ├── battle_boss.mp3
│   ├── victory.mp3
│   └── defeat.mp3
└── sfx/
    ├── attack.mp3
    ├── hit.mp3
    ├── critical.mp3
    ├── heal.mp3
    ├── levelup.mp3
    ├── buy.mp3
    ├── equip.mp3
    └── button_click.mp3
```

#### 12.3.4 Atualizar pubspec.yaml Assets
**Arquivo:** `pubspec.yaml`

```yaml
flutter:
  assets:
    - assets/audio/music/
    - assets/audio/sfx/
```

#### 12.3.5 Integrar Áudio nas Telas

**Lobby/Menu:**
```dart
@override
void initState() {
  super.initState();
  AudioService().playLobbyMusic();
}
```

**Batalha:**
```dart
void _iniciarBatalha() {
  if (inimigo.isElite) {
    AudioService().playBossBattleMusic();
  } else {
    AudioService().playBattleMusic();
  }
}

void _finalizarBatalha(bool vitoria) {
  AudioService().stopMusic();
  if (vitoria) {
    AudioService().playVictoryMusic();
  } else {
    AudioService().playDefeatMusic();
  }
}
```

#### 12.3.6 Criar Tela de Configurações de Áudio
**Arquivo:** `lib/features/settings/presentation/audio_settings_screen.dart` (NOVO)

```dart
// Layout:
// ┌─────────────────────────────────────┐
// │  CONFIGURAÇÕES DE ÁUDIO             │
// ├─────────────────────────────────────┤
// │  Música: [ON/OFF]                   │
// │  Volume: [━━━━━━●━━━] 70%           │
// ├─────────────────────────────────────┤
// │  Efeitos Sonoros: [ON/OFF]          │
// │  Volume: [━━━━━━━━●━] 80%           │
// └─────────────────────────────────────┘
```

### 12.4 Script para Download de Músicas
**Arquivo:** `scripts/download_music.dart` (NOVO)

```dart
// Script para baixar músicas gratuitas
// Executar: dart scripts/download_music.dart

// URLs de músicas gratuitas (exemplos):
const musicUrls = {
  'lobby_theme': 'https://opengameart.org/sites/default/files/audio/Tavern%20Loop.mp3',
  'battle_normal': 'https://...',
  // ...
};
```

### 12.5 Teste de Validação
- [ ] Música de lobby toca ao entrar no menu
- [ ] Música de batalha toca durante combate
- [ ] Música de boss/elite é diferente
- [ ] Vitória/derrota tocam corretamente
- [ ] Volume pode ser ajustado
- [ ] Música pode ser desligada
- [ ] Efeitos sonoros funcionam
- [ ] Configurações persistem

---

## FASE 13: TESTES E QA
**Prioridade:** Alta
**Dependências:** Todas as fases
**Estimativa de Complexidade:** Alta

### 13.1 Objetivos
- Testar todas as funcionalidades
- Corrigir bugs
- Otimizar performance
- Garantir estabilidade

### 13.2 Checklist de Testes

#### 13.2.1 Modo Unlock
- [ ] Login funciona
- [ ] Controle de dispositivo funciona
- [ ] Batalhas automáticas funcionam
- [ ] Monstros são desbloqueados
- [ ] Passivas são obtidas
- [ ] Kills são permanentes
- [ ] Sem eventos aparecem
- [ ] Salvamento funciona

#### 13.2.2 Modo Explorador
- [ ] Seleção de equipe funciona (2 + 3 banco)
- [ ] Seleção de mapa funciona (3 opções)
- [ ] 3 batalhas por mapa
- [ ] Tier sobe/desce/mantém corretamente
- [ ] XP é ganho corretamente
- [ ] Level up funciona
- [ ] Pontos de bônus funcionam
- [ ] Equipamentos funcionam (3 slots)
- [ ] Durabilidade funciona
- [ ] Energia limita batalhas
- [ ] Loja funciona
- [ ] Kills são gastas corretamente
- [ ] Monstro morto perde XP
- [ ] Banco recebe XP extra
- [ ] Desistir perde todo XP
- [ ] Drops funcionam

#### 13.2.3 Áudio
- [ ] Todas as músicas tocam
- [ ] Loops funcionam
- [ ] Transições suaves
- [ ] Volume ajustável
- [ ] On/Off funciona
- [ ] SFX funcionam

#### 13.2.4 Performance
- [ ] App não trava
- [ ] Carregamento rápido
- [ ] Sem memory leaks
- [ ] Bateria não drena excessivamente

#### 13.2.5 Persistência
- [ ] Dados salvam corretamente
- [ ] Dados carregam corretamente
- [ ] Sincronização com Drive funciona
- [ ] Migração de dados antigos funciona

---

## CRONOGRAMA SUGERIDO (SEM DATAS)

| Fase | Descrição | Complexidade |
|------|-----------|--------------|
| 1 | Infraestrutura Base | Média |
| 2 | Kills Permanentes | Média |
| 3 | Controle de Dispositivo | Alta |
| 4 | Modo Unlock | Média |
| 5 | Explorador Core | Alta |
| 6 | Mapas e Batalhas | Alta |
| 7 | XP e Evolução | Alta |
| 8 | Equipamentos | Média |
| 9 | Lojas | Média |
| 10 | Energia e Durabilidade | Média |
| 11 | Drops e Recompensas | Média |
| 12 | Polimento e Áudio | Média |
| 13 | Testes e QA | Alta |

---

## OBSERVAÇÕES IMPORTANTES

### Reaproveitamento de Código

| Componente Atual | Reaproveitamento | Onde Usar |
|-----------------|------------------|-----------|
| `BatalhaService` | 90% | Ambos os modos |
| `MonstroAventura` | 80% | Base para `MonstroExplorador` |
| `Item` | 60% | Base para `EquipamentoSlot` |
| `Habilidade` | 100% | Ambos os modos |
| `Passiva` | 100% | Ambos os modos |
| `TipagemService` | 100% | Ambos os modos |

### Riscos Identificados

1. **Migração de dados** - Usuários antigos podem perder dados se migração falhar
   - Mitigação: Backup antes de migrar, rollback se falhar

2. **Controle de dispositivo** - Pode frustrar jogadores
   - Mitigação: Mensagens claras, permitir logout

3. **Complexidade do Explorador** - Muitos sistemas novos
   - Mitigação: Implementar em fases testáveis

4. **Performance** - Mais dados para processar
   - Mitigação: Lazy loading, cache

---

## SISTEMA DE SINCRONIZAÇÃO (DRIVE)

### Estrutura de Pastas no Drive

```
TECHTERRA/
├── dispositivos/
│   └── {email}_dispositivo.json       # Controle de dispositivo diário
├── kills/
│   └── {email}_kills.json             # Kills permanentes
├── explorador/
│   ├── {email}_monstros.json          # Monstros do explorador (levels, equipamentos)
│   └── {email}_inventario.json        # Inventário de equipamentos
├── unlock/
│   └── {email}_colecao.json           # Monstros desbloqueados + passivas
├── relatorios_diarios/                # NOVO - Resumo diário para relatórios
│   └── {email}/
│       └── {data}.json                # Ex: 2025-12-22.json
└── (pastas existentes...)
    ├── HISTORIAS/                     # Manter para compatibilidade
    ├── rankings/
    └── mochila/
```

### O Que Sincroniza e Quando

#### MODO UNLOCK (Sincroniza Tudo)

| Dado | Quando Sincroniza | Direção |
|------|-------------------|---------|
| **Monstros Desbloqueados** | Ao desbloquear novo monstro | Local → Drive |
| **Passivas Obtidas** | Ao obter nova passiva | Local → Drive |
| **Kills Permanentes** | Após cada batalha | Local → Drive |
| **Progresso da Run** | Após cada tier | Local → Drive |
| **Itens/Magias** | Ao obter | Local → Drive |

#### MODO EXPLORADOR

| Dado | Sincroniza? | Quando | Observações |
|------|-------------|--------|-------------|
| **XP dos Monstros** | ❌ NÃO | - | Local do dispositivo, perde ao trocar |
| **Barra de XP** | ❌ NÃO | - | Sempre reseta ao baixar dados |
| **Level dos Monstros** | ✅ SIM | Ao subir level | Pode sobrescrever se baixar |
| **Pontos de Bônus Distribuídos** | ✅ SIM | Ao distribuir | Permanente |
| **Equipamentos (3 slots)** | ✅ SIM | Ao equipar/desequipar | Com durabilidade |
| **Inventário de Equipamentos** | ✅ SIM | Ao obter/usar | Lista completa |
| **Kills Gastas** | ✅ SIM | Ao comprar na loja | Debita permanente |
| **Caixinhas/Drops** | ✅ SIM | Ao obter | Guardadas no inventário |
| **Energia Diária** | ❌ NÃO | - | Reseta todo dia |
| **Sessão Ativa** | ❌ NÃO | - | Local apenas |
| **Histórico de Batalhas** | ❌ NÃO | - | **REMOVIDO** - não salva mais |

#### RELATÓRIO DIÁRIO (Novo)

| Dado | Quando Sincroniza | Observações |
|------|-------------------|-------------|
| **Kills do Dia (por tipo)** | Ao fazer login no dia seguinte | Resumo do dia anterior |
| **Monstros Derrotados** | Ao fazer login no dia seguinte | Quantidade total |
| **Itens no Inventário** | Ao fazer login no dia seguinte | Snapshot do fim do dia |
| **Chaves/Moedas** | Ao fazer login no dia seguinte | Ambos os modos |
| **Tier Máximo Alcançado** | Ao fazer login no dia seguinte | Para estatísticas |
| **Tempo Jogado** | Ao fazer login no dia seguinte | Opcional |

#### CONTROLE DE DISPOSITIVO

| Dado | Quando Sincroniza | Direção |
|------|-------------------|---------|
| **ID do Dispositivo do Dia** | Ao fazer login | Drive → Local (verificar) |
| **Registro de Novo Dispositivo** | Ao confirmar acesso | Local → Drive |
| **Data do Último Acesso** | Ao fazer login | Local → Drive |

### Fluxo de Sincronização Detalhado

#### Login no App

```
┌─────────────────────────────────────────────────────────────┐
│  1. AUTENTICAÇÃO                                            │
│     └─ Firebase Auth (email/senha)                          │
├─────────────────────────────────────────────────────────────┤
│  2. VERIFICAR DISPOSITIVO (Drive) - ANTES DE TUDO!          │
│     ├─ Baixar: dispositivos/{email}_dispositivo.json        │
│     │                                                       │
│     ├─ SE dispositivo diferente no mesmo dia:               │
│     │   ├─ ❌ BLOQUEAR LOGIN                                │
│     │   ├─ Mostrar mensagem:                                │
│     │   │   "Você já acessou de outro dispositivo hoje.     │
│     │   │    Aguarde até amanhã para jogar aqui."           │
│     │   ├─ Mostrar tempo restante até meia-noite            │
│     │   └─ Botão: [Fazer Logout]                            │
│     │                                                       │
│     ├─ SE mesmo dispositivo → Continuar                     │
│     └─ SE novo dia → Registrar este dispositivo             │
├─────────────────────────────────────────────────────────────┤
│  3. UPLOAD RELATÓRIO DO DIA ANTERIOR (Background)           │
│     ├─ Verificar se há dados do dia anterior não enviados   │
│     ├─ Salvar em: relatorios_diarios/{email}/{data}.json    │
│     └─ Limpar dados locais do dia anterior                  │
├─────────────────────────────────────────────────────────────┤
│  4. CARREGAR DADOS (Drive → Local)                          │
│     ├─ kills/{email}_kills.json                             │
│     ├─ unlock/{email}_colecao.json                          │
│     ├─ explorador/{email}_monstros.json                     │
│     └─ explorador/{email}_inventario.json                   │
├─────────────────────────────────────────────────────────────┤
│  5. AVISO DE XP (se aplicável)                              │
│     └─ "XP local será perdido ao baixar dados da nuvem"     │
└─────────────────────────────────────────────────────────────┘
```

#### Após Batalha (Modo Explorador)

```
┌─────────────────────────────────────────────────────────────┐
│  VITÓRIA                                                    │
├─────────────────────────────────────────────────────────────┤
│  SALVA LOCAL (Hive):                                        │
│  ├─ XP dos monstros (não sincroniza!)                       │
│  ├─ Energia gasta                                           │
│  └─ Estado da sessão                                        │
├─────────────────────────────────────────────────────────────┤
│  SALVA NO DRIVE (se level up):                              │
│  ├─ explorador/{email}_monstros.json                        │
│  │   └─ Novo level do monstro                               │
│  │   └─ Pontos de bônus distribuídos                        │
│  └─ Durabilidade dos equipamentos                           │
├─────────────────────────────────────────────────────────────┤
│  SALVA NO DRIVE (se drop):                                  │
│  └─ explorador/{email}_inventario.json                      │
│      └─ Nova caixinha/equipamento                           │
└─────────────────────────────────────────────────────────────┘
```

#### Compra na Loja

```
┌─────────────────────────────────────────────────────────────┐
│  COMPRA DE ITEM                                             │
├─────────────────────────────────────────────────────────────┤
│  SALVA NO DRIVE:                                            │
│  ├─ kills/{email}_kills.json                                │
│  │   └─ Kills do tipo gastas (debito)                       │
│  └─ explorador/{email}_inventario.json                      │
│      └─ Novo equipamento adquirido                          │
└─────────────────────────────────────────────────────────────┘
```

#### Monstro Morre na Run

```
┌─────────────────────────────────────────────────────────────┐
│  MONSTRO DESMAIOU                                           │
├─────────────────────────────────────────────────────────────┤
│  SALVA LOCAL (Hive):                                        │
│  ├─ XP zerado (perde tudo)                                  │
│  └─ Flag desmaiado = true                                   │
├─────────────────────────────────────────────────────────────┤
│  NÃO SALVA NO DRIVE:                                        │
│  └─ Level NÃO diminui (mantém o que tinha)                  │
│  └─ Equipamentos NÃO são perdidos                           │
└─────────────────────────────────────────────────────────────┘
```

#### Troca de Dispositivo

```
┌─────────────────────────────────────────────────────────────┐
│  CENÁRIO: Jogador troca de celular                          │
├─────────────────────────────────────────────────────────────┤
│  O QUE MANTÉM (vem do Drive):                               │
│  ├─ Monstros desbloqueados                                  │
│  ├─ Levels dos monstros                                     │
│  ├─ Pontos de bônus distribuídos                            │
│  ├─ Equipamentos e inventário                               │
│  ├─ Kills permanentes                                       │
│  └─ Passivas obtidas                                        │
├─────────────────────────────────────────────────────────────┤
│  O QUE PERDE (era local):                                   │
│  ├─ XP acumulado na barra (volta pra 0)                     │
│  ├─ Energia do dia (reseta)                                 │
│  └─ Sessão ativa (precisa recomeçar)                        │
├─────────────────────────────────────────────────────────────┤
│  COMPORTAMENTO ESPECIAL:                                    │
│  └─ Se baixar dados → Level pode SOBRESCREVER o local       │
│      (útil se jogou em outro dispositivo e subiu level)     │
└─────────────────────────────────────────────────────────────┘
```

### Estrutura dos JSONs

#### dispositivos/{email}_dispositivo.json
```json
{
  "email": "jogador@email.com",
  "dispositivoIdHoje": "abc123-device-id",
  "dataRegistro": "2025-12-22",
  "plataforma": "android",
  "modelo": "Samsung Galaxy S21"
}
```

#### kills/{email}_kills.json
```json
{
  "email": "jogador@email.com",
  "ultimaAtualizacao": "2025-12-22T15:30:00Z",
  "kills": {
    "fogo": 234,
    "agua": 156,
    "grama": 89,
    "dragao": 45
    // ... todos os tipos
  }
}
```

#### explorador/{email}_monstros.json
```json
{
  "email": "jogador@email.com",
  "monstros": [
    {
      "id": "dragao_001",
      "tipoPrincipal": "dragao",
      "level": 5,
      "pontosDistribuidos": {
        "vidaProprio": 3,
        "vidaTipagem": 1,
        "ataqueProprio": 1
      },
      "equipamentos": {
        "cabeca": { "id": "elmo_123", "durabilidade": 8 },
        "peito": { "id": "armadura_456", "durabilidade": 12 },
        "bracos": null
      }
    }
    // ... outros monstros
  ]
}
```

#### explorador/{email}_inventario.json
```json
{
  "email": "jogador@email.com",
  "equipamentos": [
    {
      "id": "elmo_789",
      "nome": "Elmo de Fogo",
      "slot": "cabeca",
      "tipagem": "fogo",
      "raridade": "raro",
      "atributos": { "vida": 15, "defesa": 8 },
      "durabilidadeMaxima": 15,
      "durabilidadeAtual": 15,
      "tier": 5
    }
  ],
  "caixinhas": [
    {
      "id": "caixa_001",
      "tipo": "monstro",
      "raridade": "epico",
      "aberta": false
    }
  ]
}
```

#### relatorios_diarios/{email}/{data}.json (NOVO)
```json
{
  "email": "jogador@email.com",
  "data": "2025-12-22",
  "dispositivo": {
    "id": "abc123-device-id",
    "plataforma": "android",
    "modelo": "Samsung Galaxy S21"
  },
  "resumo": {
    "monstrosDerrotados": 45,
    "tierMaximoAlcancado": 8,
    "tempoJogadoMinutos": 120
  },
  "killsDoDia": {
    "fogo": 12,
    "agua": 8,
    "grama": 15,
    "dragao": 3,
    "normal": 7
    // ... apenas tipos que tiveram kills
  },
  "killsTotaisAoFimDoDia": {
    "fogo": 234,
    "agua": 156,
    "grama": 89,
    "dragao": 45
    // ... snapshot completo
  },
  "inventarioAoFimDoDia": {
    "modoUnlock": {
      "chaveAuto": 1,
      "ovoEvento": 5,
      "moedaChave": 23,
      "pocoes": 3,
      "jaulinha": 0
    },
    "modoExplorador": {
      "equipamentosQuantidade": 12,
      "caixinhasQuantidade": 3
    }
  },
  "progressoModos": {
    "unlock": {
      "tierAtual": 15,
      "scoreAtual": 42,
      "monstrosDesbloqueados": 45
    },
    "explorador": {
      "runsCompletadas": 2,
      "maiorTierRun": 6
    }
  }
}
```

### Resumo Visual

```
┌─────────────────────────────────────────────────────────────┐
│                    SINCRONIZAÇÃO                            │
├──────────────────────┬──────────────────────────────────────┤
│   SINCRONIZA ✅      │   NÃO SINCRONIZA ❌                  │
├──────────────────────┼──────────────────────────────────────┤
│ • Kills permanentes  │ • XP (barra de experiência)          │
│ • Levels             │ • Energia diária                     │
│ • Pontos de bônus    │ • Sessão ativa                       │
│ • Equipamentos       │ • Estado "desmaiado"                 │
│ • Inventário         │ • Histórico de batalhas (removido)   │
│ • Monstros desbloq.  │                                      │
│ • Passivas           │                                      │
│ • Controle device    │                                      │
│ • Relatório diário   │                                      │
└──────────────────────┴──────────────────────────────────────┘
```

### Fluxo do Relatório Diário

```
┌─────────────────────────────────────────────────────────────┐
│  DURANTE O DIA (Local - Hive)                               │
├─────────────────────────────────────────────────────────────┤
│  O app vai acumulando localmente:                           │
│  ├─ Kills feitas por tipo                                   │
│  ├─ Monstros derrotados (contador)                          │
│  ├─ Tier máximo alcançado                                   │
│  ├─ Tempo de jogo                                           │
│  └─ Não salva cada batalha individualmente!                 │
├─────────────────────────────────────────────────────────────┤
│  AO FAZER LOGIN NO DIA SEGUINTE                             │
├─────────────────────────────────────────────────────────────┤
│  1. Detecta que há dados do dia anterior                    │
│  2. Monta o JSON do relatório diário                        │
│  3. Upload em BACKGROUND (não trava o login)                │
│     └─ relatorios_diarios/{email}/{data-ontem}.json         │
│  4. Limpa dados locais do dia anterior                      │
│  5. Continua o fluxo normal de login                        │
└─────────────────────────────────────────────────────────────┘
```

### Benefícios do Relatório Diário

| Antes | Depois |
|-------|--------|
| Salvava cada batalha | Salva resumo do dia |
| Muito tráfego de rede | 1 upload por dia |
| JSONs pesados | JSON leve (~1KB) |
| Difícil analisar | Fácil gerar relatórios |
| Sincronização frequente | Upload em background |

---

## PRÓXIMOS PASSOS

1. Revisar este documento e aprovar
2. Começar pela Fase 1 (Infraestrutura)
3. Testar cada fase antes de prosseguir
4. Iterar baseado em feedback

---

## CHANGELOG / IMPLEMENTAÇÕES REALIZADAS

### 2025-12-23 - Sessão 2

#### Correções
- **Kills removidos do Modo Explorador**: Este modo NÃO ganha pontos de kill. Removidas todas as referências a kills em:
  - `mapa_explorador_screen.dart`
  - `batalha_explorador_screen.dart`

#### Animação de XP
- **Animação de XP ganho após batalha**: Implementada animação visual quando monstro ganha XP
  - Imagem do monstro em círculo (estilo da tela de mapas)
  - **XP ganho**: borda verde, texto "+X XP" em verde
  - **Level up**: borda âmbar, ícone ✨ (auto_awesome) + "Lv.X" em amarelo
  - Animação sobe ~150px e desaparece (1.8s)
  - Monstro ativo (esquerda) e banco (direita) animam simultaneamente

#### Sistema de Distribuição de XP
- **XpDistribuicaoResult**: Nova classe que retorna informações detalhadas sobre a distribuição de XP:
  - Qual monstro ativo recebeu XP
  - Qual monstro do banco recebeu XP
  - Se algum subiu de level
  - Novo level (se subiu)
- **Sorteio individual**: XP vai para apenas 1 monstro ativo aleatório (não divide entre todos)
- Mesmo comportamento para monstros do banco (1 aleatório recebe)

### 2025-12-22/23 - Sessão 1

#### Tela de Mapa do Explorador
- **Seleção de monstro antes da batalha**: Modal para escolher qual monstro usar (se tiver mais de 1)
  - Mostra imagem, nome, level, tipos (ícones), barras de vida e energia
- **Ícones de tipo**: Adicionados ícones de tipo primário e secundário na seleção de monstro
- **Caveirinha de resultado**:
  - Vermelho = jogador venceu (derrotou o monstro)
  - Verde = jogador perdeu (monstro fugiu)
  - Posição: top: -6, right: -2
- **Botão voltar**: Retorna para home do explorador sem consequências (progresso é salvo)
- **Botão desistir**: Separado do voltar, com confirmação

#### Arquivos Modificados/Criados
```
lib/features/explorador/
├── models/
│   ├── equipe_explorador.dart      # XpDistribuicaoResult, distribuirXpComResultado()
│   ├── mapa_explorador.dart
│   └── monstro_explorador.dart
├── presentation/
│   ├── mapa_explorador_screen.dart # Animação XP, seleção monstro, caveirinhas
│   ├── selecao_mapa_screen.dart    # Estado mapas desistidos
│   └── batalha_explorador_screen.dart
├── providers/
│   ├── equipe_explorador_provider.dart  # distribuirXpComResultado()
│   └── mapas_explorador_provider.dart   # Estado mapas desistidos
└── services/
    └── batalha_explorador_service.dart
```

#### Regras Confirmadas do Modo Explorador
| Aspecto | Comportamento |
|---------|---------------|
| **Kills** | NÃO ganha pontos de kill |
| **XP** | Apenas 1 monstro ativo aleatório recebe |
| **XP Banco** | Apenas 1 monstro do banco aleatório recebe |
| **Voltar** | Livre, sem perder progresso |
| **Desistir** | Marca mapa como indisponível |
| **Progresso** | Salvo automaticamente |

---

**Documento criado por Claude + Guilherme**
**TechTerra v3.0 - Modo Explorador**
