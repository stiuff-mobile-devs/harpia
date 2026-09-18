import 'package:flutter_test/flutter_test.dart';
import 'package:harpia/app/modules/monitora_uff/models/user_model.dart';

void main() {
  group('UserModel Tests', () {
    test('Deve serializar e desserializar grupo_ativo corretamente', () {
      final now = DateTime.now();
      final user = UserModel(
        email: 'guarda1@id.uff.br',
        nome: 'Guarda Teste',
        lat: -22.9041,
        lng: -43.1329,
        timestamp: now,
        isTracked: true,
        grupoAtivo: 'seguranca-gragoata@id.uff.br',
      );

      final map = user.toMap();
      expect(map['email'], 'guarda1@id.uff.br');
      expect(map['nome'], 'Guarda Teste');
      expect(map['lat'], -22.9041);
      expect(map['lng'], -43.1329);
      expect(map['isTracked'], true);
      expect(map['grupo_ativo'], 'seguranca-gragoata@id.uff.br');

      final deserialized = UserModel.fromMap({
        'email': 'guarda1@id.uff.br',
        'nome': 'Guarda Teste',
        'lat': -22.9041,
        'lng': -43.1329,
        'isTracked': true,
        'grupo_ativo': 'seguranca-gragoata@id.uff.br',
      });

      expect(deserialized.email, 'guarda1@id.uff.br');
      expect(deserialized.nome, 'Guarda Teste');
      expect(deserialized.lat, -22.9041);
      expect(deserialized.lng, -43.1329);
      expect(deserialized.isTracked, true);
      expect(deserialized.grupoAtivo, 'seguranca-gragoata@id.uff.br');
    });

    test('Deve lidar com grupo_ativo nulo ou ausente sem quebrar', () {
      final userWithoutGroup = UserModel.fromMap({
        'email': 'observador@id.uff.br',
        'nome': 'Observador Teste',
      });

      expect(userWithoutGroup.email, 'observador@id.uff.br');
      expect(userWithoutGroup.grupoAtivo, isNull);

      final map = userWithoutGroup.toMap();
      expect(map.containsKey('grupo_ativo'), isFalse);
    });
  });
}
