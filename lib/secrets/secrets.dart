import 'package:flutter/foundation.dart' show kIsWeb;

class Secrets {
  //not so secret
  static String get clientId {
    if (kIsWeb) {
      return "WEB_CLIENT_ID.apps.googleusercontent.com"; // Web client ID
    } else {
      return "1569540045-6sum7mkn15ue13l7rqlfem11if8s2kuc.apps.googleusercontent.com"; // Android/iOS client ID
    }
  }

  Secrets._();
}
