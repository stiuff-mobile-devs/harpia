import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/svg.dart';
import 'package:harpia/app/modules/monitora_uff/controller/google_groups_controller.dart';
import 'package:harpia/app/modules/monitora_uff/controller/permissions_controller.dart';
import 'package:harpia/app/modules/monitora_uff/controller/tracking_controller.dart';
import 'package:harpia/app/modules/monitora_uff/controller/user_controller.dart';
import 'package:harpia/app/modules/login/controllers/auth_google_controller.dart';
import 'package:harpia/app/modules/monitora_uff/ui/widgets/group_selector.dart';
import 'package:harpia/app/modules/monitora_uff/ui/widgets/harpia_app_bar.dart';
import 'package:harpia/app/utils/color_pallete.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart' hide Path;

class MonitoraUFFPage extends StatelessWidget {
  const MonitoraUFFPage({super.key});

  UserController get userCtrl => Get.find<UserController>();
  PermissionsController get permissionsCtrl =>
      Get.find<PermissionsController>();
  TrackingController get trackingCtrl => Get.find<TrackingController>();
  GoogleGroupsController get googleGroupsController => Get.find<GoogleGroupsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HarpiaAppBar(),
      drawer: GroupSelector(),//_groupSelector(),
      body: _body(context)
    );
  }

  Widget _centralizeButton() {
    return Obx(
      () => permissionsCtrl.arePermissionsGranted() && userCtrl.isTrackable()
          ? Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: "btnCentralizeMap",
                backgroundColor: AppColors.lightBlue(),
                onPressed: trackingCtrl.centerMapOnCurrentLocation,
                child: Icon(Icons.my_location, color: AppColors.darkBlue()),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _body(BuildContext context) {
    return Obx(() {
      if (userCtrl.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      // TODO
      if (userCtrl.isAdmin()) {
        return _adminDashboard(context);
      } else if (userCtrl.isTrackable() & !kIsWeb) {
        return _monitorPage(context);
      }

      return _unauthorizedPage();
    });
  }

  /// Usuário verá essa tela apenas se todas as permissões necessárias já tiverem
  /// sido concedidas.
  Widget mapa(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: trackingCtrl.mapController,
          options: MapOptions(
            initialCenter: LatLng(
              trackingCtrl.position.latitude,
              trackingCtrl.position.longitude,
            ),
            onTap: (tapPosition, latLng) {
              trackingCtrl.closeFirebaseUserDetails();
            },
          ),
          children: [
            tile(),
            trajectoryPolylines(),
            trajectoryEndpointMarkers(),
            firebaseMarkers(),
            toggleButton(),
            _centralizeButton(),
          ],
        ),
        _selectedUserBar(context),
      ],
    );
  }

  /// Desenha a trajetória do usuário focado (aquele cuja barra inferior
  /// está visível). A trajetória aparece e desaparece junto com a barra.
  Widget trajectoryPolylines() {
    return Obx(() {
      final user = trackingCtrl.selectedFirebaseUser.value;
      final points = trackingCtrl.selectedTrajectory;

      if (user == null || points.length < 2) {
        return PolylineLayer<Object>(polylines: []);
      }

      final latLngPoints = points.map((p) => LatLng(p.lat, p.lng)).toList();
      final baseColor = trackingCtrl.setMarkerColor(user);

      final darkerBorderColor = Color.fromARGB(
        (baseColor.a * 255.0).round().clamp(0, 255),
        (baseColor.r * 255.0 * 0.5).round().clamp(0, 255),
        (baseColor.g * 255.0 * 0.5).round().clamp(0, 255),
        (baseColor.b * 255.0 * 0.5).round().clamp(0, 255),
      );

      return PolylineLayer<Object>(
        polylines: [
          Polyline<Object>(
            points: latLngPoints,
            strokeWidth: 5.0,
            color: baseColor,
            borderStrokeWidth: 2.0,
            borderColor: darkerBorderColor,
          ),
        ],
      );
    });
  }

  Widget trajectoryEndpointMarkers() {
    return Obx(() {
      final user = trackingCtrl.selectedFirebaseUser.value;
      final points = trackingCtrl.selectedTrajectory;

      if (user == null || points.isEmpty) {
        return MarkerLayer(markers: []);
      }

      final latLngPoints = points.map((p) => LatLng(p.lat, p.lng)).toList();
      final samePoint = latLngPoints.first == latLngPoints.last;

      return MarkerLayer(
        markers: [
          _trajectoryEndpointMarker(
            point: latLngPoints.first,
            icon: Icons.trip_origin,
            backgroundColor: Colors.indigo,
            offset: samePoint ? const Offset(-6, -6) : Offset.zero,
          ),
          _trajectoryEndpointMarker(
            point: latLngPoints.last,
            icon: Icons.flag,
            backgroundColor: Colors.indigo,
            offset: samePoint ? const Offset(6, 6) : Offset.zero,
          ),
        ],
      );
    });
  }

  Marker _trajectoryEndpointMarker({
    required LatLng point,
    required IconData icon,
    required Color backgroundColor,
    required Offset offset,
  }) {
    return Marker(
      point: point,
      width: 22,
      height: 22,
      alignment: Alignment.center,
      child: Transform.translate(
        offset: offset,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  /// Usuário verá essa tela apenas se algumas das permissões necessárias
  /// ainda não tiver sido concedida.
  Widget permissionScreen() {
    return Container(
      decoration: BoxDecoration(gradient: AppColors.appBarBottomGradient()),
      child: Obx(
        () => Align(
          alignment: Alignment.center,
          child: IntrinsicWidth(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.darkBlue(),
                        ),
                        onPressed:
                            permissionsCtrl.requestNotificationPermission,
                        child: const Text("Permitir notificação"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      permissionsCtrl.hasNotificationPermission.value
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.darkBlue(),
                        ),
                        onPressed: permissionsCtrl.requestWhenInUsePermission,
                        child: const Text("Permitir localização (durante uso)"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      permissionsCtrl.hasWhenInUseLocationPermission.value
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.darkBlue(),
                        ),
                        onPressed: permissionsCtrl.requestAlwaysPermission,
                        child: const Text("Permitir localização (sempre)"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      permissionsCtrl.hasAlwaysLocationPermission.value
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget tile() {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'br.uff.sti.uffmobileplus',
    );
  }

  Widget firebaseMarkers() {
    const double markerSize = 50.0;

    return Obx(
      () => MarkerLayer(
        markers: trackingCtrl.firebaseUsers
        .where((user) {
          // Filtro: apenas usuários que estão na intersecção entre `observedMembers` e `firebaseUsers`
          // serão mostrados na camada de marcadores.
          final observedMembersEmails = googleGroupsController.observedMembers.map((member) => member.email);
          return observedMembersEmails.contains(user.email);
        })
        .map((user) {
          final isCurrentUser = user.email == trackingCtrl.userCtrl.user?.email;
          // Usa a posição animada se disponível, caso contrário usa a posição atual
          final animatedPos = trackingCtrl.animatedMarkerPositions[user.email];
          final position = animatedPos ?? LatLng(user.lat ?? 0.0, user.lng ?? 0.0);

          return Marker(
            point: position,
            width: isCurrentUser ? markerSize * 3 : markerSize,
            height: isCurrentUser ? markerSize * 3 : markerSize,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (isCurrentUser)
                  Obx(() {
                    final heading = trackingCtrl.heading.value;
                    if (heading == null) return const SizedBox.shrink();

                    return Transform.rotate(
                      angle: heading * (math.pi / 180),
                      child: SizedBox(
                        width: markerSize * 3,
                        height: markerSize * 3,
                        child: CustomPaint(painter: _BeamPainter()),
                      ),
                    );
                  }),
                SizedBox(
                  width: markerSize,
                  height: markerSize,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => trackingCtrl.openFirebaseUserDetails(user),
                    child: Container(
                      decoration: BoxDecoration(
                        color: user.isTracked == false || DateTime.now().difference(user.timestamp!) >= Duration(minutes: 2)  
                          ? trackingCtrl.setMarkerColor(user).withAlpha(100)
                          : trackingCtrl.setMarkerColor(user),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      margin: const EdgeInsets.all(10),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _selectedUserBar(BuildContext context) {
    return Obx(() {
      final user = trackingCtrl.selectedFirebaseUser.value;

      if (user == null) {
        return const SizedBox.shrink();
      }

      return Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Material(
              color: AppColors.darkBlue(),
              elevation: 12,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            "Monitor",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: trackingCtrl.closeFirebaseUserDetails,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.nome ?? user.email,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.calendar_month,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              trackingCtrl.pickTrajectoryDate(context);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: SvgPicture.asset(
                              'assets/monitora_uff/Google_Meet_icon.svg',
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                            ),
                            onPressed: () {
                              trackingCtrl.launchGoogleMeet(user.email);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Última atualização: ${user.timestamp}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget toggleButton() {
    return userCtrl.isTrackable()
        ? Positioned(
            top: 16,
            right: 16,
            child: Obx(
              () => FloatingActionButton(
                heroTag: "btnToggleTracking",
                onPressed: trackingCtrl.toggleService,
                backgroundColor: trackingCtrl.isTrackingEnabled.value
                    ? Colors.green
                    : Colors.red,
                child: Icon(
                  trackingCtrl.isTrackingEnabled.value
                      ? Icons.location_on
                      : Icons.location_off,
                  color: Colors.white,
                ),
              ),
            ),
          )
        : Container();
  }

  Widget _adminDashboard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppColors.darkBlueToBlackGradient()),
      child: mapa(context),
    );
  }

  Widget _monitorPage(BuildContext context) {
    return Obx(
      () => permissionsCtrl.arePermissionsGranted()
          ? mapa(context)
          : permissionScreen(),
    );
  }

  Widget _unauthorizedPage() {
    return Center(
      child: Column(
        children: [
          Center(
            child: Text("Você não tem permissão para utilizar este serviço."),
          ),
          // TODO: criar widget separado para esse botão
          Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () =>
                        Get.find<AuthGoogleController>().logout(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}

class _BeamPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.blueAccent.withValues(alpha: 1.00),
          Colors.blueAccent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final path = Path();
    path.moveTo(center.dx, center.dy);
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 - math.pi / 6, // start angle: -120 deg
      math.pi / 3, // sweep angle: 60 deg
      false,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
