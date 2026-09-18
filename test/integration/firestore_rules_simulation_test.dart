import 'package:flutter_test/flutter_test.dart';

/// Simulador fiel da engine de regras do Firestore correspondente ao arquivo `firestore.rules`.
class FirestoreRulesSimulator {
  /// Avalia a regra de leitura em `/usuarios/{usuarioEmail}`
  static bool evaluateReadUserDoc({
    required Map<String, dynamic>? authToken,
    required String targetDocEmail,
    required Map<String, dynamic> resourceData,
  }) {
    if (authToken == null || authToken['email'] == null) return false;
    final requesterEmail = authToken['email'].toString();

    // 1. isDocOwner
    if (requesterEmail == targetDocEmail) return true;

    // 2. hasRoleInGroup(resource.data.grupo_ativo)
    final grupoAtivo = resourceData['grupo_ativo'] as String?;
    if (grupoAtivo == null) return false;

    final harpiaRoles = authToken['harpia_roles'];
    if (harpiaRoles is! Map) return false;

    return harpiaRoles[grupoAtivo] != null;
  }

  /// Avalia a regra de criação/atualização em `/usuarios/{usuarioEmail}`
  static bool evaluateWriteUserDoc({
    required Map<String, dynamic>? authToken,
    required String targetDocEmail,
    required Map<String, dynamic> incomingData,
  }) {
    if (authToken == null || authToken['email'] == null) return false;
    final requesterEmail = authToken['email'].toString();

    // 1. isDocOwner
    if (requesterEmail != targetDocEmail) return false;

    // 2. isObservavel (system-wide)
    final harpiaRoles = authToken['harpia_roles'];
    if (harpiaRoles is! Map) return false;
    final hasObservableRole = harpiaRoles.values.any(
      (role) => role == 'MEMBER' || role == 'MANAGER',
    );
    if (!hasObservableRole) return false;

    // 3. keys().hasOnly(...)
    const allowedKeys = [
      'email',
      'nome',
      'lat',
      'lng',
      'timestamp',
      'isTracked',
      'grupo_ativo'
    ];
    for (final key in incomingData.keys) {
      if (!allowedKeys.contains(key)) return false;
    }

    // 4. isObservavelInGroup(request.resource.data.grupo_ativo)
    final grupoAtivo = incomingData['grupo_ativo'];
    if (grupoAtivo != null) {
      final roleInTargetGroup = harpiaRoles[grupoAtivo];
      if (roleInTargetGroup != 'MEMBER' && roleInTargetGroup != 'MANAGER') {
        return false; // Usuário tentando forjar grupo onde não é MEMBER ou MANAGER!
      }
    }

    return true;
  }

  /// Avalia a regra de leitura em `/usuarios/{usuarioEmail}/historico_posicoes/{pontoId}`
  static bool evaluateReadHistory({
    required Map<String, dynamic>? authToken,
    required String targetUserEmail,
    required Map<String, dynamic> parentUserData,
  }) {
    if (authToken == null || authToken['email'] == null) return false;
    final requesterEmail = authToken['email'].toString();

    if (requesterEmail == targetUserEmail) return true;

    final grupoAtivo = parentUserData['grupo_ativo'] as String?;
    if (grupoAtivo == null) return false;

    final harpiaRoles = authToken['harpia_roles'];
    if (harpiaRoles is! Map) return false;

    return harpiaRoles[grupoAtivo] != null;
  }
}

void main() {
  group('Simulação e Validação das Regras de Segurança (firestore.rules)', () {
    const emailGuardaA = 'guarda.a@id.uff.br';
    const emailGuardaB = 'guarda.b@id.uff.br';
    const emailObservador = 'chefe.seguranca@id.uff.br';
    const emailInvasor = 'estudante.externo@id.uff.br';

    const grupoSeguranca = 'seguranca-gragoata@id.uff.br';
    const grupoTransporte = 'transporte-vans@id.uff.br';

    late Map<String, dynamic> tokenGuardaA;
    late Map<String, dynamic> tokenObservadorSeguranca;
    late Map<String, dynamic> tokenInvasorSemGrupo;

    setUp(() {
      tokenGuardaA = {
        'email': emailGuardaA,
        'harpia_roles': {
          grupoSeguranca: 'MEMBER',
        },
      };

      tokenObservadorSeguranca = {
        'email': emailObservador,
        'harpia_roles': {
          grupoSeguranca: 'MANAGER',
        },
      };

      tokenInvasorSemGrupo = {
        'email': emailInvasor,
        'harpia_roles': {
          'grupo-outro@id.uff.br': 'MEMBER',
        },
      };
    });

    test('LEITURA: O próprio usuário pode ler seu próprio documento sempre', () {
      final docGuardaA = {
        'email': emailGuardaA,
        'lat': -22.90,
        'lng': -43.13,
        'grupo_ativo': grupoSeguranca,
      };

      final permitido = FirestoreRulesSimulator.evaluateReadUserDoc(
        authToken: tokenGuardaA,
        targetDocEmail: emailGuardaA,
        resourceData: docGuardaA,
      );

      expect(permitido, isTrue);
    });

    test('LEITURA: Observador com role no mesmo grupo_ativo pode ler o documento', () {
      final docGuardaA = {
        'email': emailGuardaA,
        'lat': -22.90,
        'lng': -43.13,
        'grupo_ativo': grupoSeguranca,
      };

      final permitido = FirestoreRulesSimulator.evaluateReadUserDoc(
        authToken: tokenObservadorSeguranca,
        targetDocEmail: emailGuardaA,
        resourceData: docGuardaA,
      );

      expect(permitido, isTrue);
    });

    test('LEITURA: Usuário de OUTRO grupo é TERMINANTEMENTE BLOQUEADO (Sem vazamento)', () {
      final docGuardaA = {
        'email': emailGuardaA,
        'lat': -22.90,
        'lng': -43.13,
        'grupo_ativo': grupoSeguranca, // Guarda A está em Segurança
      };

      final permitido = FirestoreRulesSimulator.evaluateReadUserDoc(
        authToken: tokenInvasorSemGrupo, // Invasor está em grupo-outro
        targetDocEmail: emailGuardaA,
        resourceData: docGuardaA,
      );

      expect(permitido, isFalse, reason: 'Usuário de outro grupo NÃO pode ler coordenadas!');
    });

    test('LEITURA: Terceiro não pode ler documento sem grupo_ativo definido', () {
      final docSemGrupo = {
        'email': emailGuardaA,
        'lat': -22.90,
        'lng': -43.13,
        'grupo_ativo': null,
      };

      final permitido = FirestoreRulesSimulator.evaluateReadUserDoc(
        authToken: tokenObservadorSeguranca,
        targetDocEmail: emailGuardaA,
        resourceData: docSemGrupo,
      );

      expect(permitido, isFalse);
    });

    test('ESCRITA: Usuário pode atualizar suas próprias coordenadas no seu grupo legítimo', () {
      final updateValido = {
        'email': emailGuardaA,
        'lat': -22.9045,
        'lng': -43.1330,
        'timestamp': DateTime.now(),
        'isTracked': true,
        'grupo_ativo': grupoSeguranca,
      };

      final permitido = FirestoreRulesSimulator.evaluateWriteUserDoc(
        authToken: tokenGuardaA,
        targetDocEmail: emailGuardaA,
        incomingData: updateValido,
      );

      expect(permitido, isTrue);
    });

    test('ESCRITA: Usuário é BLOQUEADO se tentar forjar grupo_ativo onde não é MEMBER ou MANAGER', () {
      final updateFraudulento = {
        'email': emailGuardaA,
        'lat': -22.9045,
        'lng': -43.1330,
        'timestamp': DateTime.now(),
        'isTracked': true,
        'grupo_ativo': grupoTransporte, // Guarda A NÃO pertence a Transporte!
      };

      final permitido = FirestoreRulesSimulator.evaluateWriteUserDoc(
        authToken: tokenGuardaA,
        targetDocEmail: emailGuardaA,
        incomingData: updateFraudulento,
      );

      expect(permitido, isFalse, reason: 'Firestore deve rejeitar grupos forjados!');
    });

    test('ESCRITA: Usuário é BLOQUEADO ao tentar atualizar documento de outra pessoa', () {
      final updateAlheio = {
        'email': emailGuardaB,
        'lat': -22.90,
        'lng': -43.13,
      };

      final permitido = FirestoreRulesSimulator.evaluateWriteUserDoc(
        authToken: tokenGuardaA, // Guarda A tentando escrever em Guarda B
        targetDocEmail: emailGuardaB,
        incomingData: updateAlheio,
      );

      expect(permitido, isFalse);
    });

    test('ESCRITA: Rejeição de campos não permitidos (hasOnly)', () {
      final updateComCampoInvalido = {
        'email': emailGuardaA,
        'lat': -22.90,
        'lng': -43.13,
        'isAdmin': true, // Campo invasor não mapeado
      };

      final permitido = FirestoreRulesSimulator.evaluateWriteUserDoc(
        authToken: tokenGuardaA,
        targetDocEmail: emailGuardaA,
        incomingData: updateComCampoInvalido,
      );

      expect(permitido, isFalse);
    });

    test('HISTÓRICO: Membro do grupo ativo pode ler histórico de posições', () {
      final parentDoc = {
        'email': emailGuardaA,
        'grupo_ativo': grupoSeguranca,
      };

      final permitido = FirestoreRulesSimulator.evaluateReadHistory(
        authToken: tokenObservadorSeguranca,
        targetUserEmail: emailGuardaA,
        parentUserData: parentDoc,
      );

      expect(permitido, isTrue);
    });

    test('HISTÓRICO: Usuário de outro grupo NÃO pode ler histórico de posições', () {
      final parentDoc = {
        'email': emailGuardaA,
        'grupo_ativo': grupoSeguranca,
      };

      final permitido = FirestoreRulesSimulator.evaluateReadHistory(
        authToken: tokenInvasorSemGrupo,
        targetUserEmail: emailGuardaA,
        parentUserData: parentDoc,
      );

      expect(permitido, isFalse);
    });
  });
}
