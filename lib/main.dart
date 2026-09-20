import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:harpia/app/core/branding/services/brand_service.dart';
import 'package:harpia/app/data/models/user_google_model.dart';
import 'package:harpia/firebase_options.dart';

import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/routes/app_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialização da arquitetura White-Label
  final brandService = BrandService.init();

  await Hive.initFlutter();
  Hive.registerAdapter(UserGoogleModelAdapter());

  await Firebase.initializeApp(
    //name: 'uffmobileplus',
    options: FirebaseOptionsHarpia.currentPlatform,
  );

  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: brandService.rxConfig.value.appName,
      theme: brandService.rxConfig.value.theme.toThemeData(),
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
    ),
  );
}
