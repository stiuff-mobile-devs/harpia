import 'package:harpia/app/data/connections/google_service.dart';
import 'package:harpia/app/data/models/gd_groups_google_model.dart';
import 'package:harpia/app/data/models/user_google_model.dart';
import 'package:harpia/app/data/provider/user_google_provider.dart';

class UserGoogleRepository {
  final UserGoogleProvider _provider = UserGoogleProvider();
  final GoogleService _googleService = GoogleService();
  //final CdcService _cdcService = CdcService();

  Future<UserGoogleModel> createUserDoc(
    String email,
    String name,
    String uid,
    String urlImage,
  ) async {
    UserGoogleModel user = await _provider.createUserDoc(
      email,
      name,
      uid,
      urlImage,
    );

    return user;
  }

  Future<String> saveUserGoogleModel(UserGoogleModel user) {
    return _provider.saveUserGoogleModel(user);
  }

  Future<UserGoogleModel?> getUserGoogleModel() {
    return _provider.getUserGoogleModel();
  }

  Future<String> deleteUserGoogleModel() {
    return _provider.deleteUserGoogleModel();
  }

  Future<String> clearAllUserGoogle() {
    return _provider.clearAllUserGoogle();
  }

  Future<bool> hasUserGoogle() {
    return _provider.hasUserGoogle();
  }

  Future<GdiGroupsGoogle> getGdiGroupsGoogle(String token, String email) async {
    return await _googleService.getGdiGroupsGoogle(token, email);
  }
}
