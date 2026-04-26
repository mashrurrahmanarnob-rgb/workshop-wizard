library dataconnect_generated;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'upsert_user.dart';

part 'list_users.dart';

part 'get_current_user.dart';

part 'get_user_role.dart';







class ExampleConnector {
  
  
  UpsertUserVariablesBuilder upsertUser ({required String displayName, required String email, required String role, }) {
    return UpsertUserVariablesBuilder(dataConnect, displayName: displayName,email: email,role: role,);
  }
  
  
  ListUsersVariablesBuilder listUsers () {
    return ListUsersVariablesBuilder(dataConnect, );
  }
  
  
  GetCurrentUserVariablesBuilder getCurrentUser () {
    return GetCurrentUserVariablesBuilder(dataConnect, );
  }
  
  
  GetUserRoleVariablesBuilder getUserRole ({required String id, }) {
    return GetUserRoleVariablesBuilder(dataConnect, id: id,);
  }
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'us-east4',
    'example',
    'workshopwizard',
  );

  ExampleConnector({required this.dataConnect});
  static ExampleConnector get instance {
    
    CacheSettings cacheSettings = CacheSettings(
      maxAge: Duration(milliseconds:0),
      storage: CacheStorage.persistent,
    );
    
    return ExampleConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            
            cacheSettings: cacheSettings,
            
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}
