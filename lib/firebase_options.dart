// **************************************************************************
// إعدادات Firebase — مشروع livematch-8e189
// القيم الأندرويد حقيقية ومطابقة لملف android/app/google-services.json
// (اسم الحزمة: com.chatme.ltc)
//
// لدعم iOS أو الويب: سجّل التطبيق في Firebase Console ثم شغّل
//     flutterfire configure
// ليملأ القيم الناقصة لهاتين المنصتين تلقائيًّا.
// **************************************************************************

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'المنصة $defaultTargetPlatform غير مدعومة حاليًّا في سينما جماعية.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBYOnFMm3RlrDG54QbnFl4cWmPg3hMTnUg',
    // ⚠️ سجّل تطبيق ويب في Firebase Console ثم ضع معرّفه (1:...:web:...) هنا
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: '588476650085',
    projectId: 'livematch-8e189',
    authDomain: 'livematch-8e189.firebaseapp.com',
    storageBucket: 'livematch-8e189.appspot.com',
    databaseURL: 'https://livematch-8e189-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBYOnFMm3RlrDG54QbnFl4cWmPg3hMTnUg',
    appId: '1:588476650085:android:d213c875d1033e6edc2c8c',
    messagingSenderId: '588476650085',
    projectId: 'livematch-8e189',
    storageBucket: 'livematch-8e189.appspot.com',
    databaseURL: 'https://livematch-8e189-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    // ⚠️ أضف تطبيق iOS في Firebase Console ثم استبدل القيم عبر flutterfire configure
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '588476650085',
    projectId: 'livematch-8e189',
    storageBucket: 'livematch-8e189.appspot.com',
    databaseURL: 'https://livematch-8e189-default-rtdb.firebaseio.com',
    iosBundleId: 'com.watchtogether.cinema',
  );
}
