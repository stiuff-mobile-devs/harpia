import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:harpia/app/modules/monitora_uff/controller/google_groups_controller.dart';
import 'package:harpia/app/modules/monitora_uff/models/google_group_model.dart';
import 'package:harpia/app/utils/color_pallete.dart';

class GroupSelector extends StatelessWidget {
  const GroupSelector({super.key});

  GoogleGroupsController get googleGroupsController => Get.find<GoogleGroupsController>();

  Widget _group(GoogleGroupModel group) {
    return ListTile(
      title: Text(
        group.name,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(group.email, style: TextStyle(color: Colors.white, fontSize: 13)),
          if (group.description.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              group.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white60, fontSize: 12),
            )
          ]
        ],
      ),
      isThreeLine: true,
      onTap: () {
        googleGroupsController.updateObservedUsers(group);
        Get.back();
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.darkBlue(),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: AppColors.darkBlue()),
            child: Column(
              children: [
                Text('Grupos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24)),
              ],
            ),
          ),
          // Lista dos grupos carregados dinamicamente da API
          Obx(() {
            if (googleGroupsController.isLoading.value) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(color: Colors.white)),
              );
            }

            if (googleGroupsController.googleGroups.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('Nenhum grupo disponível', style: TextStyle(color: Colors.white))),
              );
            }

            return Column(
              children: googleGroupsController.googleGroups.map((item) {
                return _group(item);
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}

