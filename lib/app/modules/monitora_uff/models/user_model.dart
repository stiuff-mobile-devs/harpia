import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String email;
  String? nome;
  double? lat;
  double? lng;
  DateTime? timestamp;
  bool? isTracked;

  UserModel({
    required this.email,
    this.nome,
    this.lat,
    this.lng,
    this.timestamp,
    this.isTracked,
  });

  UserModel.fromMap(Map<String, dynamic> json)
    : email = json['email'].toString(),
      nome = json['nome']?.toString(),
      lat = (json['lat'] as num?)?.toDouble(),
      lng = (json['lng'] as num?)?.toDouble(),
      timestamp = (json['timestamp'] as Timestamp?)?.toDate(),
      isTracked = json['isTracked'] as bool?;

  //Map<String, dynamic> toMap() {
  //  final Map<String, dynamic> data = <String, dynamic>{};
  //  data['email'] = email;
  //  data['nome'] = nome;
  //  data['funcao'] = funcao;
  //  data['lat'] = lat;
  //  data['lng'] = lng;
  //  data['timestamp'] = timestamp;
  //  data['isTracked'] = isTracked;
  //  return data;
  //}

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      if (nome != null) 'nome': nome,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (timestamp != null) 'timestamp': timestamp,
      if (isTracked != null) 'isTracked': isTracked,
    };
  }
}
