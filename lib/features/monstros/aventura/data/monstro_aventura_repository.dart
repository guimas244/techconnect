import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import '../models/monstro_aventura.dart';
import '../../../../core/services/google_drive_service.dart';
import '../../../../shared/models/tipo_enum.dart';

class MonstroAventuraRepository {
  final GoogleDriveService _driveService = GoogleDriveService();
  
  // Cache local
  static final List<MonstroAventura> _cache = [];
  static bool _cacheCarregado = false;

  // ========================================
  // ✅ MÉTODOS PÚBLICOS - INTERFACE ÚNICA
  // ========================================

  /// LISTA TODOS OS MONSTROS
  Future<List<MonstroAventura>> listarMonstros() async {
    try {
      if (!_cacheCarregado) {
        await _carregarCache();
      }
      return List.from(_cache);
    } catch (e) {
      print('❌ Erro ao listar monstros: $e');
      return [];
    }
  }

  /// SALVA UM NOVO MONSTRO
  Future<String> salvarMonstro(MonstroAventura monstro) async {
    try {
      // Validação
      if (!monstro.tiposValidos) {
        throw Exception('Os dois tipos do monstro não podem ser iguais');
      }

      // Gerar ID único se não tiver
      final novoMonstro = monstro.id.isEmpty 
          ? monstro.copyWith(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              criadoEm: DateTime.now(),
            )
          : monstro.copyWith(atualizadoEm: DateTime.now());

      // Processa imagem se fornecida
      MonstroAventura monstroProcessado = novoMonstro;
      if (novoMonstro.imagemBytes != null) {
        try {
          final imagemProcessada = await _processarImagem(novoMonstro.imagemBytes!);
          final urlImagem = await _salvarImagemNoDrive(novoMonstro.id, imagemProcessada);
          monstroProcessado = novoMonstro.copyWith(
            imagemUrl: urlImagem,
            imagemBytes: null, // Remove bytes após salvar
          );
        } catch (e) {
          print('⚠️ Erro ao processar imagem: $e');
          // Continua sem a imagem
        }
      }

      // Atualiza cache
      final index = _cache.indexWhere((m) => m.id == monstroProcessado.id);
      if (index >= 0) {
        _cache[index] = monstroProcessado;
      } else {
        _cache.add(monstroProcessado);
      }

      // Salva no Drive
      await _salvarNoDrive();
      
      // Salva localmente
      await _salvarLocalmente();

      print('✅ Monstro salvo: ${monstroProcessado.nome}');
      return monstroProcessado.id;
    } catch (e) {
      print('❌ Erro ao salvar monstro: $e');
      throw Exception('Erro ao salvar monstro: $e');
    }
  }

  /// REMOVE UM MONSTRO
  Future<void> removerMonstro(String id) async {
    try {
      _cache.removeWhere((m) => m.id == id);
      
      // Salva mudanças
      await _salvarNoDrive();
      await _salvarLocalmente();
      
      print('✅ Monstro removido: $id');
    } catch (e) {
      print('❌ Erro ao remover monstro: $e');
      throw Exception('Erro ao remover monstro: $e');
    }
  }

  /// BUSCA MONSTRO POR ID
  Future<MonstroAventura?> buscarMonstroPorId(String id) async {
    try {
      if (!_cacheCarregado) {
        await _carregarCache();
      }
      return _cache.cast<MonstroAventura?>().firstWhere(
        (m) => m?.id == id,
        orElse: () => null,
      );
    } catch (e) {
      print('❌ Erro ao buscar monstro: $e');
      return null;
    }
  }

  /// FORÇA SINCRONIZAÇÃO COM O DRIVE
  Future<void> sincronizarComDrive() async {
    try {
      await _carregarDoDrive();
      print('✅ Sincronização concluída');
    } catch (e) {
      print('❌ Erro na sincronização: $e');
      throw Exception('Erro na sincronização: $e');
    }
  }

  /// LIMPA CACHE (FORÇA RECARREGAMENTO)
  void limparCache() {
    _cache.clear();
    _cacheCarregado = false;
  }

  /// FORÇA REGENERAÇÃO DOS MONSTROS (para atualizar nomes)
  Future<void> forcarRegeneracao() async {
    try {
      _cache.clear();
      _cacheCarregado = false;

      // Remove arquivo local para forçar regeneração completa
      try {
        if (!kIsWeb) {
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/monstros_aventura.json');
          if (await file.exists()) {
            await file.delete();
            print('🗑️ Arquivo local removido');
          }
        }
      } catch (e) {
        print('⚠️ Erro ao remover arquivo local: $e');
      }

      await _gerarColecoes();
      await _salvarLocalmente();
      print('✅ Monstros regenerados com novos nomes');
    } catch (e) {
      print('❌ Erro ao regenerar monstros: $e');
    }
  }

  // ========================================
  // 🔒 MÉTODOS PRIVADOS INTERNOS
  // ========================================

  /// Carrega cache pela primeira vez
  Future<void> _carregarCache() async {
    try {
      _cacheCarregado = true; // Marca como carregado primeiro

      // Tenta carregar do Drive primeiro (sem bloquear)
      try {
        if (_driveService.isConectado) {
          await _carregarDoDrive();
        }
      } catch (e) {
        print('⚠️ Erro ao carregar do Drive: $e');
      }

      // Se não carregou do Drive, tenta local (sem bloquear)
      if (_cache.isEmpty) {
        try {
          await _carregarLocalmente();
        } catch (e) {
          print('⚠️ Erro ao carregar localmente: $e');
        }
      }

      // Verifica se precisa regenerar com nomes reais
      bool precisaRegenerar = false;
      if (_cache.isNotEmpty) {
        // Verifica se algum monstro ainda tem nome antigo (baseado no displayName)
        for (final monstro in _cache) {
          final nomeEsperado = monstro.colecao == 'colecao_nostalgicos'
              ? '${monstro.tipo1.monsterName} Nostálgico'
              : monstro.tipo1.monsterName;

          if (monstro.nome != nomeEsperado) {
            precisaRegenerar = true;
            print('🔄 Detectado nome antigo: ${monstro.nome} -> $nomeEsperado');
            break;
          }
        }
      }

      // Se cache vazio ou precisa regenerar, gera monstros das duas coleções
      if (_cache.isEmpty || precisaRegenerar) {
        if (precisaRegenerar) {
          print('🔄 Regenerando monstros com nomes reais...');
          _cache.clear();
        }
        // Executa em background para não bloquear inicialização
        _gerarColecoes().catchError((e) {
          print('⚠️ Erro em background ao gerar coleções: $e');
        });
      }
    } catch (e) {
      print('⚠️ Erro geral ao carregar cache: $e');
      _cacheCarregado = true; // Sempre marca como carregado
    }
  }

  /// Gera automaticamente as duas coleções de monstros
  Future<void> _gerarColecoes() async {
    try {
      print('🎮 Gerando coleções de monstros...');
      final agora = DateTime.now();

      // Lista segura de tipos para evitar problemas de inicialização
      final tiposSeguro = [
        Tipo.agua, Tipo.fogo, Tipo.planta, Tipo.eletrico, Tipo.psiquico,
        Tipo.gelo, Tipo.dragao, Tipo.trevas, Tipo.fera, Tipo.venenoso,
        Tipo.terrestre, Tipo.voador, Tipo.inseto, Tipo.pedra, Tipo.fantasma,
        Tipo.normal, Tipo.luz, Tipo.magico, Tipo.marinho, Tipo.subterraneo,
        Tipo.tecnologia, Tipo.alien, Tipo.tempo, Tipo.vento, Tipo.mistico,
        Tipo.deus, Tipo.desconhecido, Tipo.nostalgico, Tipo.docrates, Tipo.zumbi
      ];

      // Gerar coleção inicial (desbloqueada)
      for (final tipo in tiposSeguro) {
        try {
          final monstroInicial = MonstroAventura(
            id: 'inicial_${tipo.name}',
            nome: _gerarNomePorTipo(tipo, false),
            tipo1: tipo,
            tipo2: _obterTipoSecundario(tipo, tiposSeguro),
            criadoEm: agora,
            colecao: 'colecao_inicial',
            isBloqueado: false,
          );
          _cache.add(monstroInicial);
          print('✅ Monstro inicial criado: ${monstroInicial.nome} (${tipo.name})');
        } catch (e) {
          print('⚠️ Erro ao gerar monstro inicial ${tipo.name}: $e');
        }
      }

      // Gerar coleção nostálgicos (bloqueada)
      for (final tipo in tiposSeguro) {
        try {
          final monstroNostalgico = MonstroAventura(
            id: 'nostalgico_${tipo.name}',
            nome: _gerarNomePorTipo(tipo, true),
            tipo1: tipo,
            tipo2: _obterTipoSecundario(tipo, tiposSeguro),
            criadoEm: agora,
            colecao: 'colecao_nostalgicos',
            isBloqueado: true,
          );
          _cache.add(monstroNostalgico);
          print('✅ Monstro nostálgico criado: ${monstroNostalgico.nome} (${tipo.name})');
        } catch (e) {
          print('⚠️ Erro ao gerar monstro nostálgico ${tipo.name}: $e');
        }
      }

      print('✅ ${_cache.length} monstros gerados');

      // Salva as coleções de forma assíncrona e defensiva
      try {
        await _salvarLocalmente();
        if (_driveService.isConectado) {
          await _salvarNoDrive();
        }
      } catch (e) {
        print('⚠️ Erro ao salvar coleções: $e');
        // Não falha a geração por problemas de salvamento
      }
    } catch (e) {
      print('❌ Erro ao gerar coleções: $e');
      // Não propaga o erro para não quebrar a inicialização
    }
  }

  /// Gera nome baseado no tipo e coleção
  String _gerarNomePorTipo(Tipo tipo, bool isNostalgico) {
    final sufixo = isNostalgico ? ' Nostálgico' : '';
    return tipo.monsterName + sufixo;
  }

  /// Obtém tipo secundário baseado no principal
  Tipo _obterTipoSecundario(Tipo tipoPrincipal, [List<Tipo>? tiposDisponiveis]) {
    final tipos = (tiposDisponiveis ?? Tipo.values).where((t) => t != tipoPrincipal).toList();
    if (tipos.isEmpty) return Tipo.normal; // Fallback seguro
    tipos.shuffle();
    return tipos.first;
  }

  /// Carrega dados do Google Drive
  Future<void> _carregarDoDrive() async {
    try {
      if (!_driveService.isConectado) return;
      
      // Cria pasta monstros/aventura se não existir
      await _criarPastaNoDrive();
      
      final jsonData = await _driveService.baixarJson('monstros/aventura/monstros_lista.json');
      if (jsonData != null && jsonData['monstros'] is List) {
        _cache.clear();
        final List<dynamic> monstrosJson = jsonData['monstros'];
        
        for (final monstroJson in monstrosJson) {
          try {
            final monstro = MonstroAventura.fromJson(monstroJson);
            _cache.add(monstro);
          } catch (e) {
            print('⚠️ Erro ao carregar monstro individual: $e');
          }
        }
        
        print('✅ ${_cache.length} monstros carregados do Drive');
      }
    } catch (e) {
      print('❌ Erro ao carregar do Drive: $e');
    }
  }

  /// Salva dados no Google Drive
  Future<void> _salvarNoDrive() async {
    try {
      if (!_driveService.isConectado) return;
      
      await _criarPastaNoDrive();
      
      final jsonData = {
        'monstros': _cache.map((m) => m.toJson()).toList(),
        'ultimaAtualizacao': DateTime.now().toIso8601String(),
      };
      
      await _driveService.salvarJsonEmPasta('monstros/aventura', 'monstros_lista.json', jsonData);
      print('✅ Lista de monstros salva no Drive');
    } catch (e) {
      print('❌ Erro ao salvar no Drive: $e');
    }
  }

  /// Cria estrutura de pastas no Drive
  Future<void> _criarPastaNoDrive() async {
    try {
      // Implementar criação de pastas quando necessário
      // Por enquanto, o GoogleDriveService deve lidar com isso
    } catch (e) {
      print('⚠️ Erro ao criar pastas: $e');
    }
  }

  /// Salva imagem no Drive e retorna URL
  Future<String> _salvarImagemNoDrive(String monstroId, Uint8List imagemBytes) async {
    try {
      if (!_driveService.isConectado) {
        throw Exception('Drive não conectado');
      }
      
      // Salva imagem na pasta monstros/aventura/imagens/
      final nomeArquivo = 'monstro_$monstroId.webp';
      await _driveService.salvarArquivo('monstros/aventura/imagens/$nomeArquivo', imagemBytes);
      
      return 'monstros/aventura/imagens/$nomeArquivo';
    } catch (e) {
      print('❌ Erro ao salvar imagem no Drive: $e');
      rethrow;
    }
  }

  /// Processa e redimensiona imagem
  Future<Uint8List> _processarImagem(Uint8List imagemOriginal) async {
    try {
      // Decodifica imagem
      final imagem = img.decodeImage(imagemOriginal);
      if (imagem == null) {
        throw Exception('Não foi possível decodificar a imagem');
      }

      // Redimensiona mantendo proporção (máximo 512x512)
      final imagemRedimensionada = img.copyResize(
        imagem,
        width: imagem.width > imagem.height ? 512 : null,
        height: imagem.height > imagem.width ? 512 : null,
        maintainAspect: true,
      );

      // Converte para PNG com qualidade reduzida (WebP não disponível na versão atual)
      final imagemProcessada = img.encodePng(imagemRedimensionada);
      
      print('✅ Imagem processada: ${imagemOriginal.length} → ${imagemProcessada.length} bytes');
      return Uint8List.fromList(imagemProcessada);
    } catch (e) {
      print('❌ Erro ao processar imagem: $e');
      rethrow;
    }
  }

  /// Carrega dados localmente
  Future<void> _carregarLocalmente() async {
    try {
      if (kIsWeb) return;
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/monstros_aventura.json');
      
      if (!await file.exists()) return;
      
      final contents = await file.readAsString();
      final Map<String, dynamic> jsonData = json.decode(contents);
      
      if (jsonData['monstros'] is List) {
        _cache.clear();
        final List<dynamic> monstrosJson = jsonData['monstros'];
        
        for (final monstroJson in monstrosJson) {
          try {
            final monstro = MonstroAventura.fromJson(monstroJson);
            _cache.add(monstro);
          } catch (e) {
            print('⚠️ Erro ao carregar monstro local: $e');
          }
        }
        
        print('✅ ${_cache.length} monstros carregados localmente');
      }
    } catch (e) {
      print('❌ Erro ao carregar localmente: $e');
    }
  }

  /// Salva dados localmente
  Future<void> _salvarLocalmente() async {
    try {
      if (kIsWeb) return;
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/monstros_aventura.json');
      
      final jsonData = {
        'monstros': _cache.map((m) => m.toJson()).toList(),
        'ultimaAtualizacao': DateTime.now().toIso8601String(),
      };
      
      await file.writeAsString(json.encode(jsonData));
      print('💾 Lista de monstros salva localmente');
    } catch (e) {
      print('❌ Erro ao salvar localmente: $e');
    }
  }
}
