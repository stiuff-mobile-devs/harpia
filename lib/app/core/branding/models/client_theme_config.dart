import 'package:flutter/material.dart';

/// Configuração do tema e paleta de cores no modelo White-Label.
class ClientThemeConfig {
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final LinearGradient? customAppBarGradient;
  final LinearGradient? customBackgroundGradient;

  const ClientThemeConfig({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.surfaceColor,
    this.textColor = Colors.white,
    this.customAppBarGradient,
    this.customBackgroundGradient,
  });

  /// Configuração canônica da UFF (retrocompatibilidade).
  factory ClientThemeConfig.uff() {
    return const ClientThemeConfig(
      primaryColor: Color(0xFF1D324E), // darkBlue
      secondaryColor: Color(0xFF397DC6), // mediumBlue
      accentColor: Color(0xFFCCE5FF), // lightBlue
      backgroundColor: Color(0xFF1D324E),
      surfaceColor: Color(0xFF213B4F), // alternativeDarkBlue
      textColor: Colors.white,
      customAppBarGradient: LinearGradient(
        colors: [Color(0xFF2A5E93), Color(0xFF213B4F)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  /// Preset verde corporativo (EcoTracker / Agronegócio / Sustentabilidade).
  factory ClientThemeConfig.green() {
    return const ClientThemeConfig(
      primaryColor: Color(0xFF1B5E20),
      secondaryColor: Color(0xFF4CAF50),
      accentColor: Color(0xFFA5D6A7),
      backgroundColor: Color(0xFF0F3813),
      surfaceColor: Color(0xFF18451D),
      textColor: Colors.white,
      customAppBarGradient: LinearGradient(
        colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  /// Converte código hexadecimal flexível para Color com fallback seguro.
  static Color parseHexColor(dynamic hex, {Color fallback = const Color(0xFF1D324E)}) {
    if (hex == null) return fallback;
    if (hex is int) return Color(hex);
    if (hex is! String) return fallback;

    var cleaned = hex.replaceAll('#', '').replaceAll('0x', '').trim();
    if (cleaned.isEmpty) return fallback;

    try {
      if (cleaned.length == 6) {
        cleaned = 'FF$cleaned';
      }
      if (cleaned.length == 8) {
        return Color(int.parse(cleaned, radix: 16));
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  /// Converte Color para String Hex (#AARRGGBB)
  static String colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  /// Serialização para Map
  Map<String, dynamic> toMap() {
    return {
      'primaryColor': colorToHex(primaryColor),
      'secondaryColor': colorToHex(secondaryColor),
      'accentColor': colorToHex(accentColor),
      'backgroundColor': colorToHex(backgroundColor),
      'surfaceColor': colorToHex(surfaceColor),
      'textColor': colorToHex(textColor),
    };
  }

  /// Desserialização a partir de Map
  factory ClientThemeConfig.fromMap(Map<String, dynamic> map) {
    const defaultUff = Color(0xFF1D324E);
    const defaultSec = Color(0xFF397DC6);
    const defaultAcc = Color(0xFFCCE5FF);

    return ClientThemeConfig(
      primaryColor: parseHexColor(map['primaryColor'], fallback: defaultUff),
      secondaryColor: parseHexColor(map['secondaryColor'], fallback: defaultSec),
      accentColor: parseHexColor(map['accentColor'], fallback: defaultAcc),
      backgroundColor: parseHexColor(map['backgroundColor'], fallback: defaultUff),
      surfaceColor: parseHexColor(map['surfaceColor'], fallback: const Color(0xFF213B4F)),
      textColor: parseHexColor(map['textColor'], fallback: Colors.white),
    );
  }

  /// Gradiente padrão para AppBar
  LinearGradient get appBarBottomGradient {
    return customAppBarGradient ??
        LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [secondaryColor, primaryColor],
        );
  }

  /// Gradiente superior de AppBar
  LinearGradient get appBarTopGradient {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [secondaryColor, primaryColor],
    );
  }

  /// Gradiente escuro para preto
  LinearGradient get primaryToBlackGradient {
    return customBackgroundGradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, Colors.black],
        );
  }

  /// Gera um ThemeData padrão completo do Flutter baseado nas cores da marca
  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        onPrimary: textColor,
        onSecondary: Colors.white,
        onSurface: textColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: textColor,
        elevation: 4,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
        ),
      ),
    );
  }

  ClientThemeConfig copyWith({
    Color? primaryColor,
    Color? secondaryColor,
    Color? accentColor,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? textColor,
    LinearGradient? customAppBarGradient,
    LinearGradient? customBackgroundGradient,
  }) {
    return ClientThemeConfig(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      textColor: textColor ?? this.textColor,
      customAppBarGradient: customAppBarGradient ?? this.customAppBarGradient,
      customBackgroundGradient: customBackgroundGradient ?? this.customBackgroundGradient,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClientThemeConfig &&
        other.primaryColor.toARGB32() == primaryColor.toARGB32() &&
        other.secondaryColor.toARGB32() == secondaryColor.toARGB32() &&
        other.accentColor.toARGB32() == accentColor.toARGB32() &&
        other.backgroundColor.toARGB32() == backgroundColor.toARGB32() &&
        other.surfaceColor.toARGB32() == surfaceColor.toARGB32() &&
        other.textColor.toARGB32() == textColor.toARGB32();
  }

  @override
  int get hashCode => Object.hash(
        primaryColor.toARGB32(),
        secondaryColor.toARGB32(),
        accentColor.toARGB32(),
        backgroundColor.toARGB32(),
        surfaceColor.toARGB32(),
        textColor.toARGB32(),
      );
}
