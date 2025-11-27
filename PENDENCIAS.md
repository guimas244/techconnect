# Pendências do Projeto TechTerra

**Última atualização:** 2025-11-27
**Branch:** feature/criadouro

---

## Sistema Criadouro (Tamagotchi)

### Funcionalidades Implementadas
- [x] Criação de mascotes por tipo
- [x] Sistema de stats (fome, sede, higiene, alegria, saúde)
- [x] Degradação automática de stats ao longo do tempo
- [x] Sistema de XP e níveis por tipo de mascote
- [x] Mochila do criadouro com itens
- [x] Loja para comprar itens
- [x] Alimentação e uso de itens
- [x] Persistência no Hive
- [x] Notificações de estado do mascote
- [x] Memorial de mascotes mortos
- [x] Widget de barra de XP animada
- [x] Configurações de limites de notificação
- [x] Integração com batalhas (ganhar XP ao vencer)

### Pendências do Criadouro

#### Alta Prioridade
- [ ] **Interações com mascote** - Implementar sistema de interações (brincar, acariciar, treinar)
- [ ] **Balanceamento de stats** - Ajustar taxas de degradação e recuperação
- [ ] **Animações do mascote** - Adicionar animações de reação às interações
- [ ] **Som/feedback** - Adicionar sons ao interagir com o mascote

#### Média Prioridade
- [ ] **Evolução de mascotes** - Sistema de evolução quando atinge certos níveis
- [ ] **Conquistas/achievements** - Recompensas por marcos alcançados
- [ ] **Ranking de criadores** - Leaderboard de quem tem mascotes mais fortes
- [ ] **Mascotes especiais** - Desbloqueáveis por eventos ou conquistas

#### Baixa Prioridade
- [ ] **Mini-games** - Jogos para ganhar moedas e XP
- [ ] **Customização visual** - Acessórios e itens cosméticos
- [ ] **Sistema social** - Visitar criadouros de amigos

---

## Sistema de Aventura

### Funcionalidades Implementadas
- [x] Mapa de aventura
- [x] Sistema de batalha
- [x] Mochila do jogador
- [x] Drops de itens
- [x] Sistema de tipagem de dano
- [x] Monstros por tipo
- [x] Progressão por andares

### Pendências da Aventura

#### Alta Prioridade
- [ ] **Bonificação inicial** - Adicionar 10 chaves ao criar conta (script pronto, falta integrar)
- [ ] **Balanceamento de batalhas** - Ajustar dificuldade progressiva

#### Média Prioridade
- [ ] **Boss battles** - Batalhas especiais em andares específicos
- [ ] **Sistema de quests** - Missões diárias/semanais
- [ ] **Eventos especiais** - Eventos temporários com recompensas

---

## Sistema Geral

### Pendências Gerais

#### Alta Prioridade
- [ ] **Testes automatizados** - Cobertura de testes para lógica crítica
- [ ] **Tratamento de erros** - Melhorar feedback ao usuário em caso de falhas
- [ ] **Otimização de performance** - Reduzir rebuilds desnecessários

#### Média Prioridade
- [ ] **Tutorial inicial** - Guia para novos jogadores
- [ ] **Configurações do app** - Sons, notificações, tema
- [ ] **Offline mode** - Funcionar sem internet (parcial)

#### Baixa Prioridade
- [ ] **Internacionalização** - Suporte a múltiplos idiomas
- [ ] **Acessibilidade** - Melhorar suporte a leitores de tela
- [ ] **Modo escuro** - Tema dark

---

## Bugs Conhecidos

| ID | Descrição | Severidade | Status |
|----|-----------|------------|--------|
| - | Nenhum bug reportado | - | - |

---

## Próximos Passos Sugeridos

1. **Integrar sistema de bonificação inicial** - 10 chaves na primeira vez
2. **Implementar interações do mascote** - Brincar, acariciar
3. **Adicionar animações de feedback** - Quando mascote come, bebe, etc
4. **Testar sistema de notificações** - Verificar em diferentes dispositivos
5. **Balancear economia** - Preços de itens vs ganho de moedas

---

## Notas de Desenvolvimento

- **Flutter:** 3.x
- **State Management:** Riverpod 2.6.1
- **Persistência Local:** Hive 2.2.3
- **Autenticação:** Firebase Auth
- **Cloud Storage:** Google Drive API

---

## Contato

Para dúvidas ou sugestões, abra uma issue no repositório.
