import 'package:flutter_test/flutter_test.dart';
import 'package:harpia/app/modules/monitora_uff/models/google_group_model.dart';

/// Função pura auxiliar que encapsula a lógica de filtragem implementada
/// em `GoogleGroupsController.getObservableGroupsForUser` para garantir testabilidade
/// determinística e isolada de chamadas estáticas do Firebase Auth.
List<GoogleGroupModel> filterObservableGroups({
  required Map<String, dynamic>? claims,
  required List<GoogleGroupModel> availableGroups,
}) {
  if (claims == null || claims.isEmpty) return [];

  final allowedEmails = claims.entries
      .where((e) => e.value == 'MEMBER' || e.value == 'MANAGER')
      .map((e) => e.key.toString().toLowerCase().trim())
      .toSet();

  return availableGroups
      .where((g) => allowedEmails.contains(g.email.toLowerCase().trim()))
      .toList();
}

/// Função pura auxiliar que encapsula a lógica de resolução de grupo ativo
/// implementada em `TrackingController._startService`.
String? resolveActiveGroupEmail({
  required List<GoogleGroupModel> observableGroups,
  GoogleGroupModel? currentSelectedGroup,
}) {
  if (observableGroups.isEmpty) {
    return null; // Não autorizado a rastrear
  }

  if (observableGroups.length == 1) {
    return observableGroups.first.email; // Auto-seleciona único grupo observável
  }

  // Se houver mais de um grupo observável, verifica se o grupo atualmente selecionado é um deles
  if (currentSelectedGroup != null &&
      observableGroups.any((g) => g.email.trim().toLowerCase() == currentSelectedGroup.email.trim().toLowerCase())) {
    return currentSelectedGroup.email;
  }

  // Requer escolha do usuário (bottomsheet)
  return 'PROMPT_SELECTION';
}

void main() {
  group('Lógica de Autorização e Filtro de Grupos Operacionais (Opção 3)', () {
    late List<GoogleGroupModel> gruposMock;

    setUp(() {
      gruposMock = [
        GoogleGroupModel(
          name: 'Segurança Praia Vermelha',
          email: 'seguranca-pv@id.uff.br',
          description: '',
          members: [],
          subgroups: [],
        ),
        GoogleGroupModel(
          name: 'Transporte Gragoatá',
          email: 'transporte-gragoata@id.uff.br',
          description: '',
          members: [],
          subgroups: [],
        ),
        GoogleGroupModel(
          name: 'Coordenação Geral Harpia',
          email: 'coordenacao-harpia@id.uff.br',
          description: '',
          members: [],
          subgroups: [],
        ),
      ];
    });

    test('Deve retornar lista vazia se claims for nulo ou vazio', () {
      expect(filterObservableGroups(claims: null, availableGroups: gruposMock), isEmpty);
      expect(filterObservableGroups(claims: {}, availableGroups: gruposMock), isEmpty);
    });

    test('NÃO deve considerar grupos onde o usuário é apenas OWNER ou METAUSER', () {
      final claimsApenasProprietario = {
        'coordenacao-harpia@id.uff.br': 'OWNER',
        'transporte-gragoata@id.uff.br': 'METAUSER',
      };

      final observaveis = filterObservableGroups(
        claims: claimsApenasProprietario,
        availableGroups: gruposMock,
      );

      // Proprietários e metausuários não são observáveis/rastreáveis
      expect(observaveis, isEmpty);
    });

    test('Deve retornar grupos onde o usuário possui papel MEMBER ou MANAGER', () {
      final claimsMembroEManager = {
        'seguranca-pv@id.uff.br': 'MEMBER',
        'transporte-gragoata@id.uff.br': 'MANAGER',
        'coordenacao-harpia@id.uff.br': 'OWNER',
      };

      final observaveis = filterObservableGroups(
        claims: claimsMembroEManager,
        availableGroups: gruposMock,
      );

      expect(observaveis.length, 2);
      expect(observaveis.map((g) => g.email), containsAll([
        'seguranca-pv@id.uff.br',
        'transporte-gragoata@id.uff.br',
      ]));
      expect(observaveis.map((g) => g.email), isNot(contains('coordenacao-harpia@id.uff.br')));
    });

    test('Deve ser resiliente a diferenças de maiúsculas/minúsculas e espaços nos emails', () {
      final claimsComVariacoes = {
        '  SEGURANCA-PV@ID.UFF.BR ': 'MEMBER',
      };

      final observaveis = filterObservableGroups(
        claims: claimsComVariacoes,
        availableGroups: gruposMock,
      );

      expect(observaveis.length, 1);
      expect(observaveis.first.email, 'seguranca-pv@id.uff.br');
    });

    test('Resolução de grupo ativo: 0 grupos observáveis deve retornar null (não autorizado)', () {
      final active = resolveActiveGroupEmail(
        observableGroups: [],
        currentSelectedGroup: gruposMock.first,
      );

      expect(active, isNull);
    });

    test('Resolução de grupo ativo: 1 grupo observável deve auto-selecionar imediatamente', () {
      final active = resolveActiveGroupEmail(
        observableGroups: [gruposMock[0]],
        currentSelectedGroup: null,
      );

      expect(active, 'seguranca-pv@id.uff.br');
    });

    test('Resolução de grupo ativo: múltiplos grupos com grupo atual válido deve usar o atual', () {
      final active = resolveActiveGroupEmail(
        observableGroups: [gruposMock[0], gruposMock[1]],
        currentSelectedGroup: gruposMock[1], // Usuário está com Transporte aberto na tela
      );

      expect(active, 'transporte-gragoata@id.uff.br');
    });

    test('Resolução de grupo ativo: múltiplos grupos com grupo atual NÃO observável deve exigir seleção', () {
      final active = resolveActiveGroupEmail(
        observableGroups: [gruposMock[0], gruposMock[1]],
        currentSelectedGroup: gruposMock[2], // Coordenação é OWNER, não é observável
      );

      expect(active, 'PROMPT_SELECTION');
    });

    test('Resolução de grupo ativo: múltiplos grupos sem grupo atual selecionado deve exigir seleção', () {
      final active = resolveActiveGroupEmail(
        observableGroups: [gruposMock[0], gruposMock[1]],
        currentSelectedGroup: null,
      );

      expect(active, 'PROMPT_SELECTION');
    });
  });
}
