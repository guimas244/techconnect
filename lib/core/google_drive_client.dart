import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/user_provider.dart';

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();
  GoogleAuthClient(this._headers);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}

class DriveClientFactory {
  static const String FOLDER_ID = "1R_WQTo21NNQyZIj3rMPaaUKj1-eGJPfV";
  static const String CLIENT_ID = "163239542287-3c3rq1k6j9k1s5fmfauvo2p6q157nbpq.apps.googleusercontent.com";

  static final List<String> scopes = [
    drive.DriveApi.driveFileScope,
    drive.DriveApi.driveReadonlyScope,
  ];

  /// Método temporário para desenvolvimento - sem OAuth
  static Future<drive.DriveApi> createDebug() async {
    print('🔐 [DEBUG] DriveClientFactory: Modo DEBUG - Sem autenticação real');
    throw Exception('Modo DEBUG: Configure o SHA-1 no Google Cloud Console primeiro');
  }

  static Future<drive.DriveApi> create({ProviderContainer? container}) async {
    print('🔐 [DEBUG] DriveClientFactory: Iniciando GoogleSignIn...');
    
    try {
      final gs = GoogleSignIn(
        scopes: scopes,
        // Remover clientId/serverClientId no Android - deixar só os scopes
        // serverClientId: CLIENT_ID, 
      );
      print('🔐 [DEBUG] DriveClientFactory: GoogleSignIn criado com scopes: $scopes');
      print('🔐 [DEBUG] DriveClientFactory: Usando configuração do google-services.json');
      
      print('🔐 [DEBUG] DriveClientFactory: Verificando usuário atual...');
      var account = await gs.signInSilently();
      
      if (account == null) {
        print('🔐 [DEBUG] DriveClientFactory: Nenhum usuário logado, iniciando login interativo...');
        account = await gs.signIn();
        
        if (account == null) {
          print('❌ [DEBUG] DriveClientFactory: Login cancelado pelo usuário');
          throw Exception("Login cancelado pelo usuário");
        }
      }
      
      print('✅ [DEBUG] DriveClientFactory: Usuário logado: ${account.email}');
      
      // Define o email no provider global para ser usado pela aplicação
      if (container != null) {
        print('📧 [DEBUG] DriveClientFactory: Definindo email no provider: ${account.email}');
        container.read(currentUserEmailStateProvider.notifier).state = account.email;
      }
      
      print('🔐 [DEBUG] DriveClientFactory: Obtendo headers de autenticação...');
      
      final headers = await account.authHeaders;
      print('✅ [DEBUG] DriveClientFactory: Headers obtidos: ${headers.keys.toList()}');
      
      print('🔐 [DEBUG] DriveClientFactory: Criando DriveApi...');
      final driveApi = drive.DriveApi(GoogleAuthClient(headers));
      print('✅ [DEBUG] DriveClientFactory: DriveApi criado com sucesso');
      
      return driveApi;
    } catch (e) {
      print('❌ [DEBUG] Erro na autenticação: $e');
      print('❌ [DEBUG] SOLUÇÃO: Configure o SHA-1 fingerprint no Google Cloud Console');
      print('❌ [DEBUG] SHA-1: EE:9D:36:26:2A:AE:45:A8:00:71:22:39:A0:E1:C5:6D:39:1F:3F:1F');
      print('❌ [DEBUG] Package: com.example.techconnect');
      rethrow;
    }
  }

  /// Cria um cliente HTTP autenticado para outras APIs (como Sheets)
  static Future<http.Client> createHttpClient({ProviderContainer? container}) async {
    print('🔐 [DEBUG] DriveClientFactory: Criando cliente HTTP para Sheets...');
    
    try {
      final gs = GoogleSignIn(
        scopes: scopes,
      );
      
      GoogleSignInAccount? account = await gs.signInSilently();
      if (account == null) {
        print('🔐 [DEBUG] Login necessário para cliente HTTP...');
        account = await gs.signIn();
        
        if (account == null) {
          print('❌ [DEBUG] Login cancelado pelo usuário');
          throw Exception("Login cancelado pelo usuário");
        }
      }
      
      final headers = await account.authHeaders;
      final client = GoogleAuthClient(headers);
      
      print('✅ [DEBUG] Cliente HTTP autenticado criado com sucesso');
      return client;
    } catch (e) {
      print('❌ [DEBUG] Erro ao criar cliente HTTP: $e');
      rethrow;
    }
  }
}
