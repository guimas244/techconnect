// Simulação de serviço de autenticação sem Firebase
class SimpleUser {
  final String email;
  final String uid;
  
  SimpleUser({required this.email, required this.uid});
}

class AuthService {
  Future<SimpleUser?> signInWithEmail(String email, String password) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      if (email.isNotEmpty && password.length >= 6) {
        return SimpleUser(
          email: email, 
          uid: 'user_${DateTime.now().millisecondsSinceEpoch}'
        );
      } else {
        throw 'Email ou senha inválidos';
      }
    } catch (e) {
      throw e.toString();
    }
  }
}
