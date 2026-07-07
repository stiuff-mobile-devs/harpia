import 'package:harpia/app/modules/monitora_uff/controller/form_controller.dart';
import 'package:get/get.dart';

class FormBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FormController>(() => FormController());
  }
}
