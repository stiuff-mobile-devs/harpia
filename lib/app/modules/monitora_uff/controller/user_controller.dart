import 'package:flutter/material.dart';
import 'package:harpia/app/data/repository/user_google_repository.dart';
import 'package:harpia/app/modules/monitora_uff/controller/google_groups_controller.dart';
import 'package:harpia/app/modules/monitora_uff/data/provider/firebase_provider.dart';
import 'package:harpia/app/modules/monitora_uff/models/user_model.dart';
import 'package:get/get.dart';

class UserController extends GetxController {
  final _user = Rxn<UserModel>();
  UserModel? get user => _user.value;

  String? _googleName;

  final allFirebaseUsers = <UserModel>[].obs;
  final isLoading = true.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await loadCurrentUser();
    allFirebaseUsers.bindStream(FirebaseProvider().streamAllUsers());
  }

  Future<void> loadCurrentUser() async {
    isLoading.value = true;
    try {
      final googleUser = await UserGoogleRepository().getUserGoogleModel();
      debugPrint('Hive user: ${googleUser?.email} / ${googleUser?.name}');
      _googleName = googleUser?.name;
      final email = googleUser?.email ?? "";

      if (email.isEmpty) {
        _user.value = null;
        return;
      }

      // 1. Carregar dados do Google Groups primeiro
      final googleGroupsCtrl = Get.find<GoogleGroupsController>();

      // Aguardar _loadGroups() terminar
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return googleGroupsCtrl.isLoading.value;
      });

      // 2. Verificar se é admin (membro de GH)
      // TODO: talvez eu não precise de UserModel nesta classe. 
      // apenas usar isRootMember bastaria.
      if (googleGroupsCtrl.isRootMember) {
        _user.value = UserModel(
          email: email,
          nome: _googleName,
          funcao: 'administrador',
        );
        debugPrint('Usuário definido como administrador: $email');
        return;
      }

      // 3. Verificar se é monitor (membro de algum GH')
      final isMonitor = await googleGroupsCtrl.isUserInAnySubgroup(email);

      if (isMonitor) {
        // Tentar carregar do Firestore (pode já existir)
        var firestoreUser = await _initializeUser();

        if (firestoreUser != null) {
          // Manter dados existentes do Firestore, mas garantir funcao='monitor'
          firestoreUser.funcao = 'monitor';
          _user.value = firestoreUser;
        } else {
          // Criar documento no Firestore
          await FirebaseProvider().setUser(UserModel(
            email: email,
            nome: _googleName,
            funcao: 'monitor',
          ));

          // Recarregar do Firestore para pegar o documento completo
          _user.value = await _initializeUser();
        }
        debugPrint('Usuário definido como monitor: $email');
      } else {
        // Não é admin nem monitor
        _user.value = null;
        debugPrint('Usuário não autorizado: $email');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<UserModel?> _initializeUser() async {
    final googleUser = await UserGoogleRepository().getUserGoogleModel();
    final email = googleUser?.email ?? "";
    debugPrint('Email usado no lookup: $email');
    if (email.isEmpty) return null;

    final user = await FirebaseProvider().getUserByEmail(email);
    //print('Firestore result: ${user?.email} / ${user?.funcao}');
    return user;
  }

  bool isAdmin() => _user.value?.funcao == 'administrador';

  bool isTrackable() => _user.value?.funcao == 'monitor';

  void deleteUser(String email) => FirebaseProvider().deleteUserByEmail(email);

  String getUserName() {
    return user!.nome ??
        _googleName ??
        "Nome não informado";
  }
}
