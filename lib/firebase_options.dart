import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'AIzaSyArefutuIzGoGRdFMLUSClWXMsXDYsvvNo',
      authDomain: 'solance-auth.firebaseapp.com',
      projectId: 'solance-auth',
      storageBucket: 'solance-auth.appspot.com',
      messagingSenderId: '626596353810',
      appId: '1:626596353810:web:f7b75b2b8ac3802f1705cb',
    );
  }
}
