import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:harpia/app/config/secrets.dart';
import 'package:harpia/app/data/models/user_google_model.dart';
import 'package:harpia/app/data/repository/user_google_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthGoogleService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final UserGoogleRepository _userRepository = UserGoogleRepository();
  final FirebaseApp _app = Firebase.app();
  late final fb.FirebaseAuth _auth = fb.FirebaseAuth.instanceFor(app: _app);

  // stream para avisar a UI/controller quando o login web (via evento) terminar
  final _webSignInController = StreamController<UserGoogleModel?>.broadcast();
  Stream<UserGoogleModel?> get onWebSignIn => _webSignInController.stream;

  late final Future<void> _init = _initialize();

  Future<void> ensureInitialized() => _init;

  AuthGoogleService();

  Future<void> _initialize() async {
    debugPrint('AuthGoogleService: initialize start');

    await _googleSignIn.initialize(
      // clientId é obrigatório na web
      // NOTE: estou usando o mesmo id para clientId e serverClientId
      clientId: kIsWeb ? Secrets.umpGoogleServerWebClientId : null,
      serverClientId: kIsWeb ? null : Secrets.harpiaGoogleServerWebClientId,
    );

    debugPrint('AuthGoogleService: initialize done');

    // só na web o login chega via evento (o botão é do próprio Google)
    if (kIsWeb) {
      //_googleSignIn.authenticationEvents.listen(_onWebAuthEvent);
      _googleSignIn.authenticationEvents.listen((event) {
        debugPrint('AuthGoogleService event: $event');
        _onWebAuthEvent(event);
      });
    }
  }
  
  Future<void> _onWebAuthEvent(GoogleSignInAuthenticationEvent event) async {
    debugPrint('AuthGoogleService _onWebAuthEvent: ${event.runtimeType}');

    if (event is GoogleSignInAuthenticationEventSignIn) {
      debugPrint('AuthGoogleService sign-in event user: ${event.user.email}');
      final user = await _signIn(event.user);
      debugPrint('AuthGoogleService _signIn result: ${user?.email}');
      _webSignInController.add(user);
      return;
    } 
    if (event is GoogleSignInAuthenticationEventSignOut) {
      //_webSignInController.add(null);
      debugPrint('AuthGoogleService sign-out event');
      return;
    }
  }

  Future<UserGoogleModel?> signInGoogle() async {
    await _init;

    if (kIsWeb) return null;

    try {
      //await _init;
      var account = await _googleSignIn.authenticate();
      return _signIn(account);
    } catch (e) {
      debugPrint('Error during Google sign-in: $e');
      return null;
    }
  }

  Future<UserGoogleModel?> _signIn(GoogleSignInAccount account) async {
    try {
      final GoogleSignInAuthentication googleAuth = account.authentication;
      final authCredential = fb.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      var userCredential = await _auth.signInWithCredential(authCredential);

      return await _createUserDoc(userCredential);
    } catch (e) {
      debugPrint('Error during Google sign-in: $e');
      return null;
    }
  }

  Future<UserGoogleModel?> _createUserDoc(
    fb.UserCredential userCredential,
  ) async {
    try {
      final userDoc = await _userRepository.createUserDoc(
        userCredential.user!.email ?? '',
        userCredential.user!.displayName ?? '',
        userCredential.user!.uid,
        userCredential.user!.photoURL ?? '',
      );

      return userDoc;
    } catch (err) {
      debugPrint(err.toString());
      return null;
    }
  }

  Future<UserGoogleModel?> trySignInGoogle() async {
    await _init;
    try {
      final account = _googleSignIn.attemptLightweightAuthentication();
      if (account == null) {
        return null;
      }
      final googleUser = await account;
      return googleUser != null ? await _signIn(googleUser) : null;
    } catch (e) {
      debugPrint('Error initializing GoogleSignIn: $e');
      return null;
    }
  }

  Future<void> logoutGoogle() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<String?> getFirebaseIdToken() async {
    // Pega o usuário logado atualmente no Firebase
    final user = _auth.currentUser;

    if (user != null) {
      // getIdToken(true) força a atualização do token caso ele esteja expirado
      return await user.getIdToken(true); 
    }
    return null;
  }

  void dispose() {
    _webSignInController.close();
  }
}
