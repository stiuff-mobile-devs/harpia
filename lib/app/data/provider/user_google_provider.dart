import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:harpia/app/data/models/user_google_model.dart';
import 'package:hive/hive.dart';

enum UserRole { user }

class UserGoogleProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    //app: Firebase.app('uffmobileplus'),
    app: Firebase.app()
  );
  final String _hiveBox = 'user_google_data';
  final String _hiveKey = 'current_user';

  Future<UserGoogleModel> createUserDoc(
    String email,
    String name,
    String uid,
    String urlImage,
  ) async {
    // Verifica se já existe um usuário com este email no Firestore
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    UserGoogleModel user;
    if (query.docs.isNotEmpty) {
      // Usuário já existe, retorna o existente
      final data = query.docs.first.data();
      user = UserGoogleModel(
        id: query.docs.first.id,
        name: data['name'] as String?,
        email: data['email'] as String,
        urlImage: data['urlImage'] as String?,
        createdAt: data['createdAt'] != null
            ? DateTime.tryParse(data['createdAt'])
            : null,
      );
    } else {
      // Usuário não existe, cria novo
      user = UserGoogleModel(
        name: name,
        email: email,
        id: uid,
        urlImage: urlImage,
        createdAt: DateTime.now(),
      );
      await createUserDocInFirebase(user);
    }

    await saveUserGoogleModel(user);
    return user;
  }

  Future<void> createUserDocInFirebase(UserGoogleModel user) async {
    DocumentReference docRef = await _firestore.collection('users').add({
      'name': user.name,
      'email': user.email,
      'urlImage': user.urlImage,
      'createdAt': user.createdAt?.toIso8601String(),
    });
    user.id = docRef.id;
  }

  Future<String> saveUserGoogleModel(UserGoogleModel user) async {
    try {
      var box = await Hive.openBox<UserGoogleModel>(_hiveBox);
      await box.put(_hiveKey, user);
      print('Saved Google user in Hive: ${user.email}');
      return "success";
    } catch (e) {
      print('Error saving Google user in Hive: $e');
      return "Erro ao salvar usuário Google no Hive: $e";
    }
  }

  Future<UserGoogleModel?> getUserGoogleModel() async {
    try {
      var box = await Hive.openBox<UserGoogleModel>(_hiveBox);
      final user = box.get(_hiveKey);
      print('Read Google user from Hive: ${user?.email}');
      return user;
    } catch (e) {
      throw Exception("Erro ao buscar usuário Google do Hive: $e");
    }
  }

  Future<String> deleteUserGoogleModel() async {
    try {
      var box = await Hive.openBox<UserGoogleModel>(_hiveBox);
      await box.delete(_hiveKey);
      return "success";
    } catch (e) {
      return "Erro ao deletar usuário Google do Hive: $e";
    }
  }

  Future<String> clearAllUserGoogle() async {
    try {
      var box = await Hive.openBox<UserGoogleModel>(_hiveBox);
      await box.clear();
      return "success";
    } catch (e) {
      return "Erro ao limpar usuários Google do Hive: $e";
    }
  }

  Future<bool> hasUserGoogle() async {
    try {
      var box = await Hive.openBox<UserGoogleModel>(_hiveBox);
      return box.containsKey(_hiveKey);
    } catch (e) {
      return false;
    }
  }
}
