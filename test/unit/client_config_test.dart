import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harpia/app/core/branding/models/client_config.dart';
import 'package:harpia/app/core/branding/models/client_logo_config.dart';
import 'package:harpia/app/core/branding/models/client_theme_config.dart';

void main() {
  group('ClientLogoConfig - Suíte de Testes Unitários', () {
    // -------------------------------------------------------------
    // Construtores e Presets
    // -------------------------------------------------------------
    test('Happy Path: Construtor asset deve configurar tipo, caminho e dimensões', () {
      // 1. Arrange
      const assetPath = 'assets/logos/client_logo.png';
      const width = 120.0;
      const height = 60.0;

      // 2. Act
      final logo = ClientLogoConfig.asset(
        assetPath,
        width: width,
        height: height,
      );

      // 3. Assert
      expect(logo.type, ClientLogoType.asset);
      expect(logo.path, assetPath);
      expect(logo.width, width);
      expect(logo.height, height);
      expect(logo.fallbackIcon, Icons.location_on);
    });

    test('Happy Path: Construtor network deve configurar tipo network e URL', () {
      // 1. Arrange
      const networkUrl = 'https://example.com/logo.png';

      // 2. Act
      final logo = ClientLogoConfig.network(networkUrl);

      // 3. Assert
      expect(logo.type, ClientLogoType.network);
      expect(logo.path, networkUrl);
      expect(logo.fallbackIcon, Icons.location_on);
    });

    test('Happy Path: Construtor icon deve configurar tipo icon e IconData customizado', () {
      // 1. Arrange
      const customIcon = Icons.eco;

      // 2. Act
      final logo = ClientLogoConfig.icon(icon: customIcon);

      // 3. Assert
      expect(logo.type, ClientLogoType.icon);
      expect(logo.fallbackIcon, customIcon);
      expect(logo.path, isNull);
    });

    test('Happy Path: defaultLogo deve retornar logo canônico do Monitora UFF', () {
      // 1. Arrange
      const expectedPath = 'assets/monitora_uff/monitora_uff.png';
      const expectedHeight = 100.0;

      // 2. Act
      final defaultLogo = ClientLogoConfig.defaultLogo();

      // 3. Assert
      expect(defaultLogo.type, ClientLogoType.asset);
      expect(defaultLogo.path, expectedPath);
      expect(defaultLogo.height, expectedHeight);
    });

    test('Edge Case: Construtor padrão com parâmetros mínimos deve usar fallbackIcon default', () {
      // 1. Arrange
      const type = ClientLogoType.icon;

      // 2. Act
      const logo = ClientLogoConfig(type: type);

      // 3. Assert
      expect(logo.fallbackIcon, Icons.location_on);
      expect(logo.path, isNull);
      expect(logo.width, isNull);
      expect(logo.height, isNull);
    });

    // -------------------------------------------------------------
    // toMap e fromMap
    // -------------------------------------------------------------
    test('Happy Path: toMap deve serializar todas as propriedades com sucesso', () {
      // 1. Arrange
      final logo = ClientLogoConfig.network(
        'https://cdn.example.com/brand.png',
        width: 150.0,
        height: 50.0,
        fallbackIcon: Icons.map,
      );

      // 2. Act
      final map = logo.toMap();

      // 3. Assert
      expect(map['type'], 'network');
      expect(map['path'], 'https://cdn.example.com/brand.png');
      expect(map['width'], 150.0);
      expect(map['height'], 50.0);
      expect(map['fallbackIconCodePoint'], Icons.map.codePoint);
    });

    test('Happy Path: fromMap deve deserializar mapa completo de tipo network', () {
      // 1. Arrange
      final map = {
        'type': 'network',
        'path': 'https://storage.google.com/logo.png',
        'fallbackIconCodePoint': Icons.business.codePoint,
        'fallbackIconFontFamily': Icons.business.fontFamily,
        'width': 200,
        'height': 80,
      };

      // 2. Act
      final logo = ClientLogoConfig.fromMap(map);

      // 3. Assert
      expect(logo.type, ClientLogoType.network);
      expect(logo.path, 'https://storage.google.com/logo.png');
      expect(logo.fallbackIcon.codePoint, Icons.business.codePoint);
      expect(logo.width, 200.0);
      expect(logo.height, 80.0);
    });

    test('Happy Path: fromMap deve deserializar mapa de tipo icon', () {
      // 1. Arrange
      final map = {
        'type': 'icon',
        'fallbackIconCodePoint': Icons.local_shipping.codePoint,
        'fallbackIconFontFamily': Icons.local_shipping.fontFamily,
      };

      // 2. Act
      final logo = ClientLogoConfig.fromMap(map);

      // 3. Assert
      expect(logo.type, ClientLogoType.icon);
      expect(logo.fallbackIcon.codePoint, Icons.local_shipping.codePoint);
      expect(logo.path, isNull);
    });

    test('Edge Case: fromMap com mapa vazio deve usar tipo asset e fallback padrão', () {
      // 1. Arrange
      final emptyMap = <String, dynamic>{};

      // 2. Act
      final logo = ClientLogoConfig.fromMap(emptyMap);

      // 3. Assert
      expect(logo.type, ClientLogoType.asset);
      expect(logo.fallbackIcon, Icons.location_on);
      expect(logo.path, isNull);
      expect(logo.width, isNull);
      expect(logo.height, isNull);
    });

    test('Edge Case: fromMap deve ser insensível a maiúsculas na propriedade type', () {
      // 1. Arrange
      final map = {'type': 'NETWORK', 'path': 'https://api.test/logo.svg'};

      // 2. Act
      final logo = ClientLogoConfig.fromMap(map);

      // 3. Assert
      expect(logo.type, ClientLogoType.network);
    });

    test('Sad Path: fromMap com tipo desconhecido deve recorrer a ClientLogoType.asset', () {
      // 1. Arrange
      final map = {'type': 'tipo_inexistente_123'};

      // 2. Act
      final logo = ClientLogoConfig.fromMap(map);

      // 3. Assert
      expect(logo.type, ClientLogoType.asset);
    });

    // -------------------------------------------------------------
    // copyWith e Igualdade
    // -------------------------------------------------------------
    test('Happy Path: copyWith deve atualizar os campos informados', () {
      // 1. Arrange
      final original = ClientLogoConfig.asset('assets/initial.png', width: 100);

      // 2. Act
      final updated = original.copyWith(path: 'assets/updated.png', width: 180);

      // 3. Assert
      expect(updated.path, 'assets/updated.png');
      expect(updated.width, 180);
      expect(updated.type, original.type);
    });

    test('Edge Case: copyWith sem parâmetros deve retornar objeto equivalente', () {
      // 1. Arrange
      final original = ClientLogoConfig.asset('assets/initial.png', width: 100);

      // 2. Act
      final copy = original.copyWith();

      // 3. Assert
      expect(copy, equals(original));
    });

    test('Happy Path: Instâncias com mesmos atributos devem ser iguais', () {
      // 1. Arrange
      final logo1 = ClientLogoConfig.asset('assets/logo.png', width: 100, height: 50);
      final logo2 = ClientLogoConfig.asset('assets/logo.png', width: 100, height: 50);

      // 2. Act
      final areEqual = (logo1 == logo2);

      // 3. Assert
      expect(areEqual, isTrue);
      expect(logo1.hashCode, equals(logo2.hashCode));
    });

    test('Sad Path: Instâncias com caminhos diferentes devem ser desiguais', () {
      // 1. Arrange
      final logo1 = ClientLogoConfig.asset('assets/logo1.png');
      final logo2 = ClientLogoConfig.asset('assets/logo2.png');

      // 2. Act
      final areEqual = (logo1 == logo2);

      // 3. Assert
      expect(areEqual, isFalse);
    });
  });

  group('ClientConfig - Suíte de Testes Unitários', () {
    // -------------------------------------------------------------
    // Construtores e Presets
    // -------------------------------------------------------------
    test('Happy Path: Preset UFF deve conter identificador e configurações padrão', () {
      // 1. Arrange
      const expectedId = 'uff';
      const expectedAppName = 'Monitora UFF';

      // 2. Act
      final config = ClientConfig.uff();

      // 3. Assert
      expect(config.id, expectedId);
      expect(config.appName, expectedAppName);
      expect(config.logo.type, ClientLogoType.asset);
      expect(config.theme.primaryColor, const Color(0xFF1D324E));
    });

    test('Happy Path: Preset Green deve conter configurações ecológicas', () {
      // 1. Arrange
      const expectedId = 'ecotrack';
      const expectedAppName = 'EcoTracker';

      // 2. Act
      final config = ClientConfig.green();

      // 3. Assert
      expect(config.id, expectedId);
      expect(config.appName, expectedAppName);
      expect(config.logo.type, ClientLogoType.icon);
      expect(config.theme.primaryColor, const Color(0xFF1B5E20));
    });

    test('Edge Case: Construtor deve permitir features nulo', () {
      // 1. Arrange
      final logo = ClientLogoConfig.defaultLogo();
      final theme = ClientThemeConfig.uff();

      // 2. Act
      final config = ClientConfig(
        id: 'tenant_x',
        appName: 'App X',
        logo: logo,
        theme: theme,
      );

      // 3. Assert
      expect(config.features, isNull);
    });

    test('Sad Path: Preset UFF e Green devem ser distintos', () {
      // 1. Arrange
      final uff = ClientConfig.uff();
      final green = ClientConfig.green();

      // 2. Act
      final areEqual = (uff == green);

      // 3. Assert
      expect(areEqual, isFalse);
    });

    // -------------------------------------------------------------
    // toMap, toJson, fromMap, fromJson
    // -------------------------------------------------------------
    test('Happy Path: toMap e toJson devem serializar dados completos', () {
      // 1. Arrange
      final config = ClientConfig(
        id: 'agro_track',
        appName: 'AgroTrack Mobile',
        logo: ClientLogoConfig.network('https://agro.io/logo.png'),
        theme: ClientThemeConfig.green(),
        features: {'offlineMode': true, 'maxVehicles': 50},
      );

      // 2. Act
      final jsonString = config.toJson();
      final decodedMap = jsonDecode(jsonString) as Map<String, dynamic>;

      // 3. Assert
      expect(decodedMap['id'], 'agro_track');
      expect(decodedMap['appName'], 'AgroTrack Mobile');
      expect(decodedMap['logo']['type'], 'network');
      expect(decodedMap['theme']['primaryColor'], '#FF1B5E20');
      expect(decodedMap['features']['offlineMode'], isTrue);
      expect(decodedMap['features']['maxVehicles'], 50);
    });

    test('Happy Path: fromMap deve reconstruir ClientConfig fiel', () {
      // 1. Arrange
      final map = {
        'id': 'frota_brasil',
        'appName': 'Frota Brasil',
        'logo': {
          'type': 'asset',
          'path': 'assets/frota.png',
        },
        'theme': {
          'primaryColor': '#1B5E20',
          'secondaryColor': '#4CAF50',
          'accentColor': '#A5D6A7',
          'backgroundColor': '#0F3813',
          'surfaceColor': '#18451D',
          'textColor': '#FFFFFFFF',
        },
        'features': {'geofence': true},
      };

      // 2. Act
      final config = ClientConfig.fromMap(map);

      // 3. Assert
      expect(config.id, 'frota_brasil');
      expect(config.appName, 'Frota Brasil');
      expect(config.logo.type, ClientLogoType.asset);
      expect(config.theme.primaryColor, const Color(0xFF1B5E20));
      expect(config.features?['geofence'], isTrue);
    });

    test('Edge Case: toMap não deve incluir chave features se for nula', () {
      // 1. Arrange
      final config = ClientConfig.uff();

      // 2. Act
      final map = config.toMap();

      // 3. Assert
      expect(map.containsKey('features'), isFalse);
    });

    test('Edge Case: fromMap com mapa vazio deve atribuir identificador e appName padrões', () {
      // 1. Arrange
      final emptyMap = <String, dynamic>{};

      // 2. Act
      final config = ClientConfig.fromMap(emptyMap);

      // 3. Assert
      expect(config.id, 'default');
      expect(config.appName, 'GeoTracking');
      expect(config.logo.type, ClientLogoType.asset);
      expect(config.theme.primaryColor, const Color(0xFF1D324E));
      expect(config.features, isNull);
    });

    test('Edge Case: fromMap deve converter id e appName numéricos para String via toString()', () {
      // 1. Arrange
      final map = {
        'id': 1001,
        'appName': 2026,
      };

      // 2. Act
      final config = ClientConfig.fromMap(map);

      // 3. Assert
      expect(config.id, '1001');
      expect(config.appName, '2026');
    });

    test('Sad Path: fromMap com logo e theme inválidos deve usar fallbacks sem exceção', () {
      // 1. Arrange
      final corruptedMap = {
        'id': 'corrompido',
        'appName': 'Corrompido App',
        'logo': 'string_invalida_em_vez_de_mapa',
        'theme': 12345,
        'features': 'invalido',
      };

      // 2. Act
      final config = ClientConfig.fromMap(corruptedMap);

      // 3. Assert
      expect(config.logo.type, ClientLogoType.asset);
      expect(config.theme.primaryColor, const Color(0xFF1D324E));
      expect(config.features, isNull);
    });

    test('Happy Path: fromJson deve desserializar string JSON válida', () {
      // 1. Arrange
      final original = ClientConfig.uff();
      final jsonStr = original.toJson();

      // 2. Act
      final restored = ClientConfig.fromJson(jsonStr);

      // 3. Assert
      expect(restored.id, original.id);
      expect(restored.appName, original.appName);
    });

    test('Sad Path: fromJson com string corrompida não-JSON deve lançar FormatException', () {
      // 1. Arrange
      const corruptedJson = '{id: invalido';

      // 2. Act
      action() => ClientConfig.fromJson(corruptedJson);

      // 3. Assert
      expect(action, throwsA(isA<FormatException>()));
    });

    test('Sad Path: fromJson com lista JSON em vez de objeto Map deve lançar FormatException explicativa', () {
      // 1. Arrange
      const jsonList = '["uff", "Monitora UFF"]';

      // 2. Act
      action() => ClientConfig.fromJson(jsonList);

      // 3. Assert
      expect(
        action,
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('O JSON de configuração do cliente deve ser um objeto Map'),
          ),
        ),
      );
    });

    // -------------------------------------------------------------
    // copyWith e Igualdade
    // -------------------------------------------------------------
    test('Happy Path: copyWith deve atualizar apenas id e appName', () {
      // 1. Arrange
      final original = ClientConfig.uff();

      // 2. Act
      final modified = original.copyWith(id: 'uff_custom', appName: 'Novo Monitora');

      // 3. Assert
      expect(modified.id, 'uff_custom');
      expect(modified.appName, 'Novo Monitora');
      expect(modified.theme, original.theme);
      expect(modified.logo, original.logo);
    });

    test('Edge Case: copyWith sem argumentos deve retornar objeto equivalente', () {
      // 1. Arrange
      final original = ClientConfig.uff();

      // 2. Act
      final copy = original.copyWith();

      // 3. Assert
      expect(copy, equals(original));
    });

    test('Happy Path: Instâncias com mesmos dados devem ser iguais e ter mesmo hashCode', () {
      // 1. Arrange
      final config1 = ClientConfig.uff();
      final config2 = ClientConfig.uff();

      // 2. Act
      final areEqual = (config1 == config2);

      // 3. Assert
      expect(areEqual, isTrue);
      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('Sad Path: Instâncias com id diferente não devem ser iguais', () {
      // 1. Arrange
      final config1 = ClientConfig.uff();
      final config2 = config1.copyWith(id: 'outro_id');

      // 2. Act
      final areEqual = (config1 == config2);

      // 3. Assert
      expect(areEqual, isFalse);
    });
  });
}
