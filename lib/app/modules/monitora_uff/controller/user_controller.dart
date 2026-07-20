import 'package:flutter/material.dart';
import 'package:harpia/app/data/repository/user_google_repository.dart';
import 'package:harpia/app/modules/monitora_uff/controller/google_groups_controller.dart';
import 'package:harpia/app/modules/monitora_uff/data/provider/firebase_provider.dart';
import 'package:harpia/app/modules/monitora_uff/models/google_group_member_model.dart';
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

      // Tentar carregar do Firestore
      var firestoreUser = await _initializeUser();
      if (firestoreUser != null) {
        _user.value = firestoreUser;
      } else {
        // Criar documento no Firestore
        await FirebaseProvider().setUser(UserModel(
          email: email,
          nome: _googleName,
        ));
        _user.value = await _initializeUser();
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
    return user;
  }

  bool isTrackable() {
    final googleGroupsCtrl = Get.find<GoogleGroupsController>();
    final currentUserEmail = _user.value?.email;

    if (currentUserEmail == null) return false;

    // Procura o usuário logado entre os membros do grupo observado
    final member = googleGroupsCtrl.observedMembers.firstWhereOrNull(
      (m) => m.email == currentUserEmail,
    );

    // Retorna true se for manager ou member (owner não conta como trackable)
    return member?.role == GoogleGroupRole.manager
      || member?.role == GoogleGroupRole.member;
  }

  String getUserName() {
    return user!.nome ??
        _googleName ??
        "Nome não informado";
  }
}
