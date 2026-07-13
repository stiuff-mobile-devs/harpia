import 'package:get/get.dart';
import 'package:harpia/app/modules/monitora_uff/models/google_group_model.dart';
import 'package:harpia/app/modules/monitora_uff/models/google_group_member_model.dart';

class GoogleGroupsController extends GetxController {
  RxList<GoogleGroupMember> observedMembers = RxList();
  // TODO: está hardcoded, mudar isso.
  // googleGroups representa todos o conjunto de todos os grupos que
  // o usuário logado participa.
  //
  // Essa lista será exibida na UI para que o usuário logado escolha
  // o grupo que ele deseja observar
  // obs.: 'observar um grupo G' == 'observar os participantes de G'
  List<GoogleGroupModel> get googleGroups => [
    GoogleGroupModel(
      name: 'a', 
      email: 'a@id.uff.br', 
      description: 'desc a', 
      members: [
        GoogleGroupMember(name: 'member_a1', email: 'member_a1@id.uff.br', role: GoogleGroupRole.owner),
        GoogleGroupMember(name: 'member_a2', email: 'member_a2@id.uff.br', role: GoogleGroupRole.manager),
        GoogleGroupMember(name: 'member_a3', email: 'member_a3@id.uff.br', role: GoogleGroupRole.member)
      ],
      subgroups: [
        GoogleGroupModel(
          name: 'subgroup_a1', 
          email: 'subgroup_a1@id.uff.br', 
          description: 'bla bla bla', 
          members: [], 
          subgroups: []
        ),
      ]
    ),
    GoogleGroupModel(
      name: 'Harpia-Índice', 
      email: 'indice.harpia@id.uff.br', 
      description: 'Grupo unificador dos grupos do Sistema Harpia', 
      members: [
        GoogleGroupMember(name: 'Cosme Faria Côrrea', email: 'cosmefc@id.uff.br', role: GoogleGroupRole.owner),
        GoogleGroupMember(name: 'João Vitor Luciano Gonçalves', email: 'jvlgoncalves@id.uff.br', role: GoogleGroupRole.manager),
        GoogleGroupMember(name: 'Rafael Cesário da Silva', email: 'rafaelcesario@id.uff.br', role: GoogleGroupRole.owner),
        
      ], 
      subgroups: [
        GoogleGroupModel(
          name: 'Brigada de Incêndio', 
          email: 'bombeiros.harpia@id.uff.br',
          description: 'Brigada de Incêndio',
          members: [
            GoogleGroupMember(name: 'Cosme Faria Côrrea', email: 'cosmefc@id.uff.br', role: GoogleGroupRole.owner),
            GoogleGroupMember(name: 'João Vitor Luciano Gonçalves', email: 'jvlgoncalves@id.uff.br', role: GoogleGroupRole.owner),
            GoogleGroupMember(name: 'Rafael Cesário da Silva', email: 'rafaelcesario@id.uff.br', role: GoogleGroupRole.owner),
          ],
          subgroups: [],
        ),
        GoogleGroupModel(
          name: 'Supervisores dos Vigilantes', 
          email: 'super.vigilantes.harpia@id.uff.br', 
          description: 'Supervisores dos Vigilantes', 
          members: [
            GoogleGroupMember(name: 'Cosme Faria Côrrea', email: 'cosmefc@id.uff.br', role: GoogleGroupRole.owner),
            GoogleGroupMember(name: 'João Vitor Luciano Gonçalves', email: 'jvlgoncalves@id.uff.br', role: GoogleGroupRole.member),
            GoogleGroupMember(name: 'Rafael Cesário da Silva', email: 'rafaelcesario@id.uff.br', role: GoogleGroupRole.member)
          ], 
          subgroups: []
        )
      ]
    )
  ];

  Future<void> updateObservedUsers(GoogleGroupModel selectedGroup) async {
    observedMembers.value = selectedGroup.members;
    //observedMembers.forEach((member) => debugPrint(member.name));
  }
}