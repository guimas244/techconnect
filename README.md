
# TechConnect

TechConnect é um aplicativo Flutter 3 com Material 3, gerenciamento de estado Riverpod, navegação GoRouter, persistência local Hive (futuramente Drive), autenticação Firebase (Google, email/senha, convidado com upgrade). Analytics e Crash Reporting estão desativados.

## 🏗️ Arquitetura

O projeto segue uma **Clean Architecture** baseada em **features**, com separação clara de responsabilidades e uso de **Riverpod** para gerenciamento de estado.

### 📁 Estrutura de Pastas

```
lib/
├── core/                           # Configurações globais da aplicação
│   ├── constants/
│   │   └── app_constants.dart      # Constantes da aplicação (rotas, keys, valores padrão)
│   ├── themes/
│   │   └── app_theme.dart          # Tema Material 3 (light/dark)
│   ├── routes/
│   │   └── app_router.dart         # Configuração de rotas GoRouter
│   └── utils/
│       ├── extensions.dart         # Extensions úteis
│       └── validators.dart         # Validações de formulário
├── features/                       # Features organizadas por domínio
│   ├── auth/                       # Autenticação
│   │   ├── data/
│   │   │   └── auth_repository.dart    # Repositório de autenticação Firebase
│   │   ├── presentation/
│   │   │   └── login_screen.dart       # Tela de login
│   │   └── providers/
│   │       └── auth_provider.dart      # Providers Riverpod para auth
│   ├── tipagem/                    # Sistema de tipos e danos
│   │   ├── data/
│   │   │   └── tipagem_repository.dart # Repositório para JSONs de tipagem
│   │   ├── domain/
│   │   │   └── tipagem_models.dart     # Modelos de domínio
│   │   ├── presentation/
│   │   │   ├── tipagem_screen.dart     # Lista de tipos
│   │   │   └── tipagem_dano_screen.dart # Configuração de danos
│   │   └── providers/
│   │       └── tipagem_provider.dart   # Providers para tipagem
│   ├── home/                       # Tela inicial
│   │   └── presentation/
│   │       └── home_screen.dart        # Dashboard principal
│   └── admin/                      # Painel administrativo
│       └── presentation/
│           └── admin_screen.dart       # Menu administrativo
├── shared/                         # Componentes reutilizáveis
│   ├── models/
│   │   └── tipo_enum.dart          # Enum dos tipos de criaturas (30 tipos)
│   ├── widgets/
│   │   ├── menu_block.dart         # Widget de blocos do menu
│   │   ├── custom_slider.dart      # Slider customizado para danos
│   │   └── loading_widget.dart     # Widget de loading
│   └── utils/
│       ├── storage_helper.dart     # Helper para persistência local
│       └── asset_helper.dart       # Helper para assets e ícones
├── main.dart                       # Ponto de entrada da aplicação
└── firebase_options.dart           # Configurações Firebase
```

### 🗄️ Dados e Persistência

```
dados_json/                          # Arquivos JSON de configuração
├── tb_normal_defesa.json           # Configurações de defesa por tipo
├── tb_planta_defesa.json           # (30 arquivos, um para cada tipo)
└── ...                            # Formato: tb_{tipo}_defesa.json

assets/
└── tipagens/                       # Ícones dos tipos
    ├── icon_tipo_normal.png        # Ícones padronizados
    └── ...                         # (30 ícones)
```

### 🎯 Padrões Arquiteturais

#### **1. Feature-First Organization**
- Cada feature é auto-contida
- Separação clara de camadas (data, domain, presentation)
- Providers específicos por feature

#### **2. Clean Architecture Layers**
- **Presentation**: Telas e widgets (UI)
- **Domain**: Modelos e regras de negócio
- **Data**: Repositórios e fontes de dados

#### **3. Riverpod State Management**
- Providers para estado global
- StateNotifiers para lógica complexa
- Injeção de dependência automática

#### **4. Repository Pattern**
- Abstração de fontes de dados
- Fácil teste e manutenção
- Separação entre lógica e dados

## 🛠️ Tecnologias

- **Flutter 3**: Framework principal
- **Material 3**: Design system
- **Riverpod**: Gerenciamento de estado
- **GoRouter**: Navegação declarativa
- **Hive**: Persistência local
- **Firebase Auth**: Autenticação
- **Path Provider**: Armazenamento de arquivos

## ⚙️ Como rodar

1. **Clone o projeto**:
   ```bash
   git clone <repository-url>
   cd techterra
   ```

2. **Instale as dependências**:
   ```bash
   flutter pub get
   ```

3. **Execute o app**:
   ```bash
   flutter run
   ```

## 📦 Geração de APK

Para gerar o APK de produção com nome automatizado:

**🪟 Windows:**
```batch
build_apk.bat
```

**🐧 Linux/macOS/Git Bash:**
```bash
./build_apk.sh
```

**Resultado:** `build/app/outputs/flutter-apk/techterra-v{versão}-release.apk`

## 🔢 Alteração de Versão

Para alterar a versão do app (reflete em todos os pontos):

1. **Edite apenas:** `pubspec.yaml`
   ```yaml
   version: 1.2.0+3  # major.minor.patch+buildNumber
   ```

2. **Execute:** Um dos comandos de build APK acima

**Pontos que atualizam automaticamente:**
- Tela inicial (título)
- Ranking (versão salva nos scores)
- Nome do APK gerado
- Configurações do Android

## 📱 Funcionalidades

### ✅ Implementadas
- **Autenticação**: Login com email/senha, logout
- **Sistema de Tipagem**: 30 tipos de criaturas com ícones
- **Configuração de Danos**: Sliders para multiplicadores (0.0x a 2.0x)
- **Persistência**: JSONs salvos localmente com assets como fallback
- **Navegação**: Estrutura de admin e menus organizados
- **UI Responsiva**: Adaptada para diferentes tamanhos de tela

### 🔄 Em Desenvolvimento
- **Login com Google**: Integração completa
- **Login de Convidado**: Com opção de upgrade
- **Sistema de Monstros**: CRUD completo
- **Sistema de Regras**: Configurações de jogo
- **Sincronização**: Drive/servidor para backup

## 🧪 Testabilidade

A arquitetura facilita testes:
- **Unit Tests**: Providers e repositórios isolados
- **Widget Tests**: Telas independentes
- **Integration Tests**: Fluxos completos

## 📚 Padrões de Código

- **Nomenclatura**: snake_case para arquivos, PascalCase para classes
- **Imports**: Organizados por: Flutter → packages → projeto
- **Widgets**: Extraídos quando reutilizáveis
- **Constantes**: Centralizadas em `app_constants.dart`

---

**Versão**: 1.1.1  
**Última atualização**: 03/09/2025
