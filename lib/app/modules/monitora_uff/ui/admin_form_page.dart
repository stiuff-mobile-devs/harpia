import 'package:flutter/material.dart';
import 'package:harpia/app/modules/monitora_uff/controller/form_controller.dart';
import 'package:harpia/app/modules/monitora_uff/models/user_model.dart';
import 'package:harpia/app/utils/color_pallete.dart';
import 'package:get/get.dart';

/// Create or edit a user
class AdminFormPage extends GetView<FormController> {
  const AdminFormPage({super.key});

  AppBar _appBar() {
    return AppBar(
      title: Text(
        controller.selectedUser == null
            ? 'Cadastro de usuário'
            : 'Edição de usuário',
      ),
      centerTitle: true,
      elevation: 8,
      foregroundColor: Colors.white,
      flexibleSpace: Container(
        decoration: BoxDecoration(gradient: AppColors.appBarBottomGradient()),
      ),
    );
  }

  Widget _emailField() {
    return TextFormField(
      controller: controller.textEditingController,
      decoration: InputDecoration(
        labelText: 'Email',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _rolesDropdownButton() {
    return DropdownButtonFormField<String>(
      initialValue: controller.role,
      decoration: InputDecoration(
        //labelText: 'Função',
        labelStyle: const TextStyle(color: Colors.white),
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      items: const [
        DropdownMenuItem(value: 'administrador', child: Text('Administrador')),
        DropdownMenuItem(value: 'monitor', child: Text('Monitor')),
      ],
      onChanged: (value) {
        controller.role = value!;
      },
    );
  }

  Widget _confirmationButton() {
    return ElevatedButton(
      onPressed: () {
        controller.setUser(
          UserModel(
            email: controller.textEditingController.text,
            funcao: controller.role,
          ),
        );
        Get.back();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkBlue(),
      ),
      child: Text(
        controller.selectedUser == null
            ? 'Adicionar usuário'
            : 'Editar usuário',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.darkBlueToBlackGradient(),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            child: Column(
              children: [
                _emailField(),
                const SizedBox(height: 16),
                _rolesDropdownButton(),
                const Spacer(),
                _confirmationButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
