import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
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
  static const String rootGroupEmail = 'grupos.harpia@id.uff.br';

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

      // 1. Buscar todos os membros do grupo raiz 'grupos.harpia@id.uff.br'
      final members = await _googleService.getGroupMembers(token, rootGroupEmail);

      // 2. Verificar se o usuário logado é membro (type == USER)
      final isMember = members.any((m) =>
          m['email'] == userEmail && m['type'] == 'USER');

      if (!isMember) {
        debugPrint("Usuário $userEmail não é membro de $rootGroupEmail.");
        _googleGroups.clear();
        isLoading.value = false;
        return;
      }

      // 3. Filtrar apenas subgrupos (type == GROUP)
      final subgroupMembers = members
        .where((m) => m['type'] == 'GROUP' && !(m['email']?.startsWith('space/')))
        .toList();

      // 4. Para cada subgrupo, criar um GoogleGroupModel
      //    (members e subgroups vazios, serão carregados sob demanda)
      final List<GoogleGroupModel> groups = subgroupMembers.map((m) {
        final email = m['email'] as String;
        // Extrair um nome legível do email (ex: "bombeiros.harpia@id.uff.br" -> "Bombeiros Harpia")
        final name = _extractNameFromEmail(email);
        return GoogleGroupModel(
          name: name,
          email: email,
          description: '',
          members: [],
          subgroups: [],
        );
      }).toList();

      _googleGroups.assignAll(groups);
      debugPrint("Grupos carregados: ${groups.length}");
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
      final members = await _googleService.getGroupMembers(token, selectedGroup.email);

      // Filtrar apenas usuários e mapear para GoogleGroupMember
      // O name fica vazio (string vazia) pois será preenchido a partir
      // dos dados do Firebase quando for exibido na UI.
      final userMembers = members
          .where((m) => m['type'] == 'USER')
          .map((m) => GoogleGroupMember(
                name: '',
                email: m['email'] as String,
                role: _parseRole(m['role'] as String),
              ))
          .toList();

      observedMembers.value = userMembers;
    } catch (e) {
      debugPrint("Erro ao buscar membros do grupo ${selectedGroup.email}: $e");
      observedMembers.clear();
    }
  }
}