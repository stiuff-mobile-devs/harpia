import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/client_logo_config.dart';
import '../services/brand_service.dart';

/// Widget desacoplado para exibição do logotipo do cliente White-Label.
class ClientLogoWidget extends StatelessWidget {
  final ClientLogoConfig? logoConfig;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ClientLogoWidget({
    super.key,
    this.logoConfig,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    // Se nenhum logoConfig for explicitamente passado, escuta reativamente o BrandService
    if (logoConfig == null) {
      if (Get.isRegistered<BrandService>()) {
        return Obx(() {
          final activeConfig = BrandService.current.logo;
          return _buildLogo(activeConfig);
        });
      }
      return _buildLogo(ClientLogoConfig.defaultLogo());
    }

    return _buildLogo(logoConfig!);
  }

  Widget _buildLogo(ClientLogoConfig config) {
    final effectiveWidth = width ?? config.width;
    final effectiveHeight = height ?? config.height ?? 80;

    switch (config.type) {
      case ClientLogoType.asset:
        if (config.path != null && config.path!.isNotEmpty) {
          return Image.asset(
            config.path!,
            width: effectiveWidth,
            height: effectiveHeight,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _buildFallback(config, effectiveWidth, effectiveHeight),
          );
        }
        return _buildFallback(config, effectiveWidth, effectiveHeight);

      case ClientLogoType.network:
        if (config.path != null && config.path!.isNotEmpty) {
          return Image.network(
            config.path!,
            width: effectiveWidth,
            height: effectiveHeight,
            fit: fit,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return SizedBox(
                width: effectiveWidth,
                height: effectiveHeight,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => _buildFallback(config, effectiveWidth, effectiveHeight),
          );
        }
        return _buildFallback(config, effectiveWidth, effectiveHeight);

      case ClientLogoType.icon:
        return _buildFallback(config, effectiveWidth, effectiveHeight);
    }
  }

  Widget _buildFallback(ClientLogoConfig config, double? width, double? height) {
    final size = (height != null && width != null)
        ? (height < width ? height : width)
        : (height ?? width ?? 48);

    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: Icon(
          config.fallbackIcon,
          size: size * 0.8,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}
