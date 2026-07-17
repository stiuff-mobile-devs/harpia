import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:harpia/app/modules/login/controllers/auth_google_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:harpia/app/utils/color_pallete.dart';

class HarpiaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HarpiaAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      flexibleSpace: Container(
        decoration: BoxDecoration(gradient: AppColors.appBarBottomGradient()),
      ),
      title: const Text('Harpia'),
      centerTitle: true,
      elevation: 8,
      foregroundColor: Colors.white,
      actions: [
        PopupMenuButton(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Builder(builder: (context) {
              final user = FirebaseAuth.instance.currentUser;
              return CircleAvatar(
                backgroundImage:
                    user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              );
            }),
          ),
          onSelected: (value) {
            if (value == 'sair') {
              Get.find<AuthGoogleController>().logout();
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'sair',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Sair', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          ],
        )
      ],
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}