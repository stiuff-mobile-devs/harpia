import 'package:harpia/app/modules/login/controllers/auth_google_controller.dart';
import 'package:harpia/app/modules/monitora_uff/controller/google_groups_controller.dart';
import 'package:harpia/app/modules/monitora_uff/controller/permissions_controller.dart';
import 'package:harpia/app/modules/monitora_uff/controller/tracking_controller.dart';
import 'package:harpia/app/modules/monitora_uff/controller/user_controller.dart';
import 'package:get/get.dart';

class MonitoraUffBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserController>(() => UserController());
    Get.lazyPut<TrackingController>(() => TrackingController());
    Get.lazyPut<PermissionsController>(() => PermissionsController());
    Get.lazyPut(() => AuthGoogleController());
    Get.lazyPut(() => GoogleGroupsController());
  }
}
