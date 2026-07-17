import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:harpia/app/modules/monitora_uff/data/provider/firebase_provider.dart';
import 'package:harpia/firebase_options.dart';

Timer? _heartbeatTimer;
int interval = 5;
int distance = 10;
int heartbeatInterval = 5;

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  await Firebase.initializeApp(
    //name: 'uffmobileplus',
    options: FirebaseOptionsHarpia.currentPlatform,
  );

  service.on('stopService').listen((event) {
    _heartbeatTimer?.cancel();
    service.stopSelf();
  });

  service.on('setUserInfo').listen((event) {
    if (event != null) {
      updateLocation(service, event['email'], event['name'], event['funcao']);
    }
  });

  // TODO: usar shared preferences?
  service.invoke('ready');
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}

// TODO: passar UserModel para essa função em vez de email, nome.
void updateLocation(ServiceInstance service, String email, String name, String funcao) {
  // Configuração do GPS
  late LocationSettings locationSettings;

  if (Platform.isAndroid) {
    locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high, // TODO: testar outros valores aqui
      distanceFilter: distance, // Só atualiza se mover mais de 10 metros
      intervalDuration: Duration(minutes: interval),
    );
  } else if (Platform.isIOS) {
    locationSettings = AppleSettings(
      accuracy: LocationAccuracy.high,
      activityType: ActivityType.other,
      distanceFilter: distance,
      pauseLocationUpdatesAutomatically: true,
      showBackgroundLocationIndicator: true,
    );
  } else {
    locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distance,
    );
  }

  _heartbeatTimer?.cancel();
  _heartbeatTimer = Timer.periodic(Duration(minutes: heartbeatInterval), (timer) async {
    if (await FirebaseProvider().doesDocumentExist(email)) {
      await FirebaseProvider().updateHeartbeat(email);
    }
  });

  Geolocator.getPositionStream(locationSettings: locationSettings).listen((
    Position position,
  ) async {
    // print("\n\n${position.accuracy}\n\n");
    // TODO: Filtro de precisão: Se o erro for maior que 20 metros, ignorar
    // e.g.: if (position.accuracy > 20) return;

    // Atualiza firebase 
    if (await FirebaseProvider().doesDocumentExist(email)) {
      await FirebaseProvider().updateLocationAndTimestamp(
        email: email,
        nome: name,
        funcao: funcao,
        lat: position.latitude,
        lng: position.longitude,
        timestamp: DateTime.now(),
      );
    }

    // Envia para o app principal
    service.invoke('updateLocationLocally', {'position': position});
  });
}
