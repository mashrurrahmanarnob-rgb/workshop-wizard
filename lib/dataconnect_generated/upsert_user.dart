part of 'generated.dart';

class UpsertUserVariablesBuilder {
  String displayName;
  String email;
  String role;

  final FirebaseDataConnect _dataConnect;
  UpsertUserVariablesBuilder(this._dataConnect, {required  this.displayName,required  this.email,required  this.role,});
  Deserializer<UpsertUserData> dataDeserializer = (dynamic json)  => UpsertUserData.fromJson(jsonDecode(json));
  Serializer<UpsertUserVariables> varsSerializer = (UpsertUserVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpsertUserData, UpsertUserVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpsertUserData, UpsertUserVariables> ref() {
    UpsertUserVariables vars= UpsertUserVariables(displayName: displayName,email: email,role: role,);
    return _dataConnect.mutation("UpsertUser", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpsertUserUserUpsert {
  final String id;
  UpsertUserUserUpsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertUserUserUpsert otherTyped = other as UpsertUserUserUpsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpsertUserUserUpsert({
    required this.id,
  });
}

@immutable
class UpsertUserData {
  final UpsertUserUserUpsert user_upsert;
  UpsertUserData.fromJson(dynamic json):
  
  user_upsert = UpsertUserUserUpsert.fromJson(json['user_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertUserData otherTyped = other as UpsertUserData;
    return user_upsert == otherTyped.user_upsert;
    
  }
  @override
  int get hashCode => user_upsert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['user_upsert'] = user_upsert.toJson();
    return json;
  }

  UpsertUserData({
    required this.user_upsert,
  });
}

@immutable
class UpsertUserVariables {
  final String displayName;
  final String email;
  final String role;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpsertUserVariables.fromJson(Map<String, dynamic> json):
  
  displayName = nativeFromJson<String>(json['displayName']),
  email = nativeFromJson<String>(json['email']),
  role = nativeFromJson<String>(json['role']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertUserVariables otherTyped = other as UpsertUserVariables;
    return displayName == otherTyped.displayName && 
    email == otherTyped.email && 
    role == otherTyped.role;
    
  }
  @override
  int get hashCode => Object.hashAll([displayName.hashCode, email.hashCode, role.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['displayName'] = nativeToJson<String>(displayName);
    json['email'] = nativeToJson<String>(email);
    json['role'] = nativeToJson<String>(role);
    return json;
  }

  UpsertUserVariables({
    required this.displayName,
    required this.email,
    required this.role,
  });
}

