import 'dart:async';

import 'package:harpia/app/data/repository/user_google_repository.dart';
import 'package:harpia/app/modules/login/services/auth_google_service.dart';
import 'package:harpia/app/routes/app_pages.dart';
import 'package:get/get.dart';

class AuthGoogleController extends GetxController {
  AuthGoogleController();

  late final AuthGoogleService _authGoogle = AuthGoogleService();
  late final UserGoogleRepository _userRepository = UserGoogleRepository();
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
      await _userRepository.saveUserGoogleModel(user);
      //await Get.find<UserController>().loadCurrentUser();
      Get.offNamed(Routes.MONITORA_UFF);
    } else {
      Get.snackbar(
        "Erro de Login",
        "Falha ao autenticar o usuário.",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

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
