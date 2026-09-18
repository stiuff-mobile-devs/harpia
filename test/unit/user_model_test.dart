import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:harpia/app/modules/monitora_uff/models/user_model.dart';

void main() {
  group('UserModel - Testes Unitários de Serialização e Integridade', () {
    test('Deve inicializar corretamente com todos os campos preenchidos', () {
      final dataHora = DateTime(2026, 9, 16, 20, 30, 0);
      final user = UserModel(
        email: 'servidor.ti@id.uff.br',
        nome: 'Servidor Teste',
        lat: -22.9041,
        lng: -43.1329,
        timestamp: dataHora,
        isTracked: true,
        grupoAtivo: 'ti-suporte@id.uff.br',
      );

      expect(user.email, 'servidor.ti@id.uff.br');
      expect(user.nome, 'Servidor Teste');
      expect(user.lat, -22.9041);
      expect(user.lng, -43.1329);
      expect(user.timestamp, dataHora);
      expect(user.isTracked, isTrue);
      expect(user.grupoAtivo, 'ti-suporte@id.uff.br');
    });

    test('toMap() deve incluir o campo grupo_ativo quando informado', () {
      final user = UserModel(
        email: 'seguranca@id.uff.br',
        nome: 'Vigilante Silva',
        lat: -22.9000,
        lng: -43.1300,
        isTracked: true,
        grupoAtivo: 'vigilancia-praia-vermelha@id.uff.br',
      );

      final map = user.toMap();

      expect(map.containsKey('grupo_ativo'), isTrue);
      expect(map['grupo_ativo'], 'vigilancia-praia-vermelha@id.uff.br');
      expect(map['email'], 'seguranca@id.uff.br');
      expect(map['nome'], 'Vigilante Silva');
      expect(map['isTracked'], isTrue);
    });

    test('toMap() NÃO deve incluir o campo grupo_ativo quando for nulo', () {
      final user = UserModel(
        email: 'gestor@id.uff.br',
        nome: 'Gestor Teste',
        isTracked: false,
      );

      final map = user.toMap();

      expect(map.containsKey('grupo_ativo'), isFalse);
      expect(map['grupo_ativo'], isNull);
    });

    test('fromMap() deve extrair grupo_ativo de dados do Firestore', () {
      final mapFirestore = {
        'email': 'motorista@id.uff.br',
        'nome': 'Motorista Santos',
        'lat': -22.8900,
        'lng': -43.1200,
        'timestamp': Timestamp.fromDate(DateTime(2026, 9, 16, 15, 0)),
        'isTracked': true,
        'grupo_ativo': 'transporte-vans@id.uff.br',
      };

      final user = UserModel.fromMap(mapFirestore);

      expect(user.email, 'motorista@id.uff.br');
      expect(user.nome, 'Motorista Santos');
      expect(user.lat, -22.8900);
      expect(user.lng, -43.1200);
      expect(user.isTracked, isTrue);
      expect(user.grupoAtivo, 'transporte-vans@id.uff.br');
      expect(user.timestamp, isNotNull);
    });

    test('fromMap() deve tratar ausência ou valor nulo de grupo_ativo graciosamente', () {
      final mapSemGrupo = {
        'email': 'usuario.sem.grupo@id.uff.br',
        'nome': 'Usuário Sem Grupo',
        'lat': -22.9050,
        'lng': -43.1310,
        'isTracked': false,
      };

      final user = UserModel.fromMap(mapSemGrupo);

      expect(user.email, 'usuario.sem.grupo@id.uff.br');
      expect(user.grupoAtivo, isNull);
    });

    test('fromMap() deve converter valor numérico ou não-string para String no grupo_ativo', () {
      final mapComTipoInesperado = {
        'email': 'teste@id.uff.br',
        'grupo_ativo': 12345, // Caso o banco contenha dado não estritamente string
      };

      final user = UserModel.fromMap(mapComTipoInesperado);

      expect(user.grupoAtivo, '12345');
    });

    test('Ciclo completo: UserModel -> toMap() -> fromMap() deve ser idempotente', () {
      final original = UserModel(
        email: 'ronda.noturna@id.uff.br',
        nome: 'Ronda Noturna',
        lat: -22.9100,
        lng: -43.1400,
        isTracked: true,
        grupoAtivo: 'seguranca-valonguinho@id.uff.br',
      );

      final map = original.toMap();
      final reconstruido = UserModel.fromMap(map);

      expect(reconstruido.email, original.email);
      expect(reconstruido.nome, original.nome);
      expect(reconstruido.lat, original.lat);
      expect(reconstruido.lng, original.lng);
      expect(reconstruido.isTracked, original.isTracked);
      expect(reconstruido.grupoAtivo, original.grupoAtivo);
    });
  });
}
