part of 'generated.dart';

class GetUserRoleVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  GetUserRoleVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<GetUserRoleData> dataDeserializer = (dynamic json)  => GetUserRoleData.fromJson(jsonDecode(json));
  Serializer<GetUserRoleVariables> varsSerializer = (GetUserRoleVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetUserRoleData, GetUserRoleVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetUserRoleData, GetUserRoleVariables> ref() {
    GetUserRoleVariables vars= GetUserRoleVariables(id: id,);
    return _dataConnect.query("GetUserRole", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetUserRoleUser {
  final String? role;
  GetUserRoleUser.fromJson(dynamic json):
  
  role = json['role'] == null ? null : nativeFromJson<String>(json['role']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUserRoleUser otherTyped = other as GetUserRoleUser;
    return role == otherTyped.role;
    
  }
  @override
  int get hashCode => role.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (role != null) {
      json['role'] = nativeToJson<String?>(role);
    }
    return json;
  }

  GetUserRoleUser({
    this.role,
  });
}

@immutable
class GetUserRoleData {
  final GetUserRoleUser? user;
  GetUserRoleData.fromJson(dynamic json):
  
  user = json['user'] == null ? null : GetUserRoleUser.fromJson(json['user']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUserRoleData otherTyped = other as GetUserRoleData;
    return user == otherTyped.user;
    
  }
  @override
  int get hashCode => user.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user != null) {
      json['user'] = user!.toJson();
    }
    return json;
  }

  GetUserRoleData({
    this.user,
  });
}

@immutable
class GetUserRoleVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetUserRoleVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUserRoleVariables otherTyped = other as GetUserRoleVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetUserRoleVariables({
    required this.id,
  });
}

