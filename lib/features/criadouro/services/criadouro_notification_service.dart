import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/mascote.dart';
import '../models/config_criadouro.dart';

/// Serviço de notificações do Criadouro
/// Verifica periodicamente os mascotes e envia alertas
class CriadouroNotificationService {
  static final CriadouroNotificationService _instance =
      CriadouroNotificationService._internal();
  factory CriadouroNotificationService() => _instance;
  CriadouroNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  Timer? _checkTimer;
  bool _isInitialized = false;

  // Callbacks para buscar dados atualizados
  Map<String, Mascote> Function()? _getMascotes;
  ConfigCriadouro Function()? _getConfig;

  // Controle de notificações já enviadas (evita spam)
  final Set<String> _notificacoesEnviadas = {};
  DateTime? _ultimaVerificacao;

  /// IDs de notificação
  static const int _idFome = 100;
  static const int _idSede = 101;
  static const int _idHigiene = 102;
  static const int _idAlegria = 103;
  static const int _idSaude = 104;
  static const int _idDoenca = 105;
  static const int _idCritico = 106;

  /// Inicializa o serviço de notificações
  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _isInitialized = true;
    print('✅ [CriadouroNotificationService] Inicializado');
  }

  /// Solicita permissão de notificação (Android 13+)
  Future<bool> requestPermission() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      print('🔔 [CriadouroNotificationService] Permissão: $granted');
      return granted ?? false;
    }
    return true;
  }

  /// Configura os callbacks para buscar dados
  void configurar({
    required Map<String, Mascote> Function() getMascotes,
    required ConfigCriadouro Function() getConfig,
  }) {
    _getMascotes = getMascotes;
    _getConfig = getConfig;
  }

  /// Inicia a verificação periódica (a cada 5 minutos)
  void iniciarMonitoramento() {
    pararMonitoramento();

    print('🚀 [CriadouroNotificationService] Iniciando monitoramento');

    // Verifica imediatamente
    _verificarMascotes();

    // Timer para verificações periódicas (5 minutos)
    _checkTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _verificarMascotes();
    });
  }

  /// Para o monitoramento
  void pararMonitoramento() {
    if (_checkTimer != null) {
      _checkTimer!.cancel();
      _checkTimer = null;
      print('⏹️ [CriadouroNotificationService] Monitoramento parado');
    }
  }

  /// Verifica todos os mascotes e envia notificações se necessário
  void _verificarMascotes() {
    if (_getMascotes == null || _getConfig == null) return;

    final config = _getConfig!();
    if (!config.notificacoesAtivas) {
      print('🔕 [CriadouroNotificationService] Notificações desativadas');
      return;
    }

    final mascotes = _getMascotes!();
    if (mascotes.isEmpty) return;

    final agora = DateTime.now();

    // Limpa notificações antigas (após 30 minutos)
    if (_ultimaVerificacao != null &&
        agora.difference(_ultimaVerificacao!).inMinutes > 30) {
      _notificacoesEnviadas.clear();
    }
    _ultimaVerificacao = agora;

    print(
        '🔍 [CriadouroNotificationService] Verificando ${mascotes.length} mascotes');

    for (final mascote in mascotes.values) {
      // Ignora mascotes mortos
      if (mascote.deveriaMorrer) continue;

      _verificarBarra(
        mascote: mascote,
        barra: 'fome',
        valor: mascote.fome,
        limite: config.limiteFome,
        emoji: '🍖',
        id: _idFome + mascote.id.hashCode % 100,
      );

      _verificarBarra(
        mascote: mascote,
        barra: 'sede',
        valor: mascote.sede,
        limite: config.limiteSede,
        emoji: '💧',
        id: _idSede + mascote.id.hashCode % 100,
      );

      _verificarBarra(
        mascote: mascote,
        barra: 'higiene',
        valor: mascote.higiene,
        limite: config.limiteHigiene,
        emoji: '🧼',
        id: _idHigiene + mascote.id.hashCode % 100,
      );

      _verificarBarra(
        mascote: mascote,
        barra: 'alegria',
        valor: mascote.alegria,
        limite: config.limiteAlegria,
        emoji: '😢',
        id: _idAlegria + mascote.id.hashCode % 100,
      );

      _verificarBarra(
        mascote: mascote,
        barra: 'saude',
        valor: mascote.saude,
        limite: config.limiteSaude,
        emoji: '❤️',
        id: _idSaude + mascote.id.hashCode % 100,
      );

      // Verifica doença
      if (config.notificarDoenca && mascote.estaDoente) {
        final chaveNotif = '${mascote.id}_doenca';
        if (!_notificacoesEnviadas.contains(chaveNotif)) {
          _enviarNotificacao(
            id: _idDoenca + mascote.id.hashCode % 100,
            title: '🤒 ${mascote.nome} está doente!',
            body: 'Use um remédio para curar seu mascote.',
          );
          _notificacoesEnviadas.add(chaveNotif);
        }
      }

      // Verifica estado crítico
      if (mascote.estaCritico) {
        final chaveNotif = '${mascote.id}_critico';
        if (!_notificacoesEnviadas.contains(chaveNotif)) {
          _enviarNotificacao(
            id: _idCritico + mascote.id.hashCode % 100,
            title: '⚠️ ${mascote.nome} está em estado CRÍTICO!',
            body: 'Cuide dele urgentemente ou ele pode morrer!',
          );
          _notificacoesEnviadas.add(chaveNotif);
        }
      }
    }
  }

  void _verificarBarra({
    required Mascote mascote,
    required String barra,
    required double valor,
    required int limite,
    required String emoji,
    required int id,
  }) {
    if (valor < limite) {
      final chaveNotif = '${mascote.id}_$barra';
      if (!_notificacoesEnviadas.contains(chaveNotif)) {
        final nomeBarra = _nomeAmigavel(barra);
        _enviarNotificacao(
          id: id,
          title: '$emoji ${mascote.nome} precisa de atenção!',
          body: '$nomeBarra está em ${valor.toInt()}%',
        );
        _notificacoesEnviadas.add(chaveNotif);
      }
    }
  }

  String _nomeAmigavel(String barra) {
    switch (barra) {
      case 'fome':
        return 'Fome';
      case 'sede':
        return 'Sede';
      case 'higiene':
        return 'Higiene';
      case 'alegria':
        return 'Alegria';
      case 'saude':
        return 'Saúde';
      default:
        return barra;
    }
  }

  /// Envia uma notificação
  Future<void> _enviarNotificacao({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'criadouro_channel',
      'Criadouro',
      channelDescription: 'Notificações do Criadouro',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details);
    print('🔔 [CriadouroNotificationService] Notificação: $title');
  }

  /// Limpa uma notificação específica (quando o usuário cuidar do mascote)
  void limparNotificacao(String mascoteId, String tipo) {
    _notificacoesEnviadas.remove('${mascoteId}_$tipo');
  }

  /// Limpa todas as notificações de um mascote
  void limparNotificacoesMascote(String mascoteId) {
    _notificacoesEnviadas.removeWhere((key) => key.startsWith(mascoteId));
  }

  /// Cancela todas as notificações
  Future<void> cancelarTodas() async {
    await _notifications.cancelAll();
    _notificacoesEnviadas.clear();
    print('🗑️ [CriadouroNotificationService] Todas notificações canceladas');
  }

  /// Verifica se o monitoramento está ativo
  bool get isMonitorando => _checkTimer != null && _checkTimer!.isActive;

  /// Força uma verificação imediata
  void verificarAgora() {
    _verificarMascotes();
  }
}
