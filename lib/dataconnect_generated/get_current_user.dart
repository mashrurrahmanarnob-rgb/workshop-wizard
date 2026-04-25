part of 'generated.dart';

class GetCurrentUserVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetCurrentUserVariablesBuilder(this._dataConnect, );
  Deserializer<GetCurrentUserData> dataDeserializer = (dynamic json)  => GetCurrentUserData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetCurrentUserData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetCurrentUserData, void> ref() {
    
    return _dataConnect.query("GetCurrentUser", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetCurrentUserUser {
  final String id;
  final String? displayName;
  final String? email;
  final String? role;
  final String? bio;
  final String? contactNumber;
  GetCurrentUserUser.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  displayName = json['displayName'] == null ? null : nativeFromJson<String>(json['displayName']),
  email = json['email'] == null ? null : nativeFromJson<String>(json['email']),
  role = json['role'] == null ? null : nativeFromJson<String>(json['role']),
  bio = json['bio'] == null ? null : nativeFromJson<String>(json['bio']),
  contactNumber = json['contactNumber'] == null ? null : nativeFromJson<String>(json['contactNumber']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetCurrentUserUser otherTyped = other as GetCurrentUserUser;
    return id == otherTyped.id && 
    displayName == otherTyped.displayName && 
    email == otherTyped.email && 
    role == otherTyped.role && 
    bio == otherTyped.bio && 
    contactNumber == otherTyped.contactNumber;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, displayName.hashCode, email.hashCode, role.hashCode, bio.hashCode, contactNumber.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    if (displayName != null) {
      json['displayName'] = nativeToJson<String?>(displayName);
    }
    if (email != null) {
      json['email'] = nativeToJson<String?>(email);
    }
    if (role != null) {
      json['role'] = nativeToJson<String?>(role);
    }
    if (bio != null) {
      json['bio'] = nativeToJson<String?>(bio);
    }
    if (contactNumber != null) {
      json['contactNumber'] = nativeToJson<String?>(contactNumber);
    }
    return json;
  }

  GetCurrentUserUser({
    required this.id,
    this.displayName,
    this.email,
    this.role,
    this.bio,
    this.contactNumber,
  });
}

@immutable
class GetCurrentUserData {
  final GetCurrentUserUser? user;
  GetCurrentUserData.fromJson(dynamic json):
  
  user = json['user'] == null ? null : GetCurrentUserUser.fromJson(json['user']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetCurrentUserData otherTyped = other as GetCurrentUserData;
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

  GetCurrentUserData({
    this.user,
  });
}

