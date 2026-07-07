import 'package:harpia/app/data/models/user_google_model.dart';
import 'package:harpia/app/data/provider/user_google_provider.dart';

class UserGoogleRepository {
  final UserGoogleProvider _provider = UserGoogleProvider();
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

  //Future<void> registerTokenCdc(String token, String tokenDevice, String device) async {
  //  await _cdcService.registerToken(token, tokenDevice, device);
  //}
}
