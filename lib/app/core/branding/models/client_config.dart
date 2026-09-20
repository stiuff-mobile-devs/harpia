import 'dart:convert';
import 'package:flutter/material.dart';
import 'client_logo_config.dart';
import 'client_theme_config.dart';

/// Modelo agregado mestre da configuração de cliente no modelo White-Label.
class ClientConfig {
  final String id;
  final String appName;
  final ClientLogoConfig logo;
  final ClientThemeConfig theme;
  final Map<String, dynamic>? features;

  const ClientConfig({
    required this.id,
    required this.appName,
    required this.logo,
    required this.theme,
    this.features,
  });

  /// Preset canônico padrão (Monitora UFF / Harpia).
  factory ClientConfig.uff() {
    return ClientConfig(
      id: 'uff',
      appName: 'Monitora UFF',
      logo: ClientLogoConfig.defaultLogo(),
      theme: ClientThemeConfig.uff(),
    );
  }

  /// Preset para demonstração corporativa (ex: EcoTrack).
  factory ClientConfig.green() {
    return ClientConfig(
      id: 'ecotrack',
      appName: 'EcoTracker',
      logo: ClientLogoConfig.icon(icon: const IconData(0xe22d, fontFamily: 'MaterialIcons')), // eco icon
      theme: ClientThemeConfig.green(),
    );
  }

  /// Serialização para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'appName': appName,
      'logo': logo.toMap(),
      'theme': theme.toMap(),
      if (features != null) 'features': features,
    };
  }

  /// Serialização para string JSON
  String toJson() => jsonEncode(toMap());

  /// Desserialização a partir de Map
  factory ClientConfig.fromMap(Map<String, dynamic> map) {
    return ClientConfig(
      id: map['id']?.toString() ?? 'default',
      appName: map['appName']?.toString() ?? 'GeoTracking',
      logo: map['logo'] is Map<String, dynamic>
          ? ClientLogoConfig.fromMap(map['logo'] as Map<String, dynamic>)
          : ClientLogoConfig.defaultLogo(),
      theme: map['theme'] is Map<String, dynamic>
          ? ClientThemeConfig.fromMap(map['theme'] as Map<String, dynamic>)
          : ClientThemeConfig.uff(),
      features: map['features'] is Map<String, dynamic>
          ? map['features'] as Map<String, dynamic>
          : null,
    );
  }

  /// Desserialização a partir de string JSON
  factory ClientConfig.fromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('O JSON de configuração do cliente deve ser um objeto Map.');
    }
    return ClientConfig.fromMap(decoded);
  }

  ClientConfig copyWith({
    String? id,
    String? appName,
    ClientLogoConfig? logo,
    ClientThemeConfig? theme,
    Map<String, dynamic>? features,
  }) {
    return ClientConfig(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      logo: logo ?? this.logo,
      theme: theme ?? this.theme,
      features: features ?? this.features,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClientConfig &&
        other.id == id &&
        other.appName == appName &&
        other.logo == logo &&
        other.theme == theme;
  }

  @override
  int get hashCode => Object.hash(id, appName, logo, theme);
}
