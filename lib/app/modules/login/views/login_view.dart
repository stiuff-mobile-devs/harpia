import 'package:flutter/material.dart';
import 'package:harpia/app/modules/login/controllers/auth_google_controller.dart';
import 'package:harpia/app/modules/login/controllers/login_controller.dart';
import 'package:get/get.dart';

import 'widgets/google_button.dart';


class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  AppBar _appBar() {
    return AppBar(
        title: const Text('Harpia UFF'),
        centerTitle: true,
      );
  }

  Widget _body() {
    return Center(
        child: _loginButton()
      );
  }

  Widget _loginButton() {
    final authController = Get.find<AuthGoogleController>();

    // Obx reconstrói esse widget quando googleReady mudar de valor
    return Obx(() {
      if (!authController.googleReady.value) {
        return const CircularProgressIndicator();
      }
      return buildGoogleButton(() => controller.loginGoogle());
    });
  }  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: _body()
    );
  }
}
