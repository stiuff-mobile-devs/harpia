import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harpia/app/core/branding/models/client_theme_config.dart';
import 'package:harpia/app/core/branding/services/brand_service.dart';
import 'package:harpia/app/utils/color_pallete.dart';

void main() {
  group('ClientThemeConfig - Suíte de Testes Unitários', () {
    // -------------------------------------------------------------
    // Presets e Construtores
    // -------------------------------------------------------------
    test('Happy Path: Preset UFF deve conter paleta canônica esperada', () {
      // 1. Arrange
      const expectedPrimary = Color(0xFF1D324E);
      const expectedSecondary = Color(0xFF397DC6);
      const expectedAccent = Color(0xFFCCE5FF);
      const expectedSurface = Color(0xFF213B4F);

      // 2. Act
      final theme = ClientThemeConfig.uff();

      // 3. Assert
      expect(theme.primaryColor, expectedPrimary);
      expect(theme.secondaryColor, expectedSecondary);
      expect(theme.accentColor, expectedAccent);
      expect(theme.backgroundColor, expectedPrimary);
      expect(theme.surfaceColor, expectedSurface);
      expect(theme.textColor, Colors.white);
      expect(theme.customAppBarGradient, isNotNull);
    });

    test('Happy Path: Preset Green deve conter paleta ecológica esperada', () {
      // 1. Arrange
      const expectedPrimary = Color(0xFF1B5E20);
      const expectedSecondary = Color(0xFF4CAF50);
      const expectedAccent = Color(0xFFA5D6A7);
      const expectedBackground = Color(0xFF0F3813);
      const expectedSurface = Color(0xFF18451D);

      // 2. Act
      final theme = ClientThemeConfig.green();

      // 3. Assert
      expect(theme.primaryColor, expectedPrimary);
      expect(theme.secondaryColor, expectedSecondary);
      expect(theme.accentColor, expectedAccent);
      expect(theme.backgroundColor, expectedBackground);
      expect(theme.surfaceColor, expectedSurface);
      expect(theme.textColor, Colors.white);
    });

    test('Edge Case: Construtor deve atribuir Colors.white quando textColor for omitido', () {
      // 1. Arrange
      const primary = Color(0xFF112233);

      // 2. Act
      const theme = ClientThemeConfig(
        primaryColor: primary,
        secondaryColor: Color(0xFF445566),
        accentColor: Color(0xFF778899),
        backgroundColor: Color(0xFF001122),
        surfaceColor: Color(0xFF223344),
      );

      // 3. Assert
      expect(theme.textColor, Colors.white);
    });

    test('Sad Path: Presets UFF e Green devem ser distintos em cores principais', () {
      // 1. Arrange
      final uff = ClientThemeConfig.uff();
      final green = ClientThemeConfig.green();

      // 2. Act
      final areEqual = (uff == green);

      // 3. Assert
      expect(areEqual, isFalse);
    });

    // -------------------------------------------------------------
    // parseHexColor
    // -------------------------------------------------------------
    test('Happy Path: parseHexColor deve interpretar string hex de 6 dígitos com cerquilha', () {
      // 1. Arrange
      const hex = '#1D324E';

      // 2. Act
      final color = ClientThemeConfig.parseHexColor(hex);

      // 3. Assert
      expect(color, const Color(0xFF1D324E));
    });

    test('Happy Path: parseHexColor deve interpretar string hex de 8 dígitos com prefixo 0x', () {
      // 1. Arrange
      const hex = '0xFF397DC6';

      // 2. Act
      final color = ClientThemeConfig.parseHexColor(hex);

      // 3. Assert
      expect(color, const Color(0xFF397DC6));
    });

    test('Happy Path: parseHexColor deve aceitar diretamente número inteiro', () {
      // 1. Arrange
      const hexInt = 0xFFCCE5FF;

      // 2. Act
      final color = ClientThemeConfig.parseHexColor(hexInt);

      // 3. Assert
      expect(color, const Color(0xFFCCE5FF));
    });

    test('Edge Case: parseHexColor deve retornar fallback padrão para entrada nula', () {
      // 1. Arrange
      const dynamic nullInput = null;

      // 2. Act
      final color = ClientThemeConfig.parseHexColor(nullInput);

      // 3. Assert
      expect(color, const Color(0xFF1D324E));
    });

    test('Edge Case: parseHexColor deve retornar fallback padrão para string vazia ou com espaços', () {
      // 1. Arrange
      const whitespaceInput = '    ';

      // 2. Act
      final color = ClientThemeConfig.parseHexColor(whitespaceInput);

      // 3. Assert
      expect(color, const Color(0xFF1D324E));
    });

    test('Edge Case: parseHexColor deve aparar espaços periféricos em string válida', () {
      // 1. Arrange
      const paddedInput = '  #4CAF50  ';

      // 2. Act
      final color = ClientThemeConfig.parseHexColor(paddedInput);

      // 3. Assert
      expect(color, const Color(0xFF4CAF50));
    });

    test('Edge Case: parseHexColor deve respeitar fallback customizado quando especificado', () {
      // 1. Arrange
      const customFallback = Colors.amber;

      // 2. Act
      final color = ClientThemeConfig.parseHexColor(null, fallback: customFallback);

      // 3. Assert
      expect(color, customFallback);
    });

    test('Sad Path: parseHexColor deve retornar fallback para string com caracteres não-hex', () {
      // 1. Arrange
      const invalidHex = '#ZZZZZZ';

      // 2. Act
      final color = ClientThemeConfig.parseHexColor(invalidHex);

      // 3. Assert
      expect(color, const Color(0xFF1D324E));
    });

    test('Sad Path: parseHexColor deve retornar fallback para tamanho de string não suportado', () {
      // 1. Arrange
      const shortHex = '#FFF';

      // 2. Act
      final color = ClientThemeConfig.parseHexColor(shortHex);

      // 3. Assert
      expect(color, const Color(0xFF1D324E));
    });

    test('Sad Path: parseHexColor deve retornar fallback para tipo incompatível', () {
      // 1. Arrange
      const invalidTypeInput = [1, 2, 3];

      // 2. Act
      final color = ClientThemeConfig.parseHexColor(invalidTypeInput);

      // 3. Assert
      expect(color, const Color(0xFF1D324E));
    });

    // -------------------------------------------------------------
    // colorToHex
    // -------------------------------------------------------------
    test('Happy Path: colorToHex deve formatar cor opaca em formato #AARRGGBB maiúsculo', () {
      // 1. Arrange
      const color = Color(0xFF1D324E);

      // 2. Act
      final hexString = ClientThemeConfig.colorToHex(color);

      // 3. Assert
      expect(hexString, '#FF1D324E');
    });

    test('Edge Case: colorToHex deve preservar transparência total com padding de zeros', () {
      // 1. Arrange
      const transparentColor = Color(0x00000000);

      // 2. Act
      final hexString = ClientThemeConfig.colorToHex(transparentColor);

      // 3. Assert
      expect(hexString, '#00000000');
    });

    test('Edge Case: colorToHex deve preencher zeros à esquerda em canais baixos', () {
      // 1. Arrange
      const lowChannelColor = Color(0xFF010203);

      // 2. Act
      final hexString = ClientThemeConfig.colorToHex(lowChannelColor);

      // 3. Assert
      expect(hexString, '#FF010203');
    });

    // -------------------------------------------------------------
    // toMap e fromMap
    // -------------------------------------------------------------
    test('Happy Path: toMap deve serializar todas as cores em strings hexadecimais', () {
      // 1. Arrange
      final theme = ClientThemeConfig.uff();

      // 2. Act
      final map = theme.toMap();

      // 3. Assert
      expect(map['primaryColor'], '#FF1D324E');
      expect(map['secondaryColor'], '#FF397DC6');
      expect(map['accentColor'], '#FFCCE5FF');
      expect(map['backgroundColor'], '#FF1D324E');
      expect(map['surfaceColor'], '#FF213B4F');
      expect(map['textColor'], '#FFFFFFFF');
    });

    test('Happy Path: fromMap deve reconstruir ClientThemeConfig fiel a partir de mapa válido', () {
      // 1. Arrange
      final inputMap = {
        'primaryColor': '#1B5E20',
        'secondaryColor': '#4CAF50',
        'accentColor': '#A5D6A7',
        'backgroundColor': '#0F3813',
        'surfaceColor': '#18451D',
        'textColor': '#FFFFFFFF',
      };

      // 2. Act
      final theme = ClientThemeConfig.fromMap(inputMap);

      // 3. Assert
      expect(theme.primaryColor, const Color(0xFF1B5E20));
      expect(theme.secondaryColor, const Color(0xFF4CAF50));
      expect(theme.accentColor, const Color(0xFFA5D6A7));
      expect(theme.backgroundColor, const Color(0xFF0F3813));
      expect(theme.surfaceColor, const Color(0xFF18451D));
      expect(theme.textColor, Colors.white);
    });

    test('Edge Case: fromMap com mapa vazio deve recorrer aos fallbacks padrões', () {
      // 1. Arrange
      final emptyMap = <String, dynamic>{};

      // 2. Act
      final theme = ClientThemeConfig.fromMap(emptyMap);

      // 3. Assert
      expect(theme.primaryColor, const Color(0xFF1D324E));
      expect(theme.secondaryColor, const Color(0xFF397DC6));
      expect(theme.accentColor, const Color(0xFFCCE5FF));
      expect(theme.surfaceColor, const Color(0xFF213B4F));
      expect(theme.textColor, Colors.white);
    });

    test('Sad Path: fromMap com valores hex corrompidos deve usar fallbacks sem quebrar', () {
      // 1. Arrange
      final corruptedMap = {
        'primaryColor': 'cor_invalida',
        'secondaryColor': null,
        'accentColor': 9999999999999999,
      };

      // 2. Act
      final theme = ClientThemeConfig.fromMap(corruptedMap);

      // 3. Assert
      expect(theme.primaryColor, const Color(0xFF1D324E));
      expect(theme.secondaryColor, const Color(0xFF397DC6));
    });

    // -------------------------------------------------------------
    // Gradientes e ThemeData
    // -------------------------------------------------------------
    test('Happy Path: appBarBottomGradient deve retornar customAppBarGradient quando configurado', () {
      // 1. Arrange
      final theme = ClientThemeConfig.uff();

      // 2. Act
      final gradient = theme.appBarBottomGradient;

      // 3. Assert
      expect(gradient, same(theme.customAppBarGradient));
    });

    test('Edge Case: appBarBottomGradient deve gerar gradiente padrão quando customAppBarGradient for nulo', () {
      // 1. Arrange
      const themeWithoutGradient = ClientThemeConfig(
        primaryColor: Color(0xFF111111),
        secondaryColor: Color(0xFF222222),
        accentColor: Color(0xFF333333),
        backgroundColor: Color(0xFF444444),
        surfaceColor: Color(0xFF555555),
      );

      // 2. Act
      final gradient = themeWithoutGradient.appBarBottomGradient;

      // 3. Assert
      expect(gradient.colors, [const Color(0xFF222222), const Color(0xFF111111)]);
    });

    test('Happy Path: primaryToBlackGradient deve gerar gradiente de cor primária para preto quando customBackgroundGradient for nulo', () {
      // 1. Arrange
      final theme = ClientThemeConfig.uff();

      // 2. Act
      final gradient = theme.primaryToBlackGradient;

      // 3. Assert
      expect(gradient.colors.first, theme.primaryColor);
      expect(gradient.colors.last, Colors.black);
    });

    test('Edge Case: primaryToBlackGradient deve retornar customBackgroundGradient quando definido', () {
      // 1. Arrange
      const customGrad = LinearGradient(colors: [Colors.red, Colors.blue]);
      final theme = ClientThemeConfig.uff().copyWith(customBackgroundGradient: customGrad);

      // 2. Act
      final gradient = theme.primaryToBlackGradient;

      // 3. Assert
      expect(gradient, same(customGrad));
    });

    test('Happy Path: toThemeData deve produzir ThemeData Material 3 escuro com cores da marca', () {
      // 1. Arrange
      final theme = ClientThemeConfig.uff();

      // 2. Act
      final themeData = theme.toThemeData();

      // 3. Assert
      expect(themeData.useMaterial3, isTrue);
      expect(themeData.brightness, Brightness.dark);
      expect(themeData.primaryColor, theme.primaryColor);
      expect(themeData.scaffoldBackgroundColor, theme.backgroundColor);
      expect(themeData.colorScheme.primary, theme.primaryColor);
      expect(themeData.colorScheme.secondary, theme.secondaryColor);
    });

    // -------------------------------------------------------------
    // copyWith e Igualdade
    // -------------------------------------------------------------
    test('Happy Path: copyWith deve atualizar apenas propriedades especificadas', () {
      // 1. Arrange
      final original = ClientThemeConfig.uff();
      const newPrimary = Color(0xFF990000);

      // 2. Act
      final modified = original.copyWith(primaryColor: newPrimary);

      // 3. Assert
      expect(modified.primaryColor, newPrimary);
      expect(modified.secondaryColor, original.secondaryColor);
      expect(modified.accentColor, original.accentColor);
    });

    test('Edge Case: copyWith sem argumentos deve gerar objeto com mesmas propriedades', () {
      // 1. Arrange
      final original = ClientThemeConfig.uff();

      // 2. Act
      final copy = original.copyWith();

      // 3. Assert
      expect(copy, equals(original));
    });

    test('Happy Path: Instâncias com mesmas cores devem ser consideradas iguais e ter mesmo hashCode', () {
      // 1. Arrange
      final theme1 = ClientThemeConfig.uff();
      final theme2 = ClientThemeConfig.uff();

      // 2. Act
      final areEqual = (theme1 == theme2);

      // 3. Assert
      expect(areEqual, isTrue);
      expect(theme1.hashCode, equals(theme2.hashCode));
    });

    test('Sad Path: Instâncias com cores primárias distintas não devem ser iguais', () {
      // 1. Arrange
      final theme1 = ClientThemeConfig.uff();
      final theme2 = theme1.copyWith(primaryColor: const Color(0xFF000000));

      // 2. Act
      final areEqual = (theme1 == theme2);

      // 3. Assert
      expect(areEqual, isFalse);
    });
  });

  group('AppColors - Fachada e Retrocompatibilidade', () {
    setUp(() {
      BrandService.to.resetToDefault();
    });

    tearDown(() {
      BrandService.to.resetToDefault();
    });

    test('Happy Path: AppColors deve expor cores principais correspondentes ao BrandService ativo', () {
      // 1. Arrange
      final expectedTheme = BrandService.currentTheme;

      // 2. Act
      final primary = AppColors.primary();

      // 3. Assert
      expect(primary, expectedTheme.primaryColor);
    });

    test('Happy Path: Métodos legados devem delegar às novas cores de marca', () {
      // 1. Arrange
      final expectedPrimary = AppColors.primary();
      final expectedSecondary = AppColors.secondary();
      final expectedAccent = AppColors.accent();
      final expectedSurface = AppColors.surface();

      // 2. Act
      final darkBlue = AppColors.darkBlue();
      final mediumBlue = AppColors.mediumBlue();
      final lightBlue = AppColors.lightBlue();
      final altDarkBlue = AppColors.alternativeDarkBlue();

      // 3. Assert
      expect(darkBlue, expectedPrimary);
      expect(mediumBlue, expectedSecondary);
      expect(lightBlue, expectedAccent);
      expect(altDarkBlue, expectedSurface);
    });

    test('Edge Case: primary com alpha customizado deve alterar canal de opacidade', () {
      // 1. Arrange
      const alphaValue = 120;

      // 2. Act
      final colorWithAlpha = AppColors.primary(alpha: alphaValue);

      // 3. Assert
      expect(colorWithAlpha.a, closeTo(120 / 255.0, 0.01));
    });

    test('Happy Path: darkBlueToBlackGradient deve iniciar na cor primária e terminar em preto', () {
      // 1. Arrange
      final expectedStart = AppColors.primary();

      // 2. Act
      final gradient = AppColors.darkBlueToBlackGradient();

      // 3. Assert
      expect(gradient.colors.first, expectedStart);
      expect(gradient.colors.last, Colors.black);
    });

    test('Happy Path: appBarTopGradient deve combinar secondary e primary', () {
      // 1. Arrange
      final expectedSec = AppColors.secondary();
      final expectedPri = AppColors.primary();

      // 2. Act
      final gradient = AppColors.appBarTopGradient();

      // 3. Assert
      expect(gradient.colors, [expectedSec, expectedPri]);
    });

    test('Happy Path: appBarBottomGradient deve retornar gradiente customizado do tema ativo', () {
      // 1. Arrange
      final expectedThemeGradient = BrandService.currentTheme.customAppBarGradient;

      // 2. Act
      final gradient = AppColors.appBarBottomGradient();

      // 3. Assert
      expect(gradient, expectedThemeGradient);
    });

    test('Edge Case: darkTransparentGradient deve aplicar opacidade 0.2 na cor preta', () {
      // 1. Arrange
      final expectedColor = Colors.black.withValues(alpha: 0.2);

      // 2. Act
      final gradient = AppColors.darkTransparentGradient();

      // 3. Assert
      expect(gradient.colors.first, expectedColor);
    });
  });
}
