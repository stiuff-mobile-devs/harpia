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

  /// Indica se o usuário logado é membro (type == USER) do grupo raiz GH.
  final RxBool _isRootMember = RxBool(false);
  bool get isRootMember => _isRootMember.value;

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

      // 2. Verificar se o usuário logado é membro (type == USER) do grupo raiz GH
      _isRootMember.value = members.any((m) =>
          m['email'] == userEmail && m['type'] == 'USER');
      debugPrint("Usuário ${_isRootMember.value ? 'É' : 'NÃO É'} membro do grupo raiz $rootGroupEmail.");

      // 3. Filtrar subgrupos (type == GROUP) de GH
      final allSubgroupMembers = members
        .where((m) => m['type'] == 'GROUP' && !(m['email']?.startsWith('space/')))
        .toList();

      // 4. Criar GoogleGroupModel para cada subgrupo
      //    (members e subgroups vazios, serão carregados sob demanda)
      final List<GoogleGroupModel> allGroups = allSubgroupMembers.map((m) {
        final email = m['email'] as String;
        final name = _extractNameFromEmail(email);
        return GoogleGroupModel(
          name: name,
          email: email,
          description: '',
          members: [],
          subgroups: [],
        );
      }).toList();

      // 5. Se for administrador (membro de GH), ver todos os subgrupos.
      //    Se não for, filtrar apenas os subgrupos onde o usuário é membro.
      List<GoogleGroupModel> finalGroups;
      if (_isRootMember.value) {
        finalGroups = allGroups;
      } else {
        finalGroups = [];
        for (final group in allGroups) {
          final groupMembers = await _googleService.getGroupMembers(token, group.email);
          final isMember = groupMembers.any((m) =>
              m['email'] == userEmail && m['type'] == 'USER');
          if (isMember) {
            finalGroups.add(group);
          }
        }
        debugPrint("Usuário é membro de ${finalGroups.length} subgrupo(s).");
      }

      _googleGroups.assignAll(finalGroups);
      debugPrint("Grupos carregados: ${finalGroups.length}");
    } catch (e) {
      debugPrint("Erro ao carregar grupos: $e");
      _googleGroups.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Verifica se um determinado email de usuário é membro (type == USER)
  /// de algum subgrupo (GH') do grupo raiz.
  /// Aguarda o carregamento inicial dos grupos, se necessário.
  Future<bool> isUserInAnySubgroup(String userEmail) async {
    // Aguardar _loadGroups() terminar
    if (isLoading.value) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return isLoading.value;
      });
    }

    final user = _auth.currentUser;
    if (user == null) return false;

    final token = await user.getIdToken(true);
    if (token == null) return false;

    for (final group in _googleGroups) {
      final members = await _googleService.getGroupMembers(token, group.email);
      final isMember = members.any((m) =>
          m['email'] == userEmail && m['type'] == 'USER');
      if (isMember) return true;
    }

    return false;
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