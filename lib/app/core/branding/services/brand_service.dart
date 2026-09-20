import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/client_config.dart';
import '../models/client_theme_config.dart';

/// Serviço de gerenciamento de marca e tenant para a arquitetura White-Label.
class BrandService extends GetxService {
  late final Rx<ClientConfig> _currentConfig;

  // Singleton de contingência para testes e isolates sem GetX inicializado
  static final BrandService _fallbackInstance = BrandService._internal();

  BrandService._internal() {
    _currentConfig = ClientConfig.uff().obs;
  }

  BrandService({ClientConfig? initialConfig}) {
    _currentConfig = (initialConfig ?? ClientConfig.uff()).obs;
  }

  /// Retorna a instância ativa do BrandService via GetX ou a de contingência.
  static BrandService get to {
    if (Get.isRegistered<BrandService>()) {
      return Get.find<BrandService>();
    }
    return _fallbackInstance;
  }

  /// Atalho de acesso estático para a configuração de cliente ativa.
  static ClientConfig get current => to._currentConfig.value;

  /// Atalho de acesso estático para o tema ativo.
  static ClientThemeConfig get currentTheme => current.theme;

  /// Atalho de acesso estático para o nome da aplicação.
  static String get currentAppName => current.appName;

  /// Getter reativo da configuração atual.
  Rx<ClientConfig> get rxConfig => _currentConfig;

  /// Inicializa o serviço e o registra no container de injeção de dependência do GetX.
  static BrandService init({ClientConfig? initialConfig}) {
    // 1. Tentar detectar via variáveis de ambiente de compilação (--dart-define)
    ClientConfig resolvedConfig = initialConfig ?? _resolveEnvironmentConfig();

    BrandService service;
    if (Get.isRegistered<BrandService>()) {
      service = Get.find<BrandService>();
      service.applyConfig(resolvedConfig);
    } else {
      service = BrandService(initialConfig: resolvedConfig);
      Get.put<BrandService>(service, permanent: true);
    }

    return service;
  }

  /// Resolve a configuração a partir de parâmetros de compilação (--dart-define).
  static ClientConfig _resolveEnvironmentConfig() {
    const envClientId = String.fromEnvironment('CLIENT_ID', defaultValue: '');
    const envClientConfig = String.fromEnvironment('CLIENT_CONFIG', defaultValue: '');

    if (envClientConfig.isNotEmpty) {
      try {
        return ClientConfig.fromJson(envClientConfig);
      } catch (e) {
        debugPrint('[BrandService] Falha ao processar CLIENT_CONFIG da compilação: $e');
      }
    }

    if (envClientId.toLowerCase() == 'green' || envClientId.toLowerCase() == 'ecotrack') {
      return ClientConfig.green();
    }

    // Padrão canônico da UFF
    return ClientConfig.uff();
  }

  /// Aplica uma nova configuração de cliente em tempo de execução.
  void applyConfig(ClientConfig newConfig) {
    _currentConfig.value = newConfig;

    // Atualiza o tema global do Flutter se o contexto estiver montado
    try {
      if (Get.context != null) {
        Get.changeTheme(newConfig.theme.toThemeData());
      }
    } catch (_) {}
  }

  /// Aplica a configuração enviada por um cliente em formato Map/JSON em tempo de execução.
  void applyFromJson(Map<String, dynamic> json) {
    final config = ClientConfig.fromMap(json);
    applyConfig(config);
  }

  /// Aplica a configuração enviada por um cliente a partir de string JSON.
  void applyFromJsonString(String jsonStr) {
    final config = ClientConfig.fromJson(jsonStr);
    applyConfig(config);
  }

  /// Restaura a configuração para o padrão original da UFF.
  void resetToDefault() {
    applyConfig(ClientConfig.uff());
  }
}
