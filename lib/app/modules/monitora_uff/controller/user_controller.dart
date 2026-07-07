import 'package:flutter/foundation.dart';
import 'package:harpia/app/data/repository/user_google_repository.dart';
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
      try {
        final googleUser = await UserGoogleRepository().getUserGoogleModel();
        print('Hive user: ${googleUser?.email} / ${googleUser?.name}');
        _googleName = googleUser?.name;
      } catch (e) {
        debugPrint('Erro ao ler usuário Google do Hive: $e');
      }

      _user.value = await _initializeUser();
      print('Loaded user: ${_user.value?.email} / funcao: ${_user.value?.funcao}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<UserModel?> _initializeUser() async {
    final googleUser = await UserGoogleRepository().getUserGoogleModel();
    final email = googleUser?.email ?? "";
    print('Email usado no lookup: $email');
    if (email.isEmpty) return null;

    final user = await FirebaseProvider().getUserByEmail(email);
    //print('Firestore result: ${user?.email} / ${user?.funcao}');
    return user;
  }

  bool isAdmin() => _user.value?.funcao == 'administrador';

  bool isMonitor() => _user.value?.funcao == 'monitor';

  void deleteUser(String email) => FirebaseProvider().deleteUserByEmail(email);

  String getUserName() {
    return user!.nome ??
        _googleName ??
        "Nome não informado";
  }
}
