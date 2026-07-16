import 'dart:async';
import 'dart:io';

//import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
  show
    AlertDialog,
    BorderSide,
    BuildContext,
    ColorScheme,
    Colors,
    DatePickerThemeData,
    Text,
    TextButton,
    TextButtonThemeData,
    TextStyle,
    Theme,
    WidgetState,
    WidgetStateColor,
    WidgetsBindingObserver,
    showDatePicker;
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
//import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:harpia/app/utils/color_pallete.dart';
import 'package:harpia/app/modules/monitora_uff/controller/user_controller.dart';
import 'package:harpia/app/modules/monitora_uff/data/provider/firebase_provider.dart';
import 'package:harpia/app/modules/monitora_uff/models/animated_user_marker.dart';
import 'package:harpia/app/modules/monitora_uff/models/location_point.dart';
import 'package:harpia/app/modules/monitora_uff/models/user_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:harpia/app/data/services/foreground_service.dart';


class TrackingController extends GetxController with WidgetsBindingObserver {
  final FlutterBackgroundService _service = FlutterBackgroundService();
  Position position = Position(
    latitude: -22.9041, // latitude em Niterói
    longitude: -43.1329, // longitude em Niterói
    timestamp: DateTime.now(),
    accuracy: 0,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
  RxList<UserModel> firebaseUsers = <UserModel>[].obs;
  final Rxn<UserModel> selectedFirebaseUser = Rxn<UserModel>();
  late final MapController mapController;
  final isTrackingEnabled = false.obs;
  final UserController userCtrl = Get.find<UserController>();
  final Rx<double?> heading = Rx<double?>(null);
  //StreamSubscription<CompassEvent>? _compassSubscription;

  /// Mapa de usuários com suas posições animadas para renderização suave.
  final Map<String, AnimatedUserMarker> _animatedMarkers =
      <String, AnimatedUserMarker>{};

  /// RxMap reativo dos marcadores animados para trigger rebuilds na UI.
  final RxMap<String, LatLng> animatedMarkerPositions = <String, LatLng>{}.obs;

  /// Timer para animar a transição dos marcadores.
  Timer? _markerAnimationTimer;

  /// Progresso da animação (0.0 a 1.0).
  double _animationProgress = 1.0;

  /// Duração da animação em milissegundos.
  static const int _animationDurationMs = 500;

  /// Trajetória recente do usuário focado (aquele cuja barra inferior está visível).
  final RxList<LocationPoint> selectedTrajectory = <LocationPoint>[].obs;
  final Rxn<DateTime> selectedTrajectoryDay = Rxn<DateTime>();
  StreamSubscription<List<LocationPoint>>? _trajectorySubscription;
  Future<void> centerMapOnCurrentLocation() async {
    try {
      mapController.move(LatLng(position.latitude, position.longitude), 15.0);
    } catch (e) {
      if (kDebugMode) print('Error moving map: $e');
    }
  }

  @override
  Future<void> onInit() async {
    // Getx irá automaticamente atualizar 'firebaseUsers' sempre que os
    // documentos forem atualizados na nuvem

    super.onInit();
    mapController = MapController();

    // Vincula o stream do Firebase aos usuários rastreados
    //firebaseUsers.bindStream(FirebaseProvider().getAllTrackedUsers());
    firebaseUsers.bindStream(FirebaseProvider().getAllUsers());
    
    // Escuta mudanças na lista de usuários para atualizar as animações
    ever(firebaseUsers, _onFirebaseUsersUpdated);

    //try {
    //  _compassSubscription = FlutterCompass.events?.listen((event) {
    //    heading.value = event.heading;
    //  });
    //} catch (e) {
    //  if (kDebugMode) print('Compass not available or error: $e');
    //}

    // TODO: encapsular em um método
    if (userCtrl.isTrackable()) {
      position = await Geolocator.getCurrentPosition();
    }

    isTrackingEnabled.value = await _service.isRunning();
  }

  /// Chamado quando a lista de usuários do Firebase é atualizada.
  /// Inicializa ou atualiza as animações dos marcadores.
  void _onFirebaseUsersUpdated(List<UserModel> users) {
    bool shouldAnimateMarkers = false;

    for (final user in users) {
      if (_animatedMarkers.containsKey(user.email)) {
        // Atualiza posição existente
        final didUpdate =
            _animatedMarkers[user.email]!.updateTargetPosition(
          user.lat ?? 0.0,
          user.lng ?? 0.0,
        );
        if (didUpdate) {
          shouldAnimateMarkers = true;
        }
      } else {
        // Cria novo marcador animado
        _animatedMarkers[user.email] = AnimatedUserMarker(user: user);
        animatedMarkerPositions[user.email] =
            LatLng(user.lat ?? 0.0, user.lng ?? 0.0);
      }
    }

    // Remove marcadores que não estão mais na lista
    final emailsToRemove = <String>[];
    for (final email in _animatedMarkers.keys) {
      if (!users.any((u) => u.email == email)) {
        emailsToRemove.add(email);
      }
    }
    for (final email in emailsToRemove) {
      _animatedMarkers.remove(email);
      animatedMarkerPositions.remove(email);
    }

    // Inicia a animação se necessário
    if (shouldAnimateMarkers) {
      _startMarkerAnimation();
    }
  }

  /// Inicia o timer de animação dos marcadores.
  void _startMarkerAnimation() {
    _markerAnimationTimer?.cancel();
    _animationProgress = 0.0;

    _markerAnimationTimer = Timer.periodic(
      const Duration(milliseconds: 16), // ~60fps
      (timer) {
        // Incrementa o progresso
        _animationProgress += 16.0 / _animationDurationMs;

        if (_animationProgress >= 1.0) {
          _animationProgress = 1.0;
          timer.cancel();
          _markerAnimationTimer = null;
        }

        _updateAnimatedMarkerPositions();
      },
    );
  }

  /// Atualiza as posições animadas dos marcadores com base no progresso da animação.
  void _updateAnimatedMarkerPositions() {
    for (final entry in _animatedMarkers.entries) {
      final renderedPosition =
          entry.value.updateAnimationProgress(_animationProgress);
      animatedMarkerPositions[entry.key] = renderedPosition;
    }
  }

  /// Método utilizado para escolher a cor dos pins, determinando uma cor
  /// especial para o pin correspondente à localização do próprio usuário
  /// e outra para os demais.
  Color setMarkerColor(UserModel someUser) {
    final currentUserEmail = userCtrl.user?.email;

    return someUser.email == currentUserEmail
        ? Colors.indigo
        : Colors.lightBlue;
  }

  void openFirebaseUserDetails(UserModel user) {
    selectedFirebaseUser.value = user;
    selectedTrajectoryDay.value = null;
    _subscribeToTrajectory(user);
  }

  void _subscribeToTrajectory(UserModel user, {DateTime? day}) {
    _trajectorySubscription?.cancel();
    selectedTrajectory.clear();

    final stream = day == null
        ? FirebaseProvider().getRecentTrajectory(user.email)
        : FirebaseProvider().getTrajectoryForDate(user.email, day: day);

    _trajectorySubscription = stream.listen((points) {
      selectedTrajectory.value = points;
    });
  }

  Future<void> pickTrajectoryDate(BuildContext context) async {
    final user = selectedFirebaseUser.value;
    if (user == null) return;

    final now = DateTime.now();
    final initial = selectedTrajectoryDay.value ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(initial.year, initial.month, initial.day),
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.darkBlue(),
              onPrimary: Colors.white,
              onSurface: AppColors.darkBlue(),
              secondary: AppColors.mediumBlue(),
              onSecondary: Colors.white,
              surface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.mediumBlue(),
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: AppColors.darkBlue(),
              headerForegroundColor: Colors.white,
              dayForegroundColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                if (states.contains(WidgetState.disabled)) {
                  return Colors.grey;
                }
                return AppColors.darkBlue();
              }),
              dayBackgroundColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.mediumBlue();
                }
                return Colors.transparent;
              }),
              todayForegroundColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return AppColors.mediumBlue();
              }),
              todayBackgroundColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.mediumBlue();
                }
                return Colors.transparent;
              }),
              todayBorder: BorderSide(color: AppColors.mediumBlue(), width: 1),
              yearForegroundColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return AppColors.darkBlue();
              }),
              yearBackgroundColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.mediumBlue();
                }
                return Colors.transparent;
              }),
              yearOverlayColor: WidgetStateColor.resolveWith((_) {
                return AppColors.lightBlue();
              }),
              dayOverlayColor: WidgetStateColor.resolveWith((_) {
                return AppColors.lightBlue();
              }),
              rangeSelectionBackgroundColor: AppColors.lightBlue(),
              dividerColor: AppColors.lightBlue(),
              weekdayStyle: TextStyle(color: AppColors.alternativeMediumBlue()),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    final normalized = DateTime(picked.year, picked.month, picked.day);
    selectedTrajectoryDay.value = normalized;
    _subscribeToTrajectory(user, day: normalized);
  }

  void closeFirebaseUserDetails() {
    selectedFirebaseUser.value = null;
    selectedTrajectoryDay.value = null;

    _trajectorySubscription?.cancel();
    _trajectorySubscription = null;
    selectedTrajectory.clear();
  }

  Future<void> toggleService() async {
    var isRunning = await _service.isRunning();
  
    if (isRunning) {
      _stopService();
    } else {
      _startService();
    }
  }

  Future<void> _setPlatformSpecifics() async {
    await _service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        // Esta linha conecta os isolates.
        onStart: onStart,
        // true -> Foreground
        // false -> Background
        isForegroundMode: true,
        autoStart: false,
        autoStartOnBoot: false,
        initialNotificationTitle: "UM+: Monitoramento de jornada ativo",
        initialNotificationContent:
            "O monitoramento está ligado. Certifique-se de desativá-lo assim que terminar suas atividades.",
      ),
    );
  }

  // TODO: mover para permissions controller.
  Future<void> notifyGpsDisabled() async {
    await Get.dialog(
      AlertDialog(
        title: Text("O GPS está desativado"),
        content: Text("Por favor, ative o GPS para continuar."),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.darkBlue()),
            child: Text("ENTENDI"),
            onPressed: () {
              Get.back(); // Fecha o diálogo
            },
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _startService() async {
    // Verifica se GPS está ativado.
    bool gpsEnabled = await Geolocator.isLocationServiceEnabled();
    if (!gpsEnabled) {
      notifyGpsDisabled();
      return; // Interrompe a execução para não iniciar o serviço sem GPS
    }
  
    await _setPlatformSpecifics();
    await _service.startService();
  
    // Este listener ouve o serviço em foreground avisar que está pronto para
    // receber informações do usuário.
    _service.on('ready').listen((event) async {
      _service.invoke("setUserInfo", {
        "email": userCtrl.user!.email,
        "name": userCtrl.getUserName(),
        "funcao": userCtrl.user!.funcao, //_currentUser.funcao,
      });
    });
  
    // Este listener ouve atualizações da posição por parte do serviço em
    // foreground.
    _service.on('updateLocationLocally').listen((event) {
      if (event != null) {
        position = Position.fromMap(event['position']);
      }
    });
  
    // Atualiza UI (botão).
    isTrackingEnabled.value = true;
    // Informa Firebase que sua posição pode ser visualizada no mapa.
    FirebaseProvider().updateIsTracked(userCtrl.user!.email, true);
  }
  
  Future<void> _stopService() async {
    _service.invoke("stopService");
    isTrackingEnabled.value = false;
    FirebaseProvider().updateIsTracked(userCtrl.user!.email, false);
  }

  @override
  void onClose() {
    //_compassSubscription?.cancel();
    _trajectorySubscription?.cancel();
    _markerAnimationTimer?.cancel();
    mapController.dispose();
    super.onClose();
  }



  Future<void> launchGoogleMeet(String email) async {
    if (kIsWeb) {
      try {
        // Codifica o e-mail para garantir que caracteres especiais (como @) não quebrem a URL
        final encodedEmail = Uri.encodeComponent(email);

        // URL específica para o serviço de ligações com o e-mail do destinatário
        final Uri meetCallingUri = Uri.parse('https://meet.google.com/calling/?user=$encodedEmail');

        await Clipboard.setData(ClipboardData(text: email));

        await launchUrl(
          meetCallingUri,
          mode: LaunchMode.externalApplication, // Abre em uma nova aba
        );
      } catch (e) {
        if (kDebugMode) {
          print('Não foi possível abrir o serviço de ligações do Meet na Web: $e');
        }
      }
      return;
    } else {
      await Clipboard.setData(ClipboardData(text: email));
      if (Platform.isAndroid) {
        final intent = AndroidIntent(
          //action: 'action_view',
          action: 'android.intent.action.MAIN',
          //data: url,
          package: 'com.google.android.apps.tachyon', // Google Meet standalone
        );

        try {
          await intent.launch();
        } catch (e) {
          if (kDebugMode) {
            print('Não foi possível abrir o Google Meet standalone: $e');
          }
        }
      } else if (Platform.isIOS) {
        final Uri meetAppUri = Uri.parse('gmeet://');
        final Uri meetWebUri = Uri.parse('https://meet.google.com/');
        try {
          // Tenta abrir o aplicativo nativo do Google Meet
          if (await canLaunchUrl(meetAppUri)) {
            await launchUrl(meetAppUri);
          } else {
            // Caso não esteja instalado, abre no Safari como fallback
            await launchUrl(meetWebUri, mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Não foi possível abrir o Google Meet no iOS: $e');
          }
        }
      }
    }
  }
}
