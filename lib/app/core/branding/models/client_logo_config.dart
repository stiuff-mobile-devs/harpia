import 'package:flutter/material.dart';

/// Tipo de origem do logotipo do cliente.
enum ClientLogoType {
  asset,
  network,
  icon,
}

/// Configuração do logotipo da marca no modelo White-Label.
class ClientLogoConfig {
  final ClientLogoType type;
  final String? path;
  final IconData fallbackIcon;
  final double? width;
  final double? height;

  const ClientLogoConfig({
    required this.type,
    this.path,
    this.fallbackIcon = Icons.location_on,
    this.width,
    this.height,
  });

  /// Construtor de conveniência para logotipo local (asset).
  factory ClientLogoConfig.asset(
    String assetPath, {
    double? width,
    double? height,
    IconData fallbackIcon = Icons.location_on,
  }) {
    return ClientLogoConfig(
      type: ClientLogoType.asset,
      path: assetPath,
      width: width,
      height: height,
      fallbackIcon: fallbackIcon,
    );
  }

  /// Construtor de conveniência para logotipo remoto (network).
  factory ClientLogoConfig.network(
    String url, {
    double? width,
    double? height,
    IconData fallbackIcon = Icons.location_on,
  }) {
    return ClientLogoConfig(
      type: ClientLogoType.network,
      path: url,
      width: width,
      height: height,
      fallbackIcon: fallbackIcon,
    );
  }

  /// Construtor de conveniência para ícone vetorial de fallback.
  factory ClientLogoConfig.icon({
    IconData icon = Icons.location_on,
    double? width,
    double? height,
  }) {
    return ClientLogoConfig(
      type: ClientLogoType.icon,
      fallbackIcon: icon,
      width: width,
      height: height,
    );
  }

  /// Logotipo padrão canônico (Monitora UFF).
  factory ClientLogoConfig.defaultLogo() {
    return ClientLogoConfig.asset(
      'assets/monitora_uff/monitora_uff.png',
      height: 100,
    );
  }

  /// Serialização para Map
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'path': path,
      'fallbackIconCodePoint': fallbackIcon.codePoint,
      'fallbackIconFontFamily': fallbackIcon.fontFamily,
      'width': width,
      'height': height,
    };
  }

  /// Desserialização a partir de Map
  factory ClientLogoConfig.fromMap(Map<String, dynamic> map) {
    ClientLogoType type = ClientLogoType.asset;
    final typeStr = map['type']?.toString().toLowerCase();
    if (typeStr == 'network') {
      type = ClientLogoType.network;
    } else if (typeStr == 'icon') {
      type = ClientLogoType.icon;
    } else {
      type = ClientLogoType.asset;
    }

    IconData fallbackIcon = Icons.location_on;
    if (map['fallbackIconCodePoint'] != null) {
      final codePoint = (map['fallbackIconCodePoint'] as num).toInt();
      final fontFamily = map['fallbackIconFontFamily'] as String?;
      // ignore: non_const_argument_for_const_parameter
      fallbackIcon = IconData(codePoint, fontFamily: fontFamily);
    }

    return ClientLogoConfig(
      type: type,
      path: map['path'] as String?,
      fallbackIcon: fallbackIcon,
      width: (map['width'] as num?)?.toDouble(),
      height: (map['height'] as num?)?.toDouble(),
    );
  }

  ClientLogoConfig copyWith({
    ClientLogoType? type,
    String? path,
    IconData? fallbackIcon,
    double? width,
    double? height,
  }) {
    return ClientLogoConfig(
      type: type ?? this.type,
      path: path ?? this.path,
      fallbackIcon: fallbackIcon ?? this.fallbackIcon,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClientLogoConfig &&
        other.type == type &&
        other.path == path &&
        other.fallbackIcon.codePoint == fallbackIcon.codePoint &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(type, path, fallbackIcon.codePoint, width, height);
}
