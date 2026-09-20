import 'package:flutter/material.dart';
import 'package:harpia/app/core/branding/services/brand_service.dart';
import 'package:harpia/app/core/branding/widgets/client_logo_widget.dart';
import 'package:harpia/app/modules/login/controllers/auth_google_controller.dart';
import 'package:harpia/app/modules/login/controllers/login_controller.dart';
import 'package:get/get.dart';
import 'package:harpia/app/utils/color_pallete.dart';

import 'widgets/google_button.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  AppBar _appBar() {
    return AppBar(
      title: Obx(() => Text(
            BrandService.currentAppName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          )),
      centerTitle: true,
      backgroundColor: AppColors.primary(),
      elevation: 0,
    );
  }

  Widget _body() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const ClientLogoWidget(height: 110),
            const SizedBox(height: 40),
            _loginButton(),
          ],
        ),
      ),
    );
  }

  Widget _loginButton() {
    final authController = Get.find<AuthGoogleController>();

    // Obx reconstrói esse widget quando googleReady ou isLoading mudar de valor
    return Obx(() {
      if (!authController.googleReady.value) {
        return const CircularProgressIndicator();
      }
      if (authController.isLoading.value) {
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              "Fazendo login...",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        );
      }
      return buildGoogleButton(() => controller.loginGoogle());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(),
      appBar: _appBar(),
      body: _body(),
    );
  }
}
