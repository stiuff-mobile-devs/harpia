import 'package:flutter_test/flutter_test.dart';
import 'package:harpia/app/modules/monitora_uff/models/google_group_model.dart';
import 'package:harpia/app/modules/monitora_uff/models/google_group_member_model.dart';

void main() {
  group('GoogleGroupModel & Member - Testes Unitários', () {
    test('Deve instanciar GoogleGroupModel com propriedades corretas', () {
      final grupo = GoogleGroupModel(
        name: 'Vigilância Campus Gragoatá',
        email: 'vigilancia-gragoata@id.uff.br',
        description: 'Equipe responsável pela vigilância patrimonial do Campus Gragoatá',
        members: [
          GoogleGroupMember(
            name: 'Carlos Oliveira',
            email: 'carlos@id.uff.br',
            role: GoogleGroupRole.member,
          ),
          GoogleGroupMember(
            name: 'Ana Souza',
            email: 'ana@id.uff.br',
            role: GoogleGroupRole.manager,
          ),
        ],
        subgroups: [],
      );

      expect(grupo.name, 'Vigilância Campus Gragoatá');
      expect(grupo.email, 'vigilancia-gragoata@id.uff.br');
      expect(grupo.description, contains('Gragoatá'));
      expect(grupo.members.length, 2);
      expect(grupo.members[0].role, GoogleGroupRole.member);
      expect(grupo.members[1].role, GoogleGroupRole.manager);
    });

    test('Deve diferenciar corretamente os papéis de GoogleGroupRole', () {
      expect(GoogleGroupRole.owner, isNot(equals(GoogleGroupRole.member)));
      expect(GoogleGroupRole.manager, isNot(equals(GoogleGroupRole.member)));
      expect(GoogleGroupRole.values, containsAll([
        GoogleGroupRole.owner,
        GoogleGroupRole.manager,
        GoogleGroupRole.member,
      ]));
    });

    test('fromJson deve construir o modelo adequadamente', () {
      final json = {
        'name': 'Transporte UFF',
        'email': 'transporte@id.uff.br',
        'description': 'Coordenação de frotas',
        'members': <GoogleGroupMember>[],
        'subgroups': <GoogleGroupModel>[],
      };

      final model = GoogleGroupModel.fromJson(json);

      expect(model.name, 'Transporte UFF');
      expect(model.email, 'transporte@id.uff.br');
      expect(model.description, 'Coordenação de frotas');
      expect(model.members, isEmpty);
      expect(model.subgroups, isEmpty);
    });
  });
}
