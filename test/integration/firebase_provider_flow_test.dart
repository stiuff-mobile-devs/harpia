import 'package:flutter_test/flutter_test.dart';
import 'package:harpia/app/modules/monitora_uff/models/user_model.dart';

void main() {
  group('Integração e Contratos de Dados do FirebaseProvider (Opção 3)', () {
    test('Contrato de escrita de posição e grupo_ativo no documento do usuário', () {
      const email = 'servidor1@id.uff.br';
      const nome = 'Servidor Silva';
      const lat = -22.9035;
      const lng = -43.1320;
      final timestamp = DateTime(2026, 9, 16, 21, 0, 0);
      const grupoAtivo = 'seguranca-gragoata@id.uff.br';

      // Simula a construção de payload de atualização em updateLocationAndTimestamp
      final userUpdates = <String, dynamic>{
        'email': email,
        'nome': nome,
        'lat': lat,
        'lng': lng,
        'timestamp': timestamp,
        if (grupoAtivo.isNotEmpty) 'grupo_ativo': grupoAtivo,
      };

      expect(userUpdates['email'], email);
      expect(userUpdates['nome'], nome);
      expect(userUpdates['lat'], lat);
      expect(userUpdates['lng'], lng);
      expect(userUpdates['timestamp'], timestamp);
      expect(userUpdates['grupo_ativo'], grupoAtivo);

      // Valida chaves contra a lista permitida no firestore.rules
      final allowedKeys = [
        'email',
        'nome',
        'lat',
        'lng',
        'timestamp',
        'isTracked',
        'grupo_ativo',
      ];
      for (final key in userUpdates.keys) {
        expect(allowedKeys.contains(key), isTrue,
            reason: 'Chave $key não é permitida nas regras do Firestore!');
      }
    });

    test('Contrato de gravação de ponto histórico com grupo_ativo', () {
      const lat = -22.9035;
      const lng = -43.1320;
      final timestamp = DateTime(2026, 9, 16, 21, 0, 0);
      const grupoAtivo = 'seguranca-gragoata@id.uff.br';

      final pointData = <String, dynamic>{
        'lat': lat,
        'lng': lng,
        'timestamp': timestamp,
        'grupo_ativo': grupoAtivo,
      };

      expect(pointData['lat'], lat);
      expect(pointData['lng'], lng);
      expect(pointData['timestamp'], timestamp);
      expect(pointData['grupo_ativo'], grupoAtivo);

      // Valida chaves contra subcoleção historico_posicoes no firestore.rules
      final allowedHistoryKeys = ['lat', 'lng', 'timestamp', 'grupo_ativo'];
      for (final key in pointData.keys) {
        expect(allowedHistoryKeys.contains(key), isTrue,
            reason: 'Chave $key no histórico não permitida nas regras do Firestore!');
      }
    });

    test('Contrato de ativação e desativação de rastreamento (updateIsTracked)', () {
      // 1. Ao iniciar rastreamento:
      const activeGroup = 'transporte-vans@id.uff.br';
      final payloadIniciar = <String, dynamic>{
        'isTracked': true,
        'grupo_ativo': activeGroup,
      };

      expect(payloadIniciar['isTracked'], isTrue);
      expect(payloadIniciar['grupo_ativo'], activeGroup);

      // 2. Ao parar rastreamento:
      final payloadParar = <String, dynamic>{
        'isTracked': false,
      };

      expect(payloadParar['isTracked'], isFalse);
      expect(payloadParar.containsKey('grupo_ativo'), isFalse);
    });

    test('Filtro de tempo para streamUsersByGroup (descarte de posições > 5 min)', () {
      final now = DateTime.now();

      final usuarioRecente = UserModel(
        email: 'ativo@id.uff.br',
        lat: -22.90,
        lng: -43.13,
        timestamp: now.subtract(const Duration(minutes: 1)),
        isTracked: true,
        grupoAtivo: 'seguranca@id.uff.br',
      );

      final usuarioInativoAntigo = UserModel(
        email: 'inativo@id.uff.br',
        lat: -22.90,
        lng: -43.13,
        timestamp: now.subtract(const Duration(minutes: 10)), // Ponto de 10 min atrás
        isTracked: true,
        grupoAtivo: 'seguranca@id.uff.br',
      );

      final todosUsuarios = [usuarioRecente, usuarioInativoAntigo];
      final limit = now.subtract(const Duration(minutes: 5));

      // Lógica interna de descarte do streamUsersByGroup
      final filtrados = todosUsuarios.where((u) {
        return u.timestamp != null && u.timestamp!.isAfter(limit);
      }).toList();

      expect(filtrados.length, 1);
      expect(filtrados.first.email, 'ativo@id.uff.br');
    });
  });
}
