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
      kReleaseMode ? 'grupos.harpia@id.uff.br' : 'harpiateste@id.uff.br';

  /// Lista de grupos que o usuário logado pode observar.
  /// Representa os subgrupos (type == GROUP) de [rootGroupEmail].
  final RxList<GoogleGroupModel> _googleGroups = RxList<GoogleGroupModel>();
  List<GoogleGroupModel> get googleGroups => _googleGroups;

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

      // 2. Filtrar subgrupos (type == GROUP) de GH
      final subgroups = entities
        .where((m) => m['type'] == 'GROUP' && !(m['email']?.startsWith('space/')))
        .toList();

      // 3. Para cada subgrupo, verificar se o usuário logado é membro
      final List<GoogleGroupModel> finalGroups = [];
      for (final entity in subgroups) {
        final groupEmail = entity['email'] as String;
        final groupName = _extractNameFromEmail(groupEmail);
        final groupMembers = await _googleService.getGroupEntities(token, groupEmail);
        final isMember = groupMembers.any((m) =>
            m['email'] == userEmail && m['type'] == 'USER');
        if (isMember) {
          finalGroups.add(GoogleGroupModel(
            name: groupName,
            email: groupEmail,
            description: '',
            members: [],
            subgroups: [],
          ));
        }
      }

      _googleGroups.assignAll(finalGroups);
      debugPrint("Usuário é membro de ${finalGroups.length} subgrupo(s).");
    } catch (e) {
      debugPrint("Erro ao carregar grupos: $e");
      _googleGroups.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Extrai um nome legível a partir do email do grupo.
  /// Ex: "bombeiros.harpia@id.uff.br" -> "Bombeiros Harpia"
  String _extractNameFromEmail(String email) {
    final localPart = email.split('@').first;
    // Substituir separadores comuns por espaço e capitalizar
    final words = localPart
        .replaceAll('.', ' ')
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .toList();
    return words.join(' ');
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

      // Buscar membros do grupo selecionado
      final members = await _googleService.getGroupEntities(token, selectedGroup.email);

      // Filtrar apenas usuários e mapear para GoogleGroupMember
      // O name fica vazio (string vazia) pois será preenchido a partir
      // dos dados do Firebase quando for exibido na UI.
      final userMembers = members
          .where((m) => m['type'] == 'USER')
          .map((m) => GoogleGroupMember(
              name: '', // TODO: substituir por m['name'] quando a API ficar pronta.
              email: m['email'] as String,
              role: _parseRole(m['role'] as String),
            )
          )
          .toList();

      observedMembers.value = userMembers;
    } catch (e) {
      debugPrint("Erro ao buscar membros do grupo ${selectedGroup.email}: $e");
      observedMembers.clear();
    }
  }
}