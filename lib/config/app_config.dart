import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  static const apiKey = 'AIzaSyCSlW3seUvudPDNlznPzQsROXltw04awh4';
  static const androidAppId = '1:997404851226:android:120512201e45d898a8a5a3';
  static const webApiKey = 'AIzaSyAnCs58XmADro3V5VDHpKKRPtO-R7fkvLc';
  static const webAppId = '1:997404851226:web:de0e8f84ff372610a8a5a3';
  static const messagingSenderId = '997404851226';
  static const projectId = 'labguard-419c6';
  static const databaseUrl = 'https://labguard-419c6-default-rtdb.asia-southeast1.firebasedatabase.app';
  static const authDomain = 'labguard-419c6.firebaseapp.com';
  static const labId = 'lab01';
  static const labName = 'Electronics Laboratory';

  static bool get configured => [
    kIsWeb ? webApiKey : apiKey,
    kIsWeb ? webAppId : androidAppId,
    messagingSenderId,
    projectId,
    databaseUrl,
    if (kIsWeb) authDomain,
  ].every((value) => value.isNotEmpty && !value.contains('REPLACE_'));

  static FirebaseOptions get firebaseOptions => FirebaseOptions(
    apiKey: kIsWeb ? webApiKey : apiKey,
    appId: kIsWeb ? webAppId : androidAppId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    databaseURL: databaseUrl,
    authDomain: kIsWeb ? authDomain : null,
  );
}
