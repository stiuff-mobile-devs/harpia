import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:harpia/app/data/connections/google_service.dart';
import 'package:harpia/app/modules/monitora_uff/models/google_group_model.dart';
import 'package:harpia/app/modules/monitora_uff/models/google_group_member_model.dart';

class GoogleGroupsController extends GetxController {
  final GoogleService _googleService = GoogleService();
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  RxString observedGroup = RxString('Nenhum');
  RxList<GoogleGroupMember> observedMembers = RxList();

  /// Email do grupo raiz que contém os subgrupos do Harpia.
  /// Em debug, usa um grupo de teste; em release, o grupo de produção.
  static String get rootGroupEmail =>
      kReleaseMode ? 'grupos.harpia@id.uff.br' : 'grupos.harpia@id.uff.br';

  /// Lista de grupos que o usuário logado pode observar.
  /// Representa os subgrupos (type == GROUP) de [rootGroupEmail].
  final RxList<GoogleGroupModel> _observableGoogleGroups = RxList<GoogleGroupModel>();
  List<GoogleGroupModel> get googleGroups => _observableGoogleGroups;

  /// Indica se o carregamento dos grupos já foi concluído.
  final RxBool isLoading = RxBool(true);

  @override
  void onInit() {
    super.onInit();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint("Usuário não autenticado.");
        isLoading.value = false;
        return;
      }

      final token = await user.getIdToken(true);
      if (token == null) {
        debugPrint("Token não disponível.");
        isLoading.value = false;
        return;
      }

      final userEmail = user.email;
      if (userEmail == null) {
        debugPrint("Email do usuário não disponível.");
        isLoading.value = false;
        return;
      }

      // 1. Buscar todas as entidades do grupo raiz 'grupos.harpia@id.uff.br'
      final entities = await _googleService.getGroupEntities(token, rootGroupEmail);

      // 2. Filtrar entidades para manter apenas subgrupos, i.e.,
      // ficar apenas com as entidades cujo 'type' == 'GROUP'
      // e cujo 'email' não começa com 'space/'.
      final subgroups = entities
        .where((e) => e['type'] == 'GROUP' && !(e['email']?.startsWith('space/')))
        .toList();

      // 3. Para cada subgrupo, verificar se o usuário logado é membro
      // e, se for, adicioná-lo a lista a ser 'finalGroups' que é exibida
      // na aba de grupos da interface.
      final List<GoogleGroupModel> finalGroups = [];
      for (final subgroup in subgroups) {
        debugPrint('\n\n\n$subgroup\n\n\n');
        final groupEmail = subgroup['email'] as String;
        final groupName = subgroup['name'] as String; 
        final groupDescription = subgroup['description'] as String;
        final groupMembers = await _googleService.getGroupEntities(token, groupEmail);
        final isMember = groupMembers.any((m) => m['email'] == userEmail && m['type'] == 'USER');
        if (isMember) {
          finalGroups.add(GoogleGroupModel(
            name: groupName,
            email: groupEmail,
            description: groupDescription,
            members: [], // TODO
            subgroups: [], // TODO
          ));
        }
      }

      _observableGoogleGroups.assignAll(finalGroups);
      //debugPrint("Usuário é membro de ${finalGroups.length} subgrupo(s).");
    } catch (e) {
      // TODO: debugPrint só faz sentido em ambiente de desenvolvimento
      debugPrint("Erro ao carregar grupos: $e");
      _observableGoogleGroups.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Mapeia o role da API para [GoogleGroupRole].
  GoogleGroupRole _parseRole(String role) {
    switch (role.toUpperCase()) {
      case 'OWNER':
        return GoogleGroupRole.owner;
      case 'MANAGER':
        return GoogleGroupRole.manager;
      default:
        return GoogleGroupRole.member;
    }
  }

  /// Atualiza os membros observados com base no grupo selecionado.
  /// Busca os participantes do grupo via API e filtra apenas usuários (type == USER).
  Future<void> updateObservedUsers(GoogleGroupModel selectedGroup) async {
    observedGroup.value = selectedGroup.name;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final token = await user.getIdToken(true);
      if (token == null) return;

      // Busca usuários do grupo selecionado
      final entities = await _googleService.getGroupEntities(token, selectedGroup.email);

      final users = entities
        .where((e) => e['type'] == 'USER')
        .toList();

      // Filtrar apenas usuários e mapear para GoogleGroupMember
      observedMembers.value = users
          .where((m) => m['type'] == 'USER')
          .map((m) => GoogleGroupMember(
              name: m['name'] as String,
              email: m['email'] as String,
              role: _parseRole(m['role'] as String),
            )
          )
          .toList();
    } catch (e) {
      debugPrint("Erro ao buscar membros do grupo ${selectedGroup.email}: $e");
      observedMembers.clear();
    }
  }
}
