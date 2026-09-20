import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:harpia/app/core/branding/models/client_config.dart';
import 'package:harpia/app/core/branding/services/brand_service.dart';
import 'package:harpia/app/utils/color_pallete.dart';

void main() {
  setUp(() {
    Get.reset();
    BrandService.to.resetToDefault();
  });

  tearDown(() {
    BrandService.to.resetToDefault();
    Get.reset();
  });

  group('BrandService - Inicialização e Instância', () {
    // -------------------------------------------------------------
    // Instanciação e Getters Estáticos
    // -------------------------------------------------------------
    test('Happy Path: Instanciação com initialConfig customizado define configuração ativa', () {
      // 1. Arrange
      final customConfig = ClientConfig.green();

      // 2. Act
      final service = BrandService(initialConfig: customConfig);

      // 3. Assert
      expect(service.rxConfig.value.id, 'ecotrack');
      expect(service.rxConfig.value.appName, 'EcoTracker');
    });

    test('Happy Path: BrandService.to deve retornar fallbackInstance quando não registrado no GetX', () {
      // 1. Arrange
      Get.reset();

      // 2. Act
      final instance = BrandService.to;

      // 3. Assert
      expect(instance, isNotNull);
      expect(instance.rxConfig.value.id, 'uff');
    });

    test('Happy Path: Getters estáticos current, currentTheme e currentAppName devem refletir marca ativa', () {
      // 1. Arrange
      BrandService.to.resetToDefault();

      // 2. Act
      final appName = BrandService.currentAppName;
      final theme = BrandService.currentTheme;
      final current = BrandService.current;

      // 3. Assert
      expect(appName, 'Monitora UFF');
      expect(theme.primaryColor, const Color(0xFF1D324E));
      expect(current.id, 'uff');
    });

    test('Edge Case: Construtor sem parâmetros deve adotar ClientConfig.uff() por padrão', () {
      // 1. Arrange
      // Nenhuma configuração inicial fornecida

      // 2. Act
      final service = BrandService();

      // 3. Assert
      expect(service.rxConfig.value.id, 'uff');
      expect(service.rxConfig.value.appName, 'Monitora UFF');
    });

    test('Edge Case: Instância independente não deve sobrescrever BrandService global', () {
      // 1. Arrange
      BrandService.to.resetToDefault();
      final localService = BrandService(initialConfig: ClientConfig.green());

      // 2. Act
      final globalAppName = BrandService.currentAppName;

      // 3. Assert
      expect(globalAppName, 'Monitora UFF');
      expect(localService.rxConfig.value.appName, 'EcoTracker');
    });
  });

  group('BrandService - Registro e Injeção no GetX', () {
    // -------------------------------------------------------------
    // Injeção de dependências GetX
    // -------------------------------------------------------------
    test('Happy Path: BrandService.init com initialConfig deve registrar serviço no GetX', () {
      // 1. Arrange
      final customConfig = ClientConfig.green();

      // 2. Act
      final service = BrandService.init(initialConfig: customConfig);

      // 3. Assert
      expect(Get.isRegistered<BrandService>(), isTrue);
      expect(service.rxConfig.value.id, 'ecotrack');
      expect(BrandService.to.rxConfig.value.id, 'ecotrack');
    });

    test('Edge Case: Chamadas subsequentes de BrandService.init devem atualizar instância existente', () {
      // 1. Arrange
      BrandService.init(initialConfig: ClientConfig.uff());
      final newConfig = ClientConfig.green();

      // 2. Act
      final service = BrandService.init(initialConfig: newConfig);

      // 3. Assert
      expect(service.rxConfig.value.id, 'ecotrack');
      expect(Get.find<BrandService>().rxConfig.value.id, 'ecotrack');
    });

    test('Edge Case: BrandService.init sem argumentos deve resolver para configuração UFF', () {
      // 1. Arrange
      Get.reset();

      // 2. Act
      final service = BrandService.init();

      // 3. Assert
      expect(service.rxConfig.value.id, 'uff');
      expect(service.rxConfig.value.appName, 'Monitora UFF');
    });
  });

  group('BrandService - Modificação em Tempo de Execução', () {
    // -------------------------------------------------------------
    // applyConfig e resetToDefault
    // -------------------------------------------------------------
    test('Happy Path: applyConfig deve alterar a configuração ativa', () {
      // 1. Arrange
      final newConfig = ClientConfig.green();

      // 2. Act
      BrandService.to.applyConfig(newConfig);

      // 3. Assert
      expect(BrandService.current.id, 'ecotrack');
      expect(BrandService.currentAppName, 'EcoTracker');
    });

    test('Happy Path: resetToDefault deve restaurar as configurações originais da UFF', () {
      // 1. Arrange
      BrandService.to.applyConfig(ClientConfig.green());

      // 2. Act
      BrandService.to.resetToDefault();

      // 3. Assert
      expect(BrandService.current.id, 'uff');
      expect(BrandService.currentAppName, 'Monitora UFF');
    });

    test('Edge Case: rxConfig deve disparar evento para observadores ao executar applyConfig', () {
      // 1. Arrange
      ClientConfig? observedConfig;
      final subscription = BrandService.to.rxConfig.listen((config) {
        observedConfig = config;
      });

      // 2. Act
      BrandService.to.applyConfig(ClientConfig.green());

      // 3. Assert
      expect(observedConfig?.id, 'ecotrack');
      subscription.cancel();
    });

    // -------------------------------------------------------------
    // applyFromJson e applyFromJsonString
    // -------------------------------------------------------------
    test('Happy Path: applyFromJson deve aplicar configurações a partir de Map', () {
      // 1. Arrange
      final map = {
        'id': 'cliente_agro',
        'appName': 'AgroTracking Pro',
        'logo': {'type': 'asset', 'path': 'assets/agro.png'},
        'theme': {
          'primaryColor': '#2E7D32',
          'secondaryColor': '#81C784',
          'accentColor': '#C8E6C9',
          'backgroundColor': '#1B5E20',
          'surfaceColor': '#388E3C',
        },
      };

      // 2. Act
      BrandService.to.applyFromJson(map);

      // 3. Assert
      expect(BrandService.current.id, 'cliente_agro');
      expect(BrandService.currentAppName, 'AgroTracking Pro');
      expect(BrandService.currentTheme.primaryColor, const Color(0xFF2E7D32));
    });

    test('Happy Path: applyFromJsonString deve aplicar configurações a partir de String JSON', () {
      // 1. Arrange
      final jsonString = jsonEncode({
        'id': 'logistica_express',
        'appName': 'Logística Express',
      });

      // 2. Act
      BrandService.to.applyFromJsonString(jsonString);

      // 3. Assert
      expect(BrandService.current.id, 'logistica_express');
      expect(BrandService.currentAppName, 'Logística Express');
    });

    test('Edge Case: applyFromJson com mapa vazio deve aplicar defaults seguros', () {
      // 1. Arrange
      final emptyMap = <String, dynamic>{};

      // 2. Act
      BrandService.to.applyFromJson(emptyMap);

      // 3. Assert
      expect(BrandService.current.id, 'default');
      expect(BrandService.currentAppName, 'GeoTracking');
    });

    test('Sad Path: applyFromJsonString com JSON malformado deve lançar FormatException', () {
      // 1. Arrange
      const malformedJson = 'not_a_valid_json';

      // 2. Act
      action() => BrandService.to.applyFromJsonString(malformedJson);

      // 3. Assert
      expect(action, throwsA(isA<FormatException>()));
    });

    test('Sad Path: applyFromJsonString com lista JSON deve lançar FormatException de tipo inválido', () {
      // 1. Arrange
      const jsonList = '["invalid", "format"]';

      // 2. Act
      action() => BrandService.to.applyFromJsonString(jsonList);

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
  });

  group('BrandService & AppColors - Reatividade White-Label', () {
    // -------------------------------------------------------------
    // Integração com a Fachada AppColors
    // -------------------------------------------------------------
    test('Happy Path: AppColors.primary deve refletir nova cor primária após applyConfig', () {
      // 1. Arrange
      final greenConfig = ClientConfig.green();

      // 2. Act
      BrandService.to.applyConfig(greenConfig);

      // 3. Assert
      expect(AppColors.primary(), const Color(0xFF1B5E20));
    });

    test('Happy Path: AppColors.primary deve voltar à cor UFF após resetToDefault', () {
      // 1. Arrange
      BrandService.to.applyConfig(ClientConfig.green());

      // 2. Act
      BrandService.to.resetToDefault();

      // 3. Assert
      expect(AppColors.primary(), const Color(0xFF1D324E));
    });

    test('Happy Path: AppColors.secondary deve atualizar para secondaryColor da marca ativa', () {
      // 1. Arrange
      final greenConfig = ClientConfig.green();

      // 2. Act
      BrandService.to.applyConfig(greenConfig);

      // 3. Assert
      expect(AppColors.secondary(), const Color(0xFF4CAF50));
    });

    test('Sad Path: AppColors.primary não deve manter a cor anterior quando a marca é alterada', () {
      // 1. Arrange
      const uffPrimary = Color(0xFF1D324E);

      // 2. Act
      BrandService.to.applyConfig(ClientConfig.green());

      // 3. Assert
      expect(AppColors.primary(), isNot(equals(uffPrimary)));
    });
  });
}
