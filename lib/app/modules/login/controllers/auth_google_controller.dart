import 'dart:async';

import 'package:flutter/material.dart';
import 'package:harpia/app/data/models/gd_groups_google_model.dart';
import 'package:harpia/app/data/repository/user_data_repository.dart';
import 'package:harpia/app/data/repository/user_google_repository.dart';
import 'package:harpia/app/modules/login/services/auth_google_service.dart';
import 'package:harpia/app/routes/app_pages.dart';
import 'package:get/get.dart';

class AuthGoogleController extends GetxController {
  AuthGoogleController();

  late final AuthGoogleService _authGoogle = AuthGoogleService();
  late final UserGoogleRepository _userRepository = UserGoogleRepository();
  late final UserDataRepository _userDataRepository = UserDataRepository();
  StreamSubscription? _webSignInSub;

  // indica se o GoogleSignIn já terminou de inicializar
  final RxBool googleReady = false.obs;

  @override
  void onInit() {
    super.onInit();
    _webSignInSub = _authGoogle.onWebSignIn.listen(_handleLoginResult);

    _authGoogle.ensureInitialized().then((_) {
      googleReady.value = true;
    }).catchError((_) {
      googleReady.value = true;
    });
  }

  Future<void> _handleLoginResult(dynamic user) async {
    if (user != null) {
      String? token = await _authGoogle.getFirebaseIdToken();
      await _userRepository.saveUserGoogleModel(user);
      //await Get.find<UserController>().loadCurrentUser();
      await _getGdiGroupsGoogle(token ?? '', user.email);
      //await _getGoogleGroupMembers(token ?? '', 'grupos.harpia@id.uff.br'); // TODO: estou passando o email do grupo diretamente aqui. Trocar.
      Get.offNamed(Routes.MONITORA_UFF);
    } else {
      Get.snackbar(
        "Erro de Login",
        "Falha ao autenticar o usuário.",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _getGdiGroupsGoogle(String token, String email) async {
    try {
      GdiGroupsGoogle gdiGroups = await _userRepository.getGdiGroupsGoogle(
        token,
        email,
      );
      // TODO: o comando abaixo retorna a promessa de uma String s,
      // mas nada é feito com s. Por isso, talvez eu possa remover o await.
      await _userDataRepository.updateGdiGroupsGoogle(gdiGroups);
    } catch (e) {
      debugPrint("Erro ao obter grupos GDI Google: $e");
    }
  }

  //Future<void> _getGoogleGroupMembers(String token, String groupEmail) async {
  //  try {
  //    GdiGroupsGoogle gdiGroups = await _userRepository.getGdiGroupsGoogle(
  //      token,
  //      groupEmail,
  //    );
  //    
  //    // TODO: o comando abaixo retorna a promessa de uma String s,
  //    // mas nada é feito com s. Por isso, talvez eu possa remover o await.
  //    await _userDataRepository.updateGdiGroupsGoogle(gdiGroups);
  //  } catch (e) {
  //    debugPrint("Erro ao obter grupos GDI Google: $e");
  //  }
  //}
  
  void loginGoogle() async {
    try {
      final user = await _authGoogle.signInGoogle();
      if (user != null) _handleLoginResult(user);
    } catch (e) {
      Get.snackbar(
        "Erro de Login externo",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    }
  }

  Future<void> tryLogin() async {
    var hasLogged = await _authGoogle.trySignInGoogle();
    if (hasLogged != null) {
      //await Get.find<UserController>().loadCurrentUser();
      String? token = await _authGoogle.getFirebaseIdToken();
      await _getGdiGroupsGoogle(token ?? '', hasLogged.email);
      Get.offNamed(Routes.MONITORA_UFF);
    } else {
      Get.offNamed(Routes.LOGIN);
    }
  }

  Future<void> logout() async {
    await _authGoogle.logoutGoogle();
    await _userRepository.deleteUserGoogleModel();
    Get.offAllNamed(Routes.LOGIN);
  }

  @override
  void onClose() {
    _webSignInSub?.cancel();
    _authGoogle.dispose();
    super.onClose();
  }
}
