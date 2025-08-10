// Simulação de repositório de autenticação sem Firebase
class SimpleUser {
  final String email;
  final String uid;
  
  SimpleUser({required this.email, required this.uid});
}

class AuthRepository {
  // Simulação de usuário atual
  SimpleUser? _currentUser;

  // Usuário atual
  SimpleUser? get currentUser => _currentUser;

  // Login com email e senha (simulado)
  Future<SimpleUser?> signInWithEmail(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    
    if (email.isNotEmpty && password.length >= 6) {
      _currentUser = SimpleUser(
        email: email, 
        uid: 'user_${DateTime.now().millisecondsSinceEpoch}'
      );
      return _currentUser;
    } else {
      throw 'Email ou senha inválidos';
    }
  }

  // Registro com email e senha (simulado)
  Future<SimpleUser?> signUpWithEmail(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    
    if (email.isNotEmpty && password.length >= 6) {
      _currentUser = SimpleUser(
        email: email, 
        uid: 'user_${DateTime.now().millisecondsSinceEpoch}'
      );
      return _currentUser;
    } else {
      throw 'Email ou senha inválidos';
    }
  }

  // Login como convidado (simulado)
  Future<SimpleUser?> signInAnonymously() async {
    await Future.delayed(const Duration(seconds: 1));
    
    _currentUser = SimpleUser(
      email: 'guest@example.com', 
      uid: 'guest_${DateTime.now().millisecondsSinceEpoch}'
    );
    return _currentUser;
  }

  // Logout
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
  }

  // Reset de senha (simulado)
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    
    if (email.isEmpty) {
      throw 'Email inválido';
    }
    // Simula envio de email de reset
  }
}
