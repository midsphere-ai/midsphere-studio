// ignore_for_file: depend_on_referenced_packages
import 'package:hive_ce/hive.dart';

class User extends HiveObject{
  int? id;
  String? lastLogin;
  String? username;
  String? firstName;
  String? lastName;
  String? email;
  bool? isActive;
  String? dateJoined;
  String? name;

  User(
      {this.id,
      this.lastLogin,
      this.username,
      this.firstName,
      this.lastName,
      this.email,
      this.isActive,
      this.dateJoined,
      this.name});

  @override
  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    lastLogin = json['last_login'];
    username = json['username'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    email = json['email'];
    isActive = json['is_active'];
    dateJoined = json['date_joined'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['last_login'] = lastLogin;
    data['username'] = username;
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    data['email'] = email;
    data['is_active'] = isActive;
    data['date_joined'] = dateJoined;
    data['name'] = name;
    return data;
  }
}
