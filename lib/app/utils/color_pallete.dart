import 'package:flutter/material.dart';
import 'package:harpia/app/core/branding/services/brand_service.dart';

/// Fachada de Cores e Gradientes compatível com a arquitetura White-Label.
/// Os métodos legados (darkBlue, mediumBlue, etc.) continuam funcionando normalmente,
/// delegando dinamicamente para o tema ativo do cliente configurado via [BrandService].
class AppColors {
  /// Cor primária da marca do cliente ativo.
  static Color primary({int alpha = 255}) =>
      BrandService.currentTheme.primaryColor.withAlpha(alpha);

  /// Cor secundária da marca do cliente ativo.
  static Color secondary({int alpha = 255}) =>
      BrandService.currentTheme.secondaryColor.withAlpha(alpha);

  /// Cor de destaque/light da marca do cliente ativo.
  static Color accent({int alpha = 255}) =>
      BrandService.currentTheme.accentColor.withAlpha(alpha);

  /// Cor de fundo da marca do cliente ativo.
  static Color background({int alpha = 255}) =>
      BrandService.currentTheme.backgroundColor.withAlpha(alpha);

  /// Cor de superfície da marca do cliente ativo.
  static Color surface({int alpha = 255}) =>
      BrandService.currentTheme.surfaceColor.withAlpha(alpha);

  // --- Métodos de Retrocompatibilidade (preservam nomes legados da UFF) ---
  static Color darkBlue({int alpha = 255}) => primary(alpha: alpha);
  static Color lightBlue({int alpha = 255}) => accent(alpha: alpha);
  static Color mediumBlue({int alpha = 255}) => secondary(alpha: alpha);
  static Color alternativeDarkBlue({int alpha = 255}) => surface(alpha: alpha);
  static Color alternativeMediumBlue({int alpha = 255}) => secondary(alpha: alpha);

  static LinearGradient darkBlueToBlackGradient({
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      colors: [
        primary(),
        Colors.black,
      ],
      begin: begin,
      end: end,
    );
  }

  static LinearGradient appBarTopGradient({
    Alignment begin = Alignment.topCenter,
    Alignment end = Alignment.bottomCenter,
  }) {
    return LinearGradient(
      colors: [
        secondary(),
        primary(),
      ],
      begin: begin,
      end: end,
    );
  }

  static LinearGradient appBarBottomGradient({
    Alignment begin = Alignment.topCenter,
    Alignment end = Alignment.bottomCenter,
  }) {
    final customGradient = BrandService.currentTheme.customAppBarGradient;
    if (customGradient != null) {
      return customGradient;
    }
    return LinearGradient(
      colors: [
        secondary(),
        primary(),
      ],
      begin: begin,
      end: end,
    );
  }

  static LinearGradient darkTransparentGradient() {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.black.withValues(alpha: 0.2),
        Colors.black.withValues(alpha: 0.2),
      ],
    );
  }
}