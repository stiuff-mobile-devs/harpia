import 'package:harpia/app/modules/monitora_uff/bindings/form_bindings.dart';
import 'package:harpia/app/modules/monitora_uff/bindings/monitora_uff_bindings.dart';
import 'package:harpia/app/modules/monitora_uff/ui/admin_form_page.dart';
import 'package:harpia/app/modules/monitora_uff/ui/monitora_uff_page.dart';
import 'package:get/get.dart';

import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.LOGIN;

  static final routes = [
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.MONITORA_UFF,
      page: () => const MonitoraUFFPage(),
      binding: MonitoraUffBindings()
    ),
    GetPage(
      name: _Paths.MONITORA_UFF_FORM,
      page: () => const AdminFormPage(),
      binding: FormBindings()
    ),
  ];
}
